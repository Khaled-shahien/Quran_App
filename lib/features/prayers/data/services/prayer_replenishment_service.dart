import 'package:sakina_app/core/result/result.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/prayer_calculation_policy.dart';
import '../../domain/prayer_time_zone.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import '../../domain/services/prayer_notification_scheduler.dart';

import 'local_prayer_notification_scheduler.dart';

/// Recalculates the next days' prayer times from the saved settings and
/// schedules them. Runs in the background; never uses GPS or the network.
class PrayerReplenishmentService {
  PrayerReplenishmentService({
    required this.preferences,
    required this.repository,
    required this.scheduler,
    DateTime Function()? now,
    this.days = 3,
  }) : _now = now ?? DateTime.now;

  final SharedPreferences preferences;
  final PrayerTimesRepository repository;
  final PrayerNotificationScheduler scheduler;
  final DateTime Function() _now;

  /// How many consecutive days, starting today, to schedule.
  final int days;

  Future<void> replenish() async {
    await preferences.reload();
    if (!(preferences.getBool('prayer_notifications_enabled') ?? true)) {
      await scheduler.cancelPrayerNotifications();
      return;
    }
    final latitude = preferences.getDouble('prayer_latitude');
    final longitude = preferences.getDouble('prayer_longitude');
    final method =
        preferences.getInt('prayer_method') ??
        PrayerCalculationPolicy.defaultMethod;
    final storedZone = preferences.getString(prayerTimeZonePreferenceKey);
    final madhab = AsrMadhab.fromStorage(
      preferences.get(AsrMadhab.preferenceKey),
    );
    if (latitude == null ||
        longitude == null ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180 ||
        !PrayerCalculationPolicy.methods.containsKey(method)) {
      await scheduler.cancelPrayerNotifications();
      return;
    }

    // "Today" is the calendar day at the prayer location, which can differ
    // from the device's day after travel or a manually chosen city.
    final wall = prayerWallTime(_now(), storedZone);
    final today = DateTime(wall.year, wall.month, wall.day);
    for (var offset = 0; offset < days; offset++) {
      final target = DateTime(today.year, today.month, today.day + offset);
      final result = await repository.getPrayerTimes(
        target,
        latitude,
        longitude,
        calculationMethod: method,
        madhab: madhab,
        timeZone: storedZone,
      );
      final timings = switch (result) {
        Success(:final value) => value,
        Err(:final failure) => throw StateError(
          'Prayer times could not be calculated: ${failure.cause}',
        ),
      };
      if (LocalPrayerNotificationScheduler.buildPrayerSchedule(
            prayerTimes: timings,
            date: target,
          ).length !=
          5) {
        throw StateError('Incomplete daily prayer timings');
      }
      await preferences.reload();
      if (!(preferences.getBool('prayer_notifications_enabled') ?? true) ||
          preferences.getDouble('prayer_latitude') != latitude ||
          preferences.getDouble('prayer_longitude') != longitude ||
          (preferences.getInt('prayer_method') ??
                  PrayerCalculationPolicy.defaultMethod) !=
              method ||
          preferences.getString(prayerTimeZonePreferenceKey) != storedZone ||
          AsrMadhab.fromStorage(preferences.get(AsrMadhab.preferenceKey)) !=
              madhab) {
        // The foreground selection owns cancellation/replacement of old alarms.
        return;
      }
      await scheduler.schedulePrayerNotifications(
        prayerTimes: timings,
        date: target,
      );
    }
  }
}
