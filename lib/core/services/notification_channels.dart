import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sakina_app/l10n/localization.dart';

/// Android notification channels used by `NotificationService`.
///
/// Android fixes a channel's sound when the channel is first created, so each
/// sound has its own versioned channel id. Changing an id here creates a new
/// channel on users' phones; never rename one without a migration plan.
abstract final class NotificationChannels {
  static const String defaultId = 'sakina_app_channel';
  static final String defaultName = appL10n.notificationServiceMessage1;
  static final String defaultDescription = appL10n.notificationServiceMessage2;

  static const String alarmsId = 'sakina_alarms_channel';
  static final String alarmsName = appL10n.notificationServiceMessage3;
  static final String alarmsDescription = appL10n.notificationServiceMessage4;

  static const String prayerId = 'prayer_times_default_sound_v2';
  static final String prayerName = appL10n.notificationServiceMessage5;
  static final String prayerDescription = appL10n.notificationServiceMessage6;

  // Adhan channels will be named per muezzin.
  static const String prayerSilentId = 'prayer_times_silent_v1';
  static const String prayerReminderId = 'prayer_reminders_v1';

  static const String testId = 'test_channel';
  static final String testName = appL10n.notificationServiceMessage7;
  static final String testDescription = appL10n.notificationServiceMessage8;

  /// Every channel the app creates on Android, in creation order.
  static List<AndroidNotificationChannel> all() => <AndroidNotificationChannel>[
    AndroidNotificationChannel(
      defaultId,
      defaultName,
      description: defaultDescription,
      importance: Importance.high,
    ),
    AndroidNotificationChannel(
      alarmsId,
      alarmsName,
      description: alarmsDescription,
      importance: Importance.max,
    ),
    AndroidNotificationChannel(
      prayerId,
      prayerName,
      description: prayerDescription,
      importance: Importance.max,
      // Platform default sound until a licensed adhan is bundled.
      playSound: true,
      enableVibration: true,
    ),
    AndroidNotificationChannel(
      prayerSilentId,
      appL10n.prayerSilentChannel,
      importance: Importance.high,
      playSound: false,
      enableVibration: true,
    ),
    AndroidNotificationChannel(
      prayerReminderId,
      appL10n.prayerReminderChannel,
      importance: Importance.high,
    ),
    AndroidNotificationChannel(
      testId,
      testName,
      description: testDescription,
      importance: Importance.max,
    ),
  ];
}
