import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/database/app_database.dart';
import 'package:sakina_app/core/services/user_data_backup.dart';
import 'package:sakina_app/core/utils/hijri_calendar_data.dart';
import 'package:sakina_app/features/practice_log/data/practice_log_repository.dart';
import 'package:sakina_app/features/practice_log/presentation/practice_log_controller.dart';
import 'package:sakina_app/features/practice_log/presentation/practice_log_screen.dart';
import 'package:sakina_app/features/prayers/domain/entities/adhan_settings.dart';
import 'package:sakina_app/features/quran/data/repositories/verse_library_repository.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase database;
  late PracticeLogRepository repository;
  final today = DateTime(2026, 11, 18, 9);

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await AppDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    repository = PracticeLogRepository(
      () async => database,
      clock: () => today,
    );
  });

  tearDown(() => database.db.close());

  test('days are stored as local calendar keys', () {
    expect(logDay(DateTime(2026, 3, 7, 23, 59)), '2026-03-07');
    expect(parseLogDay('2026-03-07'), DateTime(2026, 3, 7));
    expect(parseLogDay('2026-02-30'), isNull);
    expect(parseLogDay('x'), isNull);
  });

  test('a prayer is marked, changed and cleared', () async {
    await repository.setPrayer(today, DailyPrayer.fajr, PrayerLogStatus.late);
    await repository.setPrayer(today, DailyPrayer.fajr, PrayerLogStatus.onTime);
    await repository.setPrayer(today, DailyPrayer.asr, PrayerLogStatus.missed);
    var week = await repository.prayers(today, today);
    expect(week['2026-11-18'], {
      DailyPrayer.fajr: PrayerLogStatus.onTime,
      DailyPrayer.asr: PrayerLogStatus.missed,
    });
    await repository.setPrayer(today, DailyPrayer.asr, null);
    week = await repository.prayers(today, today);
    expect(week['2026-11-18'], {DailyPrayer.fajr: PrayerLogStatus.onTime});
  });

  test('make-up fasts: Ramadan days not fasted add, qada days subtract', () {
    const hijri = HijriConverter();
    // 1 Ramadan 1447 ≈ 18 Feb 2026 (Umm al-Qura).
    final ramadanDay = hijri.civilOf(1447, 9, 3);
    final shawwalDay = hijri.civilOf(1447, 10, 10);
    expect(
      qadaRemaining(
        base: 2,
        fasts: {
          logDay(ramadanDay): FastLogStatus.excused,
          logDay(hijri.civilOf(1447, 9, 4)): FastLogStatus.missed,
          logDay(hijri.civilOf(1447, 9, 5)): FastLogStatus.fasted,
          logDay(shawwalDay): FastLogStatus.qada,
          // Not fasting outside Ramadan owes nothing.
          logDay(hijri.civilOf(1447, 10, 11)): FastLogStatus.missed,
        },
        hijri: hijri,
      ),
      3,
    );
    expect(
      qadaRemaining(
        base: 0,
        fasts: {logDay(shawwalDay): FastLogStatus.qada},
        hijri: hijri,
      ),
      0,
    );
  });

  test('the log travels with export and import, and erase clears it', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PracticeLogController.qadaBaseKey, 4);
    final backup = UserDataBackup(
      prefs: prefs,
      library: VerseLibraryRepository(() async => database),
      otherTables: [repository],
    );
    await repository.setPrayer(today, DailyPrayer.isha, PrayerLogStatus.late);
    await repository.setFast(today, FastLogStatus.fasted);
    final file = await backup.export();

    await backup.erase();
    expect(await repository.prayers(today, today), isEmpty);
    expect(prefs.getInt(PracticeLogController.qadaBaseKey), isNull);

    await backup.restore(file);
    expect((await repository.prayers(today, today))['2026-11-18'], {
      DailyPrayer.isha: PrayerLogStatus.late,
    });
    expect((await repository.allFasts())['2026-11-18'], FastLogStatus.fasted);
    expect(prefs.getInt(PracticeLogController.qadaBaseKey), 4);
  });

  testWidgets('one tap logs a prayer; excused mode marks the rest', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = PracticeLogRepository(
      () async => database,
      clock: DateTime.now,
    );
    await tester.pumpWidget(
      Provider<SharedPreferences>.value(
        value: prefs,
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PracticeLogScreen(repository: repo),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('practice-prayer-fajr')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('في وقتها').last);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('practice-prayer-fajr')),
        matching: find.text('في وقتها'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('practice-excused')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('علّم صلوات هذا اليوم بعذر'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    final logged = (await tester.runAsync(
      () => repo.prayers(DateTime.now(), DateTime.now()),
    ))!;
    expect(logged.values.single, {
      DailyPrayer.fajr: PrayerLogStatus.onTime,
      DailyPrayer.dhuhr: PrayerLogStatus.excused,
      DailyPrayer.asr: PrayerLogStatus.excused,
      DailyPrayer.maghrib: PrayerLogStatus.excused,
      DailyPrayer.isha: PrayerLogStatus.excused,
    });
  });
}
