import 'package:sakina_app/core/services/prayer_alert_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/prayers/data/services/prayer_replenishment_service.dart';
import 'package:sakina_app/features/prayers/domain/repositories/prayer_times_repository.dart';
import 'package:sakina_app/features/prayers/domain/services/prayer_notification_scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina_app/features/prayers/domain/entities/adhan_settings.dart';
import 'package:sakina_app/features/prayers/domain/prayer_window.dart';

/// iOS keeps at most 64 pending notifications and cannot be relied on to
/// replenish in the background (audit NOTIF-03, task P2-01).
class _NoRepository implements PrayerTimesRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AdhanSettings settings({
    int reminder = 0,
    Map<DailyPrayer, PrayerAlertMode> modes = const {},
  }) {
    var s = AdhanSettings(reminderMinutes: reminder);
    for (final e in modes.entries) {
      s = s.withMode(e.key, e.value);
    }
    return s;
  }

  test('Android keeps the 3-day window', () {
    expect(prayerWindowDays(settings(reminder: 10), ios: false), 3);
  });

  test('iOS: as many days as fit, never above the 7 weekday slots', () {
    // 5 alerts + 5 reminders a day → 50 / 10 = 5 days.
    expect(prayerWindowDays(settings(reminder: 10), ios: true), 5);
    // 5 alerts a day → 10 days fit, capped at 7.
    expect(prayerWindowDays(settings(), ios: true), maxPrayerWindowDays);
    // Everything silent: nothing to budget.
    expect(
      prayerWindowDays(
        settings(
          modes: {
            for (final p in DailyPrayer.values) p: PrayerAlertMode.silent,
          },
        ),
        ios: true,
      ),
      androidPrayerWindowDays,
    );
  });

  test('the iOS pending total stays within 64 for every setting', () {
    for (var alerting = 0; alerting <= 5; alerting++) {
      for (final reminder in [0, 10]) {
        final s = settings(
          reminder: reminder,
          modes: {
            for (final p in DailyPrayer.values.skip(alerting))
              p: PrayerAlertMode.silent,
          },
        );
        final days = prayerWindowDays(s, ios: true);
        final perDay = alerting * (reminder > 0 ? 2 : 1);
        expect(
          days * perDay + iosReservedNotifications,
          lessThanOrEqualTo(iosPendingNotificationLimit),
          reason: '$alerting alerting prayers, reminder $reminder',
        );
      }
    }
  });

  test('the window-ending notice comes at noon on the last day', () {
    expect(
      PrayerAlertNotifications.prayerWindowEndingAt(DateTime(2026, 1, 14, 23)),
      DateTime(2026, 1, 14, 12),
    );
  });

  test('replenishment uses the platform window by default', () async {
    SharedPreferences.setMockInitialValues({});
    final service = PrayerReplenishmentService(
      preferences: await SharedPreferences.getInstance(),
      repository: _NoRepository(),
      scheduler: const NoopPrayerNotificationScheduler(),
    );
    expect(service.days, androidPrayerWindowDays);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(service.days, maxPrayerWindowDays);
  });
}
