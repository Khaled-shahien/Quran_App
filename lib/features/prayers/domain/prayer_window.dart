import 'entities/adhan_settings.dart';

/// How many days of prayer alerts are scheduled ahead (day 0 = today).
///
/// Android replenishes in the background every 12 hours, so 3 days are
/// enough. iOS runs background work only when the system allows and keeps at
/// most 64 pending notifications per app, so it schedules as many days as fit
/// beside the app's other notifications, up to the 7 weekday ID slots
/// (audit NOTIF-03).
const int androidPrayerWindowDays = 3;
const int maxPrayerWindowDays = 7;

/// The iOS per-app limit on pending notifications.
const int iosPendingNotificationLimit = 64;

/// Pending notifications iOS must keep free for everything else: 4 daily
/// reminders, 7 daily verses, the khatma reminder, the window-ending notice
/// and the test alert.
const int iosReservedNotifications = 14;

int prayerWindowDays(AdhanSettings settings, {required bool ios}) {
  if (!ios) return androidPrayerWindowDays;
  final alerting = DailyPrayer.values
      .where((p) => settings.modeFor(p) != PrayerAlertMode.silent)
      .length;
  final perDay = alerting * (settings.hasReminder ? 2 : 1);
  if (perDay == 0) return androidPrayerWindowDays;
  final fit =
      (iosPendingNotificationLimit - iosReservedNotifications) ~/ perDay;
  return fit.clamp(androidPrayerWindowDays, maxPrayerWindowDays);
}
