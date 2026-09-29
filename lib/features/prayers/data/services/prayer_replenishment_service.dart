import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/prayer_calculation_policy.dart';
import '../../domain/prayer_time_zone.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import '../../domain/services/prayer_notification_scheduler.dart';
import 'local_prayer_notification_scheduler.dart';

/// Fetches actual daily timings using saved coordinates, never background GPS.
class PrayerReplenishmentService {
  PrayerReplenishmentService({
    required this.preferences,
    required this.repository,
    required this.scheduler,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final SharedPreferences preferences;
  final PrayerTimesRepository repository;
  final PrayerNotificationScheduler scheduler;
  final DateTime Function() _now;

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

    final instant = _now();
    var date = DateTime(instant.year, instant.month, instant.day);
    var timings = await repository.getPrayerTimes(
      date,
      latitude,
      longitude,
      calculationMethod: method,
    );
    // First response supplies the selected location's timezone. A device may
    // already be on a different calendar day after travel or manual selection.
    if (prayerLocation(timings.timezone) == null) {
      throw StateError('Prayer timezone is required for background scheduling');
    }
    final wall = prayerWallTime(instant, timings.timezone);
    final today = DateTime(wall.year, wall.month, wall.day);
    for (var offset = 0; offset < 3; offset++) {
      final target = DateTime(today.year, today.month, today.day + offset);
      if (target != date) {
        timings = await repository.getPrayerTimes(
          target,
          latitude,
          longitude,
          calculationMethod: method,
        );
        date = target;
      }
      if (prayerLocation(timings.timezone) == null) {
        throw StateError(
          'Prayer timezone is required for background scheduling',
        );
      }
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
              method) {
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
