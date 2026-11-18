import 'package:sakina_app/l10n/localization.dart';

import '../accessibility/digit_style.dart';
import 'notification_style.dart';
import '../../features/quran/data/daily_verse_source.dart';
import '../../features/prayers/domain/entities/adhan_settings.dart';

/// What each kind of notification says. Pure, so it is tested directly.
abstract final class NotificationContent {
  /// The look of a daily reminder: adhkar or Quran reading. Every daily
  /// reminder has always used the reminders channel, and still does.
  static SakinaNotificationKind dailyReminderKind(String? payload) =>
      switch (payload) {
        'morning_adhkar' || 'evening_adhkar' => SakinaNotificationKind.adhkar,
        _ => SakinaNotificationKind.quranReading,
      };

  /// Fixed wording for the built-in daily reminders; others keep theirs.
  static ({String title, String body}) dailyReminderContent({
    required String title,
    required String body,
    String? payload,
  }) {
    switch (payload) {
      case 'morning_adhkar':
        return (
          title: appL10n.notificationServiceMessage9,
          body: appL10n.notificationServiceMessage10,
        );
      case 'evening_adhkar':
        return (
          title: appL10n.notificationServiceMessage11,
          body: appL10n.notificationServiceMessage12,
        );
      case 'mulk_surah':
        return (
          title: appL10n.notificationServiceMessage13,
          body: appL10n.notificationServiceMessage14,
        );
      case 'baqarah_surah':
        return (
          title: appL10n.notificationServiceMessage15,
          body: appL10n.notificationServiceMessage16,
        );
      default:
        return (title: title, body: body);
    }
  }

  /// What a prayer alert or "prayer is near" reminder says. The alert keeps
  /// its title and body and adds the prayer time; the reminder, which had
  /// only a title, now says when the prayer is. [prayerTime] is when the
  /// notification fires: for a reminder, [reminderMinutes] before the prayer.
  static ({
    SakinaNotificationKind kind,
    String title,
    String body,
    String? summary,
  })
  prayerNotificationContent({
    required String prayerName,
    required DateTime prayerTime,
    PrayerAlertMode mode = PrayerAlertMode.sound,
    bool isReminder = false,
    int reminderMinutes = 0,
    DigitStyle digits = DigitStyle.western,
  }) {
    if (isReminder) {
      final String time = formatNotificationTime(
        prayerTime.add(Duration(minutes: reminderMinutes)),
        digits,
      );
      return (
        kind: SakinaNotificationKind.prayerReminder,
        title: appL10n.prayerReminderBody(
          applyDigitStyle('$reminderMinutes', digits),
          prayerName,
        ),
        body: appL10n.prayerReminderTimeLine(time),
        summary: null,
      );
    }
    final String time = formatNotificationTime(prayerTime, digits);
    return (
      kind: mode == PrayerAlertMode.notificationOnly
          ? SakinaNotificationKind.prayerSilent
          : SakinaNotificationKind.prayer,
      title: appL10n.notificationServiceMessage17(prayerName),
      body: appL10n.prayerNotificationBody,
      summary: appL10n.prayerNotificationTimeLine(time),
    );
  }

  /// Title, the whole ayah as the body, and where it is in the Quran.
  static ({String title, String body, String summary})
  dailyVerseNotificationContent(DailyVerse verse, DigitStyle digits) => (
    title: appL10n.notificationCategoryVerse,
    body: verse.text,
    summary: appL10n.dailyVerseNotificationReference(
      verse.surahName,
      applyDigitStyle('${verse.ayah}', digits),
    ),
  );
}
