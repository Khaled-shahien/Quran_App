import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/features/prayers/data/repositories/adhan_settings_store.dart';
import 'package:sakina_app/features/prayers/domain/entities/adhan_settings.dart';
import 'package:sakina_app/features/prayers/presentation/providers/adhan_settings_controller.dart';
import 'package:sakina_app/features/prayers/presentation/widgets/exact_alarm_prompt.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Without "Alarms & reminders" (denied by default on Android 14+), Doze
/// holds prayer alerts until the screen is turned on. The app must ask for
/// it and warn while it is missing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('needsExactAlarms', () {
    const sound = AdhanSettings();
    final silent = DailyPrayer.values.fold<AdhanSettings>(
      sound,
      (s, p) => s.withMode(p, PrayerAlertMode.silent),
    );

    test('only when denied, alerts are on and some prayer alerts', () {
      expect(
        needsExactAlarms(
          settings: sound,
          exactAllowed: false,
          prayerAlertsEnabled: true,
        ),
        isTrue,
      );
      for (final allowed in [true, null]) {
        expect(
          needsExactAlarms(
            settings: sound,
            exactAllowed: allowed,
            prayerAlertsEnabled: true,
          ),
          isFalse,
          reason: 'allowed=$allowed',
        );
      }
      expect(
        needsExactAlarms(
          settings: sound,
          exactAllowed: false,
          prayerAlertsEnabled: false,
        ),
        isFalse,
      );
      expect(
        needsExactAlarms(
          settings: silent,
          exactAllowed: false,
          prayerAlertsEnabled: true,
        ),
        isFalse,
      );
    });
  });

  group('prompt and warning', () {
    late bool exact;
    late int requests;
    late SharedPreferences prefs;

    Future<AdhanSettingsController> controller() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      exact = false;
      requests = 0;
      return AdhanSettingsController(
        store: AdhanSettingsStore(prefs),
        platform: AdhanPlatform(
          reschedule: () async {},
          canScheduleExact: () async => exact,
          requestExact: () async {
            requests++;
            exact = true;
            return true;
          },
          scheduleTest: (_) async {},
        ),
      );
    }

    Widget app(AdhanSettingsController c, Widget child) =>
        ChangeNotifierProvider<AdhanSettingsController>.value(
          value: c,
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: child),
          ),
        );

    testWidgets('the warning shows while denied and goes once granted', (
      tester,
    ) async {
      final c = await controller();
      await tester.pumpWidget(app(c, const ExactAlarmWarningCard()));
      await tester.pumpAndSettle();
      expect(find.textContaining('يؤخرها حتى تفتح الشاشة'), findsOneWidget);

      await tester.tap(find.text('تفعيل'));
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(find.textContaining('يؤخرها حتى تفتح الشاشة'), findsNothing);
    });

    testWidgets('the dialog is shown once and opens the system page', (
      tester,
    ) async {
      final c = await controller();
      await tester.pumpWidget(
        app(
          c,
          Builder(
            builder: (context) => TextButton(
              onPressed: () => promptForExactAlarmsOnce(context),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.text('لتصل تنبيهات الصلاة في وقتها'), findsOneWidget);
      await tester.tap(find.text('تفعيل'));
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(prefs.getBool(exactAlarmPromptSeenKey), isTrue);

      exact = false; // revoked later: the warning card covers it, no nagging
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.text('لتصل تنبيهات الصلاة في وقتها'), findsNothing);
    });

    testWidgets('no dialog when the permission is already granted', (
      tester,
    ) async {
      final c = await controller();
      exact = true;
      await tester.pumpWidget(
        app(
          c,
          Builder(
            builder: (context) => TextButton(
              onPressed: () => promptForExactAlarmsOnce(context),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.text('لتصل تنبيهات الصلاة في وقتها'), findsNothing);
      expect(prefs.getBool(exactAlarmPromptSeenKey), isNull);
    });
  });
}
