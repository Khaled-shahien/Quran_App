import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:sakina_alarms/sakina_alarms.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'anchored_reminders.dart';
import 'notification_content.dart';
import 'notification_service.dart';
import 'notification_style.dart';
import '../accessibility/digit_style.dart';
import '../../features/prayers/domain/adhan_voices.dart';
import '../../features/prayers/domain/after_adhan.dart';
import '../../features/prayers/domain/entities/adhan_settings.dart';
import '../../features/prayers/domain/prayer_notification_ids.dart';
import '../../features/prayers/domain/services/prayer_alert_planner.dart';
import '../../features/prayers/presentation/prayer_labels.dart';

/// Prayer alerts, "prayer is near" reminders, the adhkar reminders that
/// follow a prayer, and the iOS "open the app" notice.
class PrayerAlertNotifications {
  PrayerAlertNotifications(this._core);

  final NotificationService _core;

  /// Schedule a one-time notification for a prayer time.
  ///
  /// [mode] picks the channel: the alert sound, a silent notification, or
  /// in adhan mode the channel of [adhanVoice], whose sound is the recording.
  Future<void> schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
    PrayerAlertMode mode = PrayerAlertMode.sound,
    bool isReminder = false,
    int reminderMinutes = 0,
    AdhanVoice? adhanVoice,
  }) async {
    await _core.initialize(requestPermissions: false);
    if (!_core.isPluginAvailable) return;

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      prayerTime,
      tz.local,
    );

    if (!scheduledDate.isAfter(now.add(const Duration(seconds: 5)))) {
      developer.log(
        'Skipping past prayer notification $id for $prayerName at $prayerTime',
        name: 'sakina_app.notifications',
      );
      return;
    }

    final content = NotificationContent.prayerNotificationContent(
      prayerName: prayerName,
      prayerTime: prayerTime,
      mode: mode,
      isReminder: isReminder,
      reminderMinutes: reminderMinutes,
      digits: await _core.digitStyle(),
    );
    final Duration lead = Duration(minutes: isReminder ? reminderMinutes : 0);
    NotificationDetails details({AdhanVoice? voice}) =>
        buildNotificationDetails(
          content.kind,
          title: content.title,
          body: content.body,
          summary: content.summary,
          when: prayerTime.add(lead),
          // The reminder leaves the tray when the prayer alert itself is due.
          timeoutAfter: lead > Duration.zero ? lead : null,
          adhanVoice: voice,
        );
    final AdhanVoice? voice = mode == PrayerAlertMode.adhan && !isReminder
        ? adhanVoice
        : null;

    final String serializedPayload = jsonEncode({
      'type': 'prayer_time',
      'data': <String, dynamic>{
        'prayerName': prayerName,
        'scheduledAt': prayerTime.toIso8601String(),
        if (isReminder) 'reminder': true,
      },
    });

    final AndroidScheduleMode scheduleMode = await _core.androidScheduleMode();
    Future<void> schedule(NotificationDetails d) =>
        _core.flutterLocalNotificationsPlugin.zonedSchedule(
          id: id,
          title: content.title,
          body: content.body,
          scheduledDate: scheduledDate,
          notificationDetails: d,
          androidScheduleMode: scheduleMode,
          payload: serializedPayload,
        );

    try {
      await schedule(details(voice: voice));
    } on PlatformException catch (error) {
      // A missing recording must not cost the user the prayer alert: fall
      // back to the alert sound and record why.
      if (voice == null || error.code != 'invalid_sound') rethrow;
      developer.log(
        'Adhan recording ${voice.resource} unavailable; using alert sound',
        name: 'sakina_app.notifications',
        level: 900,
        error: error,
      );
      await schedule(details());
    }

    developer.log(
      'Prayer notification $id scheduled for $prayerName at $scheduledDate',
      name: 'sakina_app.notifications',
    );
  }

  /// Replace only the supplied calendar day's slot, preserving other days.
  /// Prayers are keyed by [DailyPrayer]; display names are derived here and
  /// only shown.
  ///
  /// [sunrise] lets the Fajr wake alarm (Android) offer snooze until then.
  Future<void> scheduleAllPrayersForDate({
    required Map<DailyPrayer, DateTime> prayerTimes,
    AdhanSettings settings = const AdhanSettings(),
    DateTime? sunrise,
  }) async {
    if (prayerTimes.isEmpty) return;
    final date = prayerTimes.values.first;
    for (final prayer in DailyPrayer.values) {
      final legacyId = prayerBaseId(prayer);
      await _core.cancelNotification(legacyId);
      await _core.cancelNotification(prayerNotificationId(legacyId, date));
      await _core.cancelNotification(
        prayerReminderNotificationId(legacyId, date),
      );
    }
    await _core.cancelNotification(AnchoredReminders.morningId(date));
    await _core.cancelNotification(AnchoredReminders.eveningId(date));

    final names = <DailyPrayer, String>{
      for (final prayer in prayerTimes.keys) prayer: appL10n.prayerName(prayer),
    };
    final DigitStyle digits = await _core.digitStyle();

    final DateTime now = DateTime.now();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AfterAdhanSettings after = AfterAdhanSettingsStore(prefs).read();
    final bool android =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final bool wake =
        android &&
        wakesForFajr(
          after: after,
          fajr: prayerTimes[DailyPrayer.fajr],
          sunrise: sunrise,
          now: now,
        );

    for (final alert in planPrayerAlerts(
      times: prayerTimes,
      names: names,
      settings: settings,
      now: now,
      skipFajrAlert: wake,
    )) {
      await schedulePrayerNotification(
        id: alert.id,
        prayerName: alert.prayerName,
        prayerTime: alert.at,
        mode: alert.mode,
        isReminder: alert.kind == PlannedAlertKind.reminder,
        reminderMinutes: settings.reminderMinutes,
        adhanVoice: alert.voice,
      );
    }
    await _scheduleAnchoredReminders(prayerTimes);
    if (!android) return;
    final DateTime day = date.toLocal();
    await SakinaAlarms.setQuietWindows(
      day,
      planQuietWindows(
        times: prayerTimes,
        alerts: settings,
        after: after,
        now: now,
      ),
    );
    await SakinaAlarms.setFajrWake(
      day,
      wake
          ? FajrWakeAlarm(
              at: prayerTimes[DailyPrayer.fajr]!,
              sunrise: sunrise!,
              snoozeMinutes: after.snoozeMinutes,
              sound: settings.modeFor(DailyPrayer.fajr) == PrayerAlertMode.adhan
                  ? settings.voiceFor(DailyPrayer.fajr).resource
                  : null,
              texts: FajrWakeTexts(
                title: appL10n.fajrWakeTitle,
                body: appL10n.fajrWakeBody,
                stop: appL10n.fajrWakeStop,
                snooze: appL10n.fajrWakeSnooze(
                  applyDigitStyle('${after.snoozeMinutes}', digits),
                ),
                untilSunrise: appL10n.fajrWakeUntilSunrise,
                sunriseReached: appL10n.fajrWakeSunriseReached,
                channelName: appL10n.fajrWakeChannel,
                arabicDigits: digits == DigitStyle.arabic,
              ),
            )
          : null,
    );
  }

  /// Morning/evening adhkar reminders set to follow Fajr/Asr (see
  /// [AnchoredReminders]); only reminders still ahead are scheduled.
  Future<void> _scheduleAnchoredReminders(
    Map<DailyPrayer, DateTime> prayerTimes,
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    for (final AnchoredReminder r in AnchoredReminders.plan(
      prayerTimes: prayerTimes,
      prefs: prefs,
      now: DateTime.now(),
    )) {
      final bool morning = r.kind == AnchoredReminderKind.morning;
      await _core.scheduleOneTimeNotification(
        id: r.id,
        title: morning
            ? appL10n.notificationServiceMessage19
            : appL10n.notificationServiceMessage21,
        body: morning
            ? appL10n.notificationServiceMessage20
            : appL10n.notificationServiceMessage22,
        scheduledAt: r.at,
        payload: morning ? 'morning_adhkar' : 'evening_adhkar',
        kind: SakinaNotificationKind.adhkar,
      );
    }
  }

  /// Shows a prayer alert in 10 seconds so the user can check it works on
  /// this device, using the alert type chosen for Fajr.
  Future<void> scheduleTestPrayerAlert(AdhanSettings settings) async {
    final mode = settings.modeFor(DailyPrayer.fajr);
    await schedulePrayerNotification(
      id: _testPrayerAlertId,
      prayerName: appL10n.prayerName(DailyPrayer.fajr),
      prayerTime: DateTime.now().add(const Duration(seconds: 10)),
      mode: mode == PrayerAlertMode.silent ? PrayerAlertMode.sound : mode,
      adhanVoice: settings.voiceFor(DailyPrayer.fajr),
    );
  }

  static const int _testPrayerAlertId = 2999;

  /// Cancel all prayer time notifications.
  Future<void> cancelAllPrayerNotifications() async {
    await _core.initialize(requestPermissions: false);
    if (!_core.isPluginAvailable) return;

    for (final int id in allPrayerNotificationIds()) {
      await _core.flutterLocalNotificationsPlugin.cancel(id: id);
    }
    for (final int id in AnchoredReminders.allIds()) {
      await _core.flutterLocalNotificationsPlugin.cancel(id: id);
    }
    await _core.flutterLocalNotificationsPlugin.cancel(
      id: prayerWindowEndingNotificationId,
    );
    await SakinaAlarms.clearAll();

    developer.log(
      'Cancelled all prayer notifications',
      name: 'sakina_app.notifications',
    );
  }

  /// iOS: the notice on the last scheduled day that prayer alerts need the
  /// app opened to continue. Each schedule moves it to the new last day.
  static const int prayerWindowEndingNotificationId = 1206;

  /// When the window-ending notice for [lastDay] is shown: noon that day,
  /// before the day's later prayers and well before alerts run out.
  @visibleForTesting
  static DateTime prayerWindowEndingAt(DateTime lastDay) =>
      DateTime(lastDay.year, lastDay.month, lastDay.day, 12);

  Future<void> schedulePrayerWindowEndingNotice(DateTime lastDay) =>
      _core.scheduleOneTimeNotification(
        id: prayerWindowEndingNotificationId,
        title: appL10n.prayerWindowEndingTitle,
        body: appL10n.prayerWindowEndingBody,
        scheduledAt: prayerWindowEndingAt(lastDay),
        payload: 'prayer_time',
        payloadData: const {'reminder': true},
      );
}
