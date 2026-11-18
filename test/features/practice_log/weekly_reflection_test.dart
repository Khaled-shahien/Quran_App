import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/features/khatma/domain/models/khatma_model.dart';
import 'package:sakina_app/features/practice_log/data/practice_log_repository.dart';
import 'package:sakina_app/features/practice_log/domain/weekly_reflection.dart';
import 'package:sakina_app/features/practice_log/presentation/weekly_reflection_card.dart';
import 'package:sakina_app/features/prayers/domain/entities/adhan_settings.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A log without a database.
class _Log extends PracticeLogRepository {
  _Log(this.days) : super(() => throw UnimplementedError());
  final Map<String, Map<DailyPrayer, PrayerLogStatus>> days;

  @override
  Future<Map<String, Map<DailyPrayer, PrayerLogStatus>>> prayers(
    DateTime from,
    DateTime to,
  ) async => days;
}

// A Friday.
final DateTime _friday = DateTime(2026, 11, 20, 18);

Future<SharedPreferences> _prefs({bool enabled = true}) async {
  final khatma = KhatmaModel(
    id: 'k',
    startMode: 'juz',
    startJuz: 1,
    startDate: DateTime(2026, 11, 1),
    trackingUnit: KhatmaTrackingUnit.page,
    goalType: KhatmaGoalType.byDailyAmount,
    plannedDurationDays: 30,
    dailyTargetUnits: 10,
    completedUnits: 40,
    reminderHour: 20,
    reminderMinute: 0,
    dailyLogs: [
      KhatmaDailyLog(date: DateTime(2026, 11, 19), unitsRead: 10),
      KhatmaDailyLog(date: DateTime(2026, 11, 16), unitsRead: 12),
      // Outside the seven days.
      KhatmaDailyLog(date: DateTime(2026, 11, 10), unitsRead: 18),
    ],
  );
  SharedPreferences.setMockInitialValues({
    WeeklyReflection.enabledKey: enabled,
    'active_khatma_plan': jsonEncode(khatma.toJson()),
  });
  final prefs = await SharedPreferences.getInstance();
  for (final d in [DateTime(2026, 11, 20), DateTime(2026, 11, 18)]) {
    await AdhkarHistory.record(prefs, 'morning', d);
  }
  await AdhkarHistory.record(prefs, 'morning', DateTime(2026, 11, 20));
  await AdhkarHistory.record(prefs, 'evening', DateTime(2026, 11, 1));
  return prefs;
}

void main() {
  test('only the seven days are counted; excused prayers are not', () async {
    final prefs = await _prefs();
    final week = await WeeklyReflection.compute(
      prefs: prefs,
      log: _Log({
        '2026-11-19': {
          DailyPrayer.fajr: PrayerLogStatus.onTime,
          DailyPrayer.dhuhr: PrayerLogStatus.late,
          DailyPrayer.asr: PrayerLogStatus.excused,
        },
      }),
      now: _friday,
    );
    expect(week.khatmaUnits, 22);
    expect(week.khatmaUnit, KhatmaTrackingUnit.page);
    expect(week.adhkarSessions, 2, reason: 'one per category per day');
    expect(week.prayersOnTime, 1);
    expect(week.prayersLogged, 2);
  });

  test('shown on Friday and Saturday only', () {
    expect(WeeklyReflection.isReflectionDay(_friday), isTrue);
    expect(WeeklyReflection.isReflectionDay(DateTime(2026, 11, 21)), isTrue);
    expect(WeeklyReflection.isReflectionDay(DateTime(2026, 11, 22)), isFalse);
  });

  Future<void> pump(WidgetTester tester, SharedPreferences prefs) =>
      tester.pumpWidget(
        Provider<SharedPreferences>.value(
          value: prefs,
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: WeeklyReflectionCard(
                log: _Log(const {}),
                clock: () => _friday,
              ),
            ),
          ),
        ),
      );

  testWidgets('the card lists only what was done', (tester) async {
    final prefs = (await tester.runAsync(_prefs))!;
    await pump(tester, prefs);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('weekly-reflection')), findsOneWidget);
    expect(find.textContaining('22'), findsOneWidget);
    expect(find.textContaining('في وقتها'), findsNothing);
  });

  testWidgets('nothing shows unless the user turned it on', (tester) async {
    final prefs = (await tester.runAsync(() => _prefs(enabled: false)))!;
    await pump(tester, prefs);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('weekly-reflection')), findsNothing);
  });
}
