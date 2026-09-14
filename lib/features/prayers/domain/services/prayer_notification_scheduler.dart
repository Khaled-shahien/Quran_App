import 'package:sakina_app/features/prayers/domain/Entities/prayer_times_entity.dart';

/// Schedules prayer-time notifications once prayer times are available.
abstract class PrayerNotificationScheduler {
  Future<void> schedulePrayerNotifications({
    required PrayerTimesEntity prayerTimes,
    required DateTime date,
  });
}

/// Test/default implementation that keeps providers free of platform side effects.
class NoopPrayerNotificationScheduler implements PrayerNotificationScheduler {
  const NoopPrayerNotificationScheduler();

  @override
  Future<void> schedulePrayerNotifications({
    required PrayerTimesEntity prayerTimes,
    required DateTime date,
  }) async {}
}
