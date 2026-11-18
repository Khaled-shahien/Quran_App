import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../khatma/data/repositories/khatma_repository.dart';
import '../../khatma/domain/models/khatma_model.dart';
import '../data/practice_log_repository.dart';

/// Days each adhkar category was completed, newest last, for the weekly
/// reflection. Only the date is kept, never the counts.
abstract final class AdhkarHistory {
  static const String key = 'adhkar_completed_days_v1';
  static const int keepDays = 60;

  static Map<String, List<String>> read(SharedPreferences prefs) {
    try {
      final Object? decoded = jsonDecode(prefs.getString(key) ?? '{}');
      if (decoded is! Map) return {};
      return {
        for (final e in decoded.entries)
          if (e.key is String && e.value is List)
            e.key as String: (e.value as List).whereType<String>().toList(),
      };
    } on FormatException {
      return {};
    }
  }

  /// Records that [category] was completed on [day] (once per day).
  static Future<void> record(
    SharedPreferences prefs,
    String category,
    DateTime day,
  ) async {
    final all = read(prefs);
    final days = all[category] ?? <String>[];
    final String today = logDay(day);
    if (days.contains(today)) return;
    days.add(today);
    all[category] = days.length > keepDays
        ? days.sublist(days.length - keepDays)
        : days;
    await prefs.setString(key, jsonEncode(all));
  }
}

/// What the past seven days held, counted on the phone. Only what was done
/// is counted; nothing is compared or scored.
typedef WeekSummary = ({
  double khatmaUnits,
  KhatmaTrackingUnit? khatmaUnit,
  int adhkarSessions,
  int prayersOnTime,
  int prayersLogged,
});

abstract final class WeeklyReflection {
  static const String enabledKey = 'weekly_reflection_enabled';

  /// Shown on Friday and Saturday.
  static bool isReflectionDay(DateTime now) =>
      now.weekday == DateTime.friday || now.weekday == DateTime.saturday;

  static Future<WeekSummary> compute({
    required SharedPreferences prefs,
    required PracticeLogRepository log,
    required DateTime now,
  }) async {
    final DateTime end = DateTime(now.year, now.month, now.day);
    final DateTime start = DateTime(end.year, end.month, end.day - 6);
    bool inWeek(DateTime d) {
      final day = DateTime(d.year, d.month, d.day);
      return !day.isBefore(start) && !day.isAfter(end);
    }

    final KhatmaModel? khatma = KhatmaRepositoryImpl(
      prefs: prefs,
    ).getActiveKhatma().valueOrNull;
    double units = 0;
    for (final entry in khatma?.dailyLogs ?? const <KhatmaDailyLog>[]) {
      if (inWeek(entry.date)) units += entry.unitsRead;
    }

    int sessions = 0;
    for (final days in AdhkarHistory.read(prefs).values) {
      for (final day in days) {
        final date = parseLogDay(day);
        if (date != null && inWeek(date)) sessions++;
      }
    }

    int onTime = 0, logged = 0;
    try {
      for (final day in (await log.prayers(start, end)).values) {
        for (final status in day.values) {
          if (status == PrayerLogStatus.excused) continue;
          logged++;
          if (status == PrayerLogStatus.onTime) onTime++;
        }
      }
    } catch (_) {
      // Without the log the rest of the week still shows.
    }
    return (
      khatmaUnits: units,
      khatmaUnit: khatma?.trackingUnit,
      adhkarSessions: sessions,
      prayersOnTime: onTime,
      prayersLogged: logged,
    );
  }
}
