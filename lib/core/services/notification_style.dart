import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../../features/prayers/domain/adhan_voices.dart';
import '../accessibility/digit_style.dart';
import '../theme/app_colors.dart';
import 'notification_channels.dart';

/// What a notification is about. Each kind keeps the channel it has always
/// used, so users' per-channel settings on Android stay as they set them.
enum SakinaNotificationKind {
  adhkar,
  quranReading,
  prayer,
  prayerSilent,
  prayerReminder,
  dailyVerse,
  general,
  test,
}

/// Stable ids of notification buttons, reported back when one is tapped.
abstract final class NotificationActionIds {
  /// Opens the notification's own destination, like tapping its body.
  static const String open = 'open';

  /// Opens the prayer times screen.
  static const String prayerTimes = 'open_prayer_times';

  /// Ends the adhan without opening the app.
  static const String stopAdhan = 'stop_adhan';
}

/// The shared look of every Sakina notification: brand colour, the bell as
/// small icon, the app icon as large icon, the category or [summary] in the
/// header, text that expands instead of being cut to one line, and the
/// buttons and channel that belong to the [kind].
///
/// [adhanVoice] turns a [SakinaNotificationKind.prayer] alert into the adhan:
/// on Android it goes to that recording's channel, whose sound is the
/// recording. iOS keeps the alert sound (see `ADHAN_AUDIO_LIBRARY.md`).
NotificationDetails buildNotificationDetails(
  SakinaNotificationKind kind, {
  String? title,
  String? body,
  String? summary,
  DateTime? when,
  Duration? timeoutAfter,
  AdhanVoice? adhanVoice,
}) {
  final AdhanVoice? adhan = kind == SakinaNotificationKind.prayer
      ? adhanVoice
      : null;
  final _Channel channel = adhan == null
      ? _channelFor(kind)
      : _adhanChannel(adhan);
  final String? category = notificationCategoryLabel(kind);
  return NotificationDetails(
    android: AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: Priority.high,
      icon: notificationSmallIcon,
      largeIcon: const DrawableResourceAndroidBitmap(notificationLargeIcon),
      color: AppColors.lightPrimary,
      playSound: channel.playSound,
      // Android 8+ takes the sound from the channel; older versions from here.
      sound: adhan == null
          ? null
          : RawResourceAndroidNotificationSound(adhan.resource),
      enableVibration: true,
      category: channel.category,
      // The header line: the detail when there is one (where the verse is,
      // when the prayer is), otherwise the category. Android 12+ does not
      // show a big-text summary line, so the detail goes here instead.
      subText: summary ?? category,
      styleInformation: body == null
          ? null
          : BigTextStyleInformation(body, contentTitle: title),
      when: when?.millisecondsSinceEpoch,
      showWhen: true,
      timeoutAfter: timeoutAfter?.inMilliseconds,
      actions: <AndroidNotificationAction>[
        // Cancelling the notification is what stops its channel's sound.
        if (adhan != null)
          AndroidNotificationAction(
            NotificationActionIds.stopAdhan,
            appL10n.notificationActionStopAdhan,
            cancelNotification: true,
          ),
        for (final action in notificationActionsFor(kind))
          AndroidNotificationAction(
            action.id,
            action.label,
            // Every button opens the app, so taps arrive through the same
            // path as a body tap and no background isolate is needed.
            showsUserInterface: true,
          ),
      ],
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: channel.playSound,
      subtitle: summary ?? category,
      threadIdentifier: _threadFor(kind),
      categoryIdentifier: notificationActionsFor(kind).isEmpty
          ? null
          : darwinCategoryId(kind),
      interruptionLevel: switch (kind) {
        SakinaNotificationKind.adhkar ||
        SakinaNotificationKind.quranReading ||
        SakinaNotificationKind.prayer ||
        SakinaNotificationKind.prayerSilent => InterruptionLevel.timeSensitive,
        _ => InterruptionLevel.active,
      },
    ),
  );
}

/// Small icon: a white bell; Android draws it in [AppColors.lightPrimary].
const String notificationSmallIcon = '@drawable/ic_notification';

/// Large icon: a PNG copy of the launcher art. The launcher icon itself is
/// an adaptive-icon XML on Android 8+, which cannot be decoded as a bitmap.
const String notificationLargeIcon = '@drawable/ic_notification_large';

/// The category named in the notification header, or null for none.
String? notificationCategoryLabel(SakinaNotificationKind kind) =>
    switch (kind) {
      SakinaNotificationKind.adhkar => appL10n.notificationCategoryAdhkar,
      SakinaNotificationKind.quranReading => appL10n.notificationCategoryQuran,
      SakinaNotificationKind.prayer ||
      SakinaNotificationKind.prayerSilent ||
      SakinaNotificationKind.prayerReminder =>
        appL10n.notificationCategoryPrayer,
      SakinaNotificationKind.dailyVerse => appL10n.notificationCategoryVerse,
      SakinaNotificationKind.general || SakinaNotificationKind.test => null,
    };

/// A button shown on a notification.
typedef NotificationButton = ({String id, String label});

