import 'package:shared_preferences/shared_preferences.dart';

import '../../features/prayers/domain/entities/adhan_settings.dart';

/// Morning and evening adhkar reminders tied to the day's prayer times
/// instead of a fixed clock time: "N minutes after Fajr" and "N minutes
/// after Asr". The clock times drift away from the adhkar windows across
/// the seasons; anchored ones follow them.
///
/// An anchored reminder is planned with each day's prayer alerts (in the
/// foreground and in the background reschedule), so it uses that day's
/// times and the same scheduling window. The daily clock-time reminder of
/// the same kind is not scheduled while its anchor is set.
abstract final class AnchoredReminders {
  /// Minutes after Fajr; absent means the clock time is used.
  static const String morningKey = 'morning_alarm_anchor_minutes';

  /// Minutes after Asr; absent means the clock time is used.
  static const String eveningKey = 'evening_alarm_anchor_minutes';

  static const String morningEnabledKey = 'morning_alarm_enabled';
  static const String eveningEnabledKey = 'evening_alarm_enabled';

  /// Offsets offered in Settings.
  static const List<int> options = [0, 10, 15, 20, 30, 45, 60];

  static int? _minutes(SharedPreferences prefs, String key) {
    final Object? value = prefs.get(key);
    return value is int && options.contains(value) ? value : null;
  }

  static int? morning(SharedPreferences prefs) => _minutes(prefs, morningKey);
  static int? evening(SharedPreferences prefs) => _minutes(prefs, eveningKey);

  static Future<void> setMorning(SharedPreferences prefs, int? minutes) =>
      minutes == null
      ? prefs.remove(morningKey)
      : prefs.setInt(morningKey, minutes);

  static Future<void> setEvening(SharedPreferences prefs, int? minutes) =>
      minutes == null
      ? prefs.remove(eveningKey)
      : prefs.setInt(eveningKey, minutes);

  /// Seven weekday slots each, like prayer alerts (5011–5072).
  static int morningId(DateTime date) => 5001 + date.weekday * 10;
  static int eveningId(DateTime date) => 5002 + date.weekday * 10;

  static Iterable<int> allIds() sync* {
    for (var slot = 0; slot <= 7; slot++) {
      yield 5001 + slot * 10;
      yield 5002 + slot * 10;
    }
  }

  /// The anchored reminders of one day still ahead of [now].
  static List<AnchoredReminder> plan({
    required Map<DailyPrayer, DateTime> prayerTimes,
    required SharedPreferences prefs,
    required DateTime now,
  }) {
    final List<AnchoredReminder> plan = [];
    final int? morningMinutes = morning(prefs);
    final DateTime? fajr = prayerTimes[DailyPrayer.fajr];
    if ((prefs.getBool(morningEnabledKey) ?? false) &&
        morningMinutes != null &&
        fajr != null) {
      final DateTime at = fajr.add(Duration(minutes: morningMinutes));
      if (at.isAfter(now)) {
        plan.add(
          AnchoredReminder(
            id: morningId(fajr),
            at: at,
            kind: AnchoredReminderKind.morning,
          ),
        );
      }
    }
    final int? eveningMinutes = evening(prefs);
    final DateTime? asr = prayerTimes[DailyPrayer.asr];
    if ((prefs.getBool(eveningEnabledKey) ?? false) &&
        eveningMinutes != null &&
        asr != null) {
      final DateTime at = asr.add(Duration(minutes: eveningMinutes));
      if (at.isAfter(now)) {
        plan.add(
          AnchoredReminder(
            id: eveningId(asr),
            at: at,
            kind: AnchoredReminderKind.evening,
          ),
        );
      }
    }
    return plan;
  }
}

enum AnchoredReminderKind { morning, evening }

class AnchoredReminder {
  const AnchoredReminder({
    required this.id,
    required this.at,
    required this.kind,
  });

  final int id;
  final DateTime at;
  final AnchoredReminderKind kind;
}
