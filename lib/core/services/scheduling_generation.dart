import 'package:shared_preferences/shared_preferences.dart';

/// A counter the app increases every time its UI isolate starts rewriting
/// scheduled notifications.
///
/// The UI isolate and a WorkManager background isolate both cancel and
/// recreate the same notification IDs. A background reschedule records the
/// value when it starts and stops before its next write once the value has
/// changed, so the UI's newer schedule is never overwritten by an older run.
abstract final class SchedulingGeneration {
  static const String preferenceKey = 'notification_scheduling_generation';

  /// The current value; 0 when never set or not an int.
  static int read(SharedPreferences preferences) {
    final value = preferences.get(preferenceKey);
    return value is int ? value : 0;
  }

  /// Marks that the UI isolate now owns the schedule.
  static Future<void> bump(SharedPreferences preferences) =>
      preferences.setInt(preferenceKey, read(preferences) + 1);
}