/// The buttons a [kind] of notification offers, in display order.
List<NotificationButton> notificationActionsFor(SakinaNotificationKind kind) =>
    switch (kind) {
      SakinaNotificationKind.adhkar => [
        (
          id: NotificationActionIds.open,
          label: appL10n.notificationActionStartAdhkar,
        ),
      ],
      SakinaNotificationKind.quranReading => [
        (
          id: NotificationActionIds.open,
          label: appL10n.notificationActionReadNow,
        ),
      ],
      SakinaNotificationKind.prayer || SakinaNotificationKind.prayerSilent => [
        (
          id: NotificationActionIds.open,
          label: appL10n.notificationActionAfterAdhan,
        ),
        (
          id: NotificationActionIds.prayerTimes,
          label: appL10n.notificationActionPrayerTimes,
        ),
      ],
      SakinaNotificationKind.prayerReminder => [
        (
          id: NotificationActionIds.prayerTimes,
          label: appL10n.notificationActionPrayerTimes,
        ),
      ],
      SakinaNotificationKind.dailyVerse => [
        (
          id: NotificationActionIds.open,
          label: appL10n.notificationActionOpenVerse,
        ),
      ],
      SakinaNotificationKind.general || SakinaNotificationKind.test => [],
    };

/// The iOS category that carries a [kind]'s buttons.
String darwinCategoryId(SakinaNotificationKind kind) => 'sakina_${kind.name}';

/// iOS categories for every kind with buttons; register them at startup.
List<DarwinNotificationCategory> darwinNotificationCategories() => [
  for (final kind in SakinaNotificationKind.values)
    if (notificationActionsFor(kind).isNotEmpty)
      DarwinNotificationCategory(
        darwinCategoryId(kind),
        actions: [
          for (final action in notificationActionsFor(kind))
            DarwinNotificationAction.plain(
              action.id,
              action.label,
              options: const {DarwinNotificationActionOption.foreground},
            ),
        ],
      ),
];

/// [time] as the clock reads it, e.g. `04:52 ص`, in the user's digits.
String formatNotificationTime(DateTime time, DigitStyle digits) {
  final int hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final String period = time.hour >= 12
      ? appL10n.alarmMenuItemMessage2
      : appL10n.alarmMenuItemMessage3;
  final String text =
      '${hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')} $period';
  return applyDigitStyle(text, digits);
}

String? _threadFor(SakinaNotificationKind kind) => switch (kind) {
  SakinaNotificationKind.adhkar => 'sakina.adhkar',
  SakinaNotificationKind.quranReading ||
  SakinaNotificationKind.dailyVerse => 'sakina.quran',
  SakinaNotificationKind.prayer ||
  SakinaNotificationKind.prayerSilent ||
  SakinaNotificationKind.prayerReminder => 'sakina.prayer',
  SakinaNotificationKind.general || SakinaNotificationKind.test => null,
};

typedef _Channel = ({
  String id,
  String name,
  String? description,
  Importance importance,
  bool playSound,
  AndroidNotificationCategory? category,
});

_Channel _adhanChannel(AdhanVoice voice) {
  final channel = NotificationChannels.adhan(voice);
  return (
    id: channel.id,
    name: channel.name,
    description: channel.description,
    importance: channel.importance,
    playSound: true,
    category: AndroidNotificationCategory.alarm,
  );
}

/// Channel settings exactly as each kind used before the shared style.
_Channel _channelFor(SakinaNotificationKind kind) => switch (kind) {
  SakinaNotificationKind.adhkar || SakinaNotificationKind.quranReading => (
    id: NotificationChannels.alarmsId,
    name: NotificationChannels.alarmsName,
    description: NotificationChannels.alarmsDescription,
    importance: Importance.max,
    playSound: true,
    category: AndroidNotificationCategory.alarm,
  ),
  SakinaNotificationKind.prayer => (
    id: NotificationChannels.prayerId,
    name: NotificationChannels.prayerName,
    description: NotificationChannels.prayerDescription,
    importance: Importance.max,
    playSound: true,
    category: AndroidNotificationCategory.alarm,
  ),
  SakinaNotificationKind.prayerSilent => (
    id: NotificationChannels.prayerSilentId,
    name: appL10n.prayerSilentChannel,
    description: null,
    importance: Importance.high,
    playSound: false,
    category: AndroidNotificationCategory.reminder,
  ),
  SakinaNotificationKind.prayerReminder => (
    id: NotificationChannels.prayerReminderId,
    name: appL10n.prayerReminderChannel,
    description: null,
    importance: Importance.high,
    playSound: true,
    category: AndroidNotificationCategory.reminder,
  ),
  SakinaNotificationKind.dailyVerse => (
    id: NotificationChannels.dailyVerseId,
    name: NotificationChannels.dailyVerseName,
    description: NotificationChannels.dailyVerseDescription,
    importance: Importance.defaultImportance,
    playSound: true,
    category: AndroidNotificationCategory.reminder,
  ),
  SakinaNotificationKind.general => (
    id: NotificationChannels.defaultId,
    name: NotificationChannels.defaultName,
    description: NotificationChannels.defaultDescription,
    importance: Importance.high,
    playSound: true,
    category: null,
  ),
  SakinaNotificationKind.test => (
    id: NotificationChannels.testId,
    name: NotificationChannels.testName,
    description: NotificationChannels.testDescription,
    importance: Importance.max,
    playSound: true,
    category: null,
  ),
};
