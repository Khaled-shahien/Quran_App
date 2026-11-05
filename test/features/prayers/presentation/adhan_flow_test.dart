import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/duas/data/models/azkar_model.dart';
import 'package:sakina_app/features/duas/data/repositories/adhan_adhkar_repository.dart';
import 'package:sakina_app/features/duas/presentation/screens/after_adhan_screen.dart';
import 'package:sakina_app/features/prayers/data/repositories/adhan_settings_store.dart';
import 'package:sakina_app/features/prayers/domain/entities/adhan_settings.dart';
import 'package:sakina_app/features/prayers/presentation/providers/adhan_settings_controller.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_arrival_watcher.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_times_provider.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

NextPrayer next(String name, DateTime at, DateTime now) => NextPrayer(
  name: name,
  at: at,
  wallTime: at,
  isTomorrow: false,
  remaining: at.difference(now),
);

void main() {
  group('PrayerArrivalWatcher', () {
    final dhuhr = DateTime(2026, 11, 5, 11, 39);
    final asr = DateTime(2026, 11, 5, 14, 43);

    test('reports a prayer once, when its time passes', () {
      final w = PrayerArrivalWatcher();
      var now = DateTime(2026, 11, 5, 11, 38);
      expect(w.tick(next('الظهر', dhuhr, now), now), isNull);

      now = DateTime(2026, 11, 5, 11, 39, 20);
      final arrived = w.tick(next('العصر', asr, now), now);
      expect(arrived?.name, 'الظهر');

      now = DateTime(2026, 11, 5, 11, 40, 20);
      expect(w.tick(next('العصر', asr, now), now), isNull);
    });

    test('the first tick after opening the app never fires', () {
      final w = PrayerArrivalWatcher();
      final now = DateTime(2026, 11, 5, 12);
      expect(w.tick(next('العصر', asr, now), now), isNull);
    });
  });

  group('AdhanSettingsController', () {
    late int reschedules;
    late bool? exact;
    late List<AdhanSettings> tests;
    late SharedPreferences prefs;

    Future<AdhanSettingsController> build() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      reschedules = 0;
      exact = false;
      tests = [];
      return AdhanSettingsController(
        store: AdhanSettingsStore(prefs),
        platform: AdhanPlatform(
          reschedule: () async => reschedules++,
          canScheduleExact: () async => exact,
          requestExact: () async {
            exact = true;
            return true;
          },
          scheduleTest: (s) async => tests.add(s),
        ),
      );
    }

    test('changing a prayer\'s alert saves and reschedules', () async {
      final c = await build();
      await c.setMode(DailyPrayer.fajr, PrayerAlertMode.notificationOnly);
      expect(reschedules, 1);
      expect(
        AdhanSettingsStore(prefs).read().modeFor(DailyPrayer.fajr),
        PrayerAlertMode.notificationOnly,
      );
    });

    test('reminder accepts only offered values', () async {
      final c = await build();
      await c.setReminderMinutes(10);
      await c.setReminderMinutes(11);
      expect(c.settings.reminderMinutes, 10);
      expect(reschedules, 1);
    });

    test(
      'exact alarms are requested only on demand, then reschedule',
      () async {
        final c = await build();
        await c.refreshExactStatus();
        expect(c.exactAllowed, isFalse);
        expect(reschedules, 0, reason: 'nothing is requested automatically');
        await c.requestExactAlarms();
        expect(c.exactAllowed, isTrue);
        expect(reschedules, 1);
      },
    );

    test('the test alert uses the current settings', () async {
      final c = await build();
      await c.setMode(DailyPrayer.fajr, PrayerAlertMode.adhan);
      await c.scheduleTest();
      expect(tests.single.modeFor(DailyPrayer.fajr), PrayerAlertMode.adhan);
    });
  });

  group('adhan adhkar', () {
    test('asset is Hisn al-Muslim chapter on the adhan, with sources', () {
      final data =
          jsonDecode(File('assets/adhan_adhkar.json').readAsStringSync())
              as List<dynamic>;
      final items = AzkarCategoryModel.fromJson(
        data.single as Map<String, dynamic>,
      ).items;
      expect(items.map((i) => i.reference), [
        'حصن المسلم (22)',
        'حصن المسلم (23)',
        'حصن المسلم (24)',
        'حصن المسلم (25)',
        'حصن المسلم (26)',
      ]);
      final marks = RegExp(r'[ً-ْ]');
      final dua = items[3].text.replaceAll(marks, '');
      expect(dua, contains('اللهم رب هذه الدعوة التامة'));
      expect(items[3].instructionBefore.replaceAll(marks, ''), 'يقول:');
    });

    testWidgets('screen shows the prayer and the adhkar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AfterAdhanScreen(
            repository: AdhanAdhkarRepositoryImpl(),
            prayerName: 'المغرب',
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
      expect(find.text('حان وقت صلاة المغرب'), findsOneWidget);
      expect(find.text('حصن المسلم (22)'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('حصن المسلم (25)'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('حصن المسلم (25)'), findsOneWidget);
    });
  });
}
