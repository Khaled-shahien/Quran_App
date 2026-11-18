import 'package:shared_preferences/shared_preferences.dart';

import 'entities/adhan_settings.dart';

/// What happens around the adhan beyond the notification itself: a quiet
/// period afterwards (Do Not Disturb) and the Fajr wake alarm. All off by
/// default; Android only.
class AfterAdhanSettings {
  const AfterAdhanSettings({
    this.quietMinutes = 0,
    this.fajrWake = false,
    this.snoozeMinutes = 5,
  });

  /// 0 means no quiet period.
  static const List<int> quietOptions = [0, 15, 20, 30, 45, 60];
  static const List<int> snoozeOptions = [5, 10];

  /// The quiet period starts this long after the prayer time, so the adhan
  /// itself is still heard.
  static const Duration quietDelay = Duration(minutes: 5);

  final int quietMinutes;
  final bool fajrWake;
  final int snoozeMinutes;

  bool get hasQuiet => quietMinutes > 0;

  AfterAdhanSettings copyWith({
    int? quietMinutes,
    bool? fajrWake,
    int? snoozeMinutes,
  }) => AfterAdhanSettings(
    quietMinutes: quietMinutes ?? this.quietMinutes,
    fajrWake: fajrWake ?? this.fajrWake,
    snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
  );
}

/// Synchronous so the background rescheduler can read it.
class AfterAdhanSettingsStore {
  const AfterAdhanSettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static const String quietKey = 'adhan_quiet_minutes';
  static const String wakeKey = 'fajr_wake_enabled';
  static const String snoozeKey = 'fajr_wake_snooze_minutes';

  AfterAdhanSettings read() {
    final quiet = _prefs.get(quietKey);
    final wake = _prefs.get(wakeKey);
    final snooze = _prefs.get(snoozeKey);
    return AfterAdhanSettings(
      quietMinutes:
          quiet is int && AfterAdhanSettings.quietOptions.contains(quiet)
          ? quiet
          : 0,
      fajrWake: wake is bool && wake,
      snoozeMinutes:
          snooze is int && AfterAdhanSettings.snoozeOptions.contains(snooze)
          ? snooze
          : 5,
    );
  }

  Future<void> write(AfterAdhanSettings settings) async {
    await _prefs.setInt(quietKey, settings.quietMinutes);
    await _prefs.setBool(wakeKey, settings.fajrWake);
    await _prefs.setInt(snoozeKey, settings.snoozeMinutes);
  }
}

/// The quiet windows of one day: after each prayer that alerts, starting
/// [AfterAdhanSettings.quietDelay] after its time. Windows already over at
/// [now] are left out.
List<({DateTime start, DateTime end})> planQuietWindows({
  required Map<DailyPrayer, DateTime> times,
  required AdhanSettings alerts,
  required AfterAdhanSettings after,
  required DateTime now,
}) {
  if (!after.hasQuiet) return const [];
  final windows = <({DateTime start, DateTime end})>[];
  for (final prayer in DailyPrayer.values) {
    final at = times[prayer];
    if (at == null || alerts.modeFor(prayer) == PrayerAlertMode.silent) {
      continue;
    }
    final start = at.add(AfterAdhanSettings.quietDelay);
    final end = start.add(Duration(minutes: after.quietMinutes));
    if (end.isAfter(now)) windows.add((start: start, end: end));
  }
  return windows;
}

/// Whether a wake alarm replaces the Fajr notification on this day: the
/// user turned it on, Fajr is still ahead and sunrise follows it.
bool wakesForFajr({
  required AfterAdhanSettings after,
  required DateTime? fajr,
  required DateTime? sunrise,
  required DateTime now,
}) =>
    after.fajrWake &&
    fajr != null &&
    sunrise != null &&
    fajr.isAfter(now) &&
    sunrise.isAfter(fajr);
