import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/features/prayers/domain/entities/prayer_times_entity.dart';
import 'package:sakina_app/features/prayers/domain/prayer_calculation_policy.dart';
import 'package:sakina_app/features/prayers/domain/prayer_time_adjustments.dart';
import 'package:sakina_app/features/prayers/domain/repositories/prayer_times_repository.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_times_provider.dart';
import 'package:sakina_app/features/prayers/presentation/screens/month_timetable_screen.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repository implements PrayerTimesRepository {
  final requested = <DateTime>[];

  @override
  Future<Result<PrayerTimesEntity>> getPrayerTimes(
    DateTime date,
    double latitude,
    double longitude, {
    int calculationMethod = PrayerCalculationPolicy.defaultMethod,
    AsrMadhab madhab = AsrMadhab.standard,
    String? timeZone,
    PrayerTimeAdjustments adjustments = PrayerTimeAdjustments.none,
  }) async {
    requested.add(date);
    return Success(
      PrayerTimesEntity(
        fajr: '04:${date.day.toString().padLeft(2, '0')}',
        sunrise: '06:15',
        dhuhr: '11:40',
        asr: '14:35',
        maghrib: '16:58',
        isha: '18:18',
        timezone: 'Africa/Cairo',
      ),
    );
  }
}

void main() {
  late _Repository repository;
  late PrayerTimesProvider provider;
  late Directory temp;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = _Repository();
    provider = PrayerTimesProvider(
      repository: repository,
      preferences: await SharedPreferences.getInstance(),
      nearestCity: (_, _) async => null,
    );
    temp = Directory.systemTemp.createTempSync('sakina_month');
  });

  tearDown(() {
    provider.dispose();
    temp.deleteSync(recursive: true);
  });

  test('every day of the month, none without a place', () async {
    expect(await provider.monthTimes(2026, 2), isEmpty);
    await provider.selectLocation(
      30.0444,
      31.2357,
      'القاهرة',
      5,
      timeZone: 'Africa/Cairo',
    );
    repository.requested.clear();
    final feb = await provider.monthTimes(2026, 2);
    expect(feb, hasLength(28));
    expect(feb.last.date, DateTime(2026, 2, 28));
    expect(feb.first.times.fajr, '04:01');
    expect((await provider.monthTimes(2028, 2)), hasLength(29));
  });

  testWidgets('the month is shown and shared as a PDF and an image', (
    tester,
  ) async {
    await tester.runAsync(
      () => provider.selectLocation(
        30.0444,
        31.2357,
        'القاهرة',
        5,
        timeZone: 'Africa/Cairo',
      ),
    );
    final shared = <(String, String)>[];
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider<PrayerTimesProvider>.value(
        value: provider,
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MonthTimetableScreen(
            share: (path, mime) async => shared.add((path, mime)),
            folder: () async => temp,
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('مواقيت الشهر'), findsOneWidget);
    expect(find.byType(DataRow), findsNothing); // rows are not widgets
    expect(find.text('06:15'), findsWidgets);

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('month-share-pdf')));
      for (var i = 0; i < 100 && shared.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    expect(shared.single.$2, 'application/pdf');
    final pdf = File(shared.single.$1).readAsBytesSync();
    expect(String.fromCharCodes(pdf.sublist(0, 4)), '%PDF');

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('month-share-image')));
      for (var i = 0; i < 100 && shared.length < 2; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    expect(shared.last.$2, 'image/png');
    expect(
      File(shared.last.$1).readAsBytesSync().sublist(1, 4),
      'PNG'.codeUnits,
    );
  });
}
