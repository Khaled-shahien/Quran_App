import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/prayers/data/services/local_prayer_notification_scheduler.dart';
import 'package:sakina_app/features/prayers/domain/Entities/prayer_times_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePrayerNotificationGateway implements PrayerNotificationGateway {
  int scheduleCalls = 0;
  int cancelCalls = 0;
  Map<String, DateTime>? scheduledPrayerTimes;

  @override
  Future<void> cancelAllPrayerNotifications() async {
    cancelCalls++;
  }

  @override
  Future<void> scheduleAllPrayersToday({
    required Map<String, DateTime> prayerTimes,
  }) async {
    scheduleCalls++;
    scheduledPrayerTimes = Map<String, DateTime>.from(prayerTimes);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'schedules in the selected timezone rather than device timezone',
    () async {
      SharedPreferences.setMockInitialValues({});
      final gateway = FakePrayerNotificationGateway();
      final scheduler = LocalPrayerNotificationScheduler(
        prefs: await SharedPreferences.getInstance(),
        notificationGateway: gateway,
      );
      await scheduler.schedulePrayerNotifications(
        date: DateTime(2026, 1, 1),
        prayerTimes: PrayerTimesEntity(fajr: '05:00', timezone: 'Asia/Riyadh'),
      );
      expect(
        gateway.scheduledPrayerTimes!['الفجر']!.toUtc(),
        DateTime.utc(2026, 1, 1, 2),
      );
    },
  );

  test('schedules the five daily prayer notifications', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final gateway = FakePrayerNotificationGateway();
    final scheduler = LocalPrayerNotificationScheduler(
      prefs: prefs,
      notificationGateway: gateway,
    );

    await scheduler.schedulePrayerNotifications(
      date: DateTime(2026, 3, 23),
      prayerTimes: PrayerTimesEntity(
        fajr: '05:00 (EET)',
        sunrise: '06:20',
        dhuhr: '12:15',
        asr: '15:40',
        maghrib: '18:30',
        isha: '19:45',
      ),
    );

    expect(gateway.scheduleCalls, 1);
    expect(gateway.cancelCalls, 0);
    expect(gateway.scheduledPrayerTimes, isNotNull);
    expect(gateway.scheduledPrayerTimes!.keys, <String>[
      'الفجر',
      'الظهر',
      'العصر',
      'المغرب',
      'العشاء',
    ]);
    expect(gateway.scheduledPrayerTimes!['الفجر'], DateTime(2026, 3, 23, 5));
    expect(
      gateway.scheduledPrayerTimes!['العشاء'],
      DateTime(2026, 3, 23, 19, 45),
    );
  });

  test('cancels prayer notifications when preference is disabled', () async {
    SharedPreferences.setMockInitialValues({
      LocalPrayerNotificationScheduler.prayerNotificationsEnabledPreferenceKey:
          false,
    });
    final prefs = await SharedPreferences.getInstance();
    final gateway = FakePrayerNotificationGateway();
    final scheduler = LocalPrayerNotificationScheduler(
      prefs: prefs,
      notificationGateway: gateway,
    );

    await scheduler.schedulePrayerNotifications(
      date: DateTime(2026, 3, 23),
      prayerTimes: PrayerTimesEntity(fajr: '05:00'),
    );

    expect(gateway.scheduleCalls, 0);
    expect(gateway.cancelCalls, 1);
  });
}
