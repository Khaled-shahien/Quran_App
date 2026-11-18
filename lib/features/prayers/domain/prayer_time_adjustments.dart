import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// The six daily times a user can shift by whole minutes.
enum PrayerTimeKind { fajr, sunrise, dhuhr, asr, maghrib, isha }

/// Minutes added to the calculated times, per time, so they can match the
/// local mosque or the official timetable. Applied after the method's own
/// adjustments, in the foreground and in the background reschedule alike.
class PrayerTimeAdjustments {
  const PrayerTimeAdjustments([this.minutes = const {}]);

  static const PrayerTimeAdjustments none = PrayerTimeAdjustments();

  /// Stored as one JSON value so all six are always written together.
  static const String preferenceKey = 'prayer_time_adjustments';

  /// Largest shift either way, in minutes.
  static const int limit = 30;

  final Map<PrayerTimeKind, int> minutes;

  int of(PrayerTimeKind kind) => minutes[kind] ?? 0;

  bool get isEmpty => minutes.values.every((m) => m == 0);

  PrayerTimeAdjustments withMinutes(PrayerTimeKind kind, int value) {
    final int clamped = value.clamp(-limit, limit);
    final Map<PrayerTimeKind, int> next = {...minutes};
    if (clamped == 0) {
      next.remove(kind);
    } else {
      next[kind] = clamped;
    }
    return PrayerTimeAdjustments(next);
  }

  /// Invalid or out-of-range stored values are ignored, never thrown.
  static PrayerTimeAdjustments read(SharedPreferences prefs) {
    final Object? raw = prefs.get(preferenceKey);
    if (raw is! String) return none;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) return none;
      final Map<PrayerTimeKind, int> minutes = {};
      for (final PrayerTimeKind kind in PrayerTimeKind.values) {
        final Object? value = decoded[kind.name];
        if (value is int && value != 0 && value.abs() <= limit) {
          minutes[kind] = value;
        }
      }
      return PrayerTimeAdjustments(minutes);
    } on FormatException {
      return none;
    }
  }

  Future<void> write(SharedPreferences prefs) => isEmpty
      ? prefs.remove(preferenceKey)
      : prefs.setString(
          preferenceKey,
          jsonEncode({
            for (final MapEntry(:key, :value) in minutes.entries)
              key.name: value,
          }),
        );

  @override
  bool operator ==(Object other) =>
      other is PrayerTimeAdjustments &&
      PrayerTimeKind.values.every((k) => of(k) == other.of(k));

  @override
  int get hashCode => Object.hashAll(PrayerTimeKind.values.map(of));
}
