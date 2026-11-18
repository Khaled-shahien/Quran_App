import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../accessibility/digit_style.dart';
import 'anchored_reminders.dart';
import 'notification_content.dart';
import 'notification_service.dart';
import 'notification_style.dart';
import 'notification_timing.dart';
import '../../features/quran/data/daily_verse_source.dart';

/// Daily reminders at a clock time: morning and evening adhkar, Surah
/// al-Mulk, Surah al-Baqarah and the daily verse.
class DailyReminderNotifications {
  DailyReminderNotifications(this._core);

  final NotificationService _core;

  // Notification IDs
  static const int _morningAdhkarNotificationId = 1001;
  static const int _eveningAdhkarNotificationId = 1002;
  static const int _mulkNotificationId = 1003;
  static const int _baqarahNotificationId = 1004;
  static const List<int> _managedNotificationIds = <int>[
    _morningAdhkarNotificationId,
    _eveningAdhkarNotificationId,
    _mulkNotificationId,
    _baqarahNotificationId,
  ];

  /// The daily verse: one notification per day, a week ahead. A day uses
  /// slot 4000 + weekday, so seven consecutive days never share an id.
  @visibleForTesting
  static int dailyVerseNotificationId(DateTime date) => 4000 + date.weekday;

  static const int _dailyVerseDaysAhead = 7;

  // Alarm time keys
  static const String _morningAlarmHourKey = 'morning_alarm_hour';
  static const String _morningAlarmMinuteKey = 'morning_alarm_minute';
  static const String _eveningAlarmHourKey = 'evening_alarm_hour';
  static const String _eveningAlarmMinuteKey = 'evening_alarm_minute';
  static const String _mulkAlarmHourKey = 'mulk_alarm_hour';
  static const String _mulkAlarmMinuteKey = 'mulk_alarm_minute';
  static const String _baqarahAlarmHourKey = 'baqarah_alarm_hour';
  static const String _baqarahAlarmMinuteKey = 'baqarah_alarm_minute';
  static const String _verseAlarmHourKey = 'verse_alarm_hour';
  static const String _verseAlarmMinuteKey = 'verse_alarm_minute';

  // Default times
  static const int _defaultMorningHour = 7;
  static const int _defaultMorningMinute = 0;
  static const int _defaultEveningHour = 17; // 5 PM
  static const int _defaultEveningMinute = 30;
  static const int _defaultMulkHour = 21; // 9 PM
  static const int _defaultMulkMinute = 0;
  static const int _defaultBaqarahHour = 20; // 8 PM
  static const int _defaultBaqarahMinute = 30;
  static const int _defaultVerseHour = 9;
  static const int _defaultVerseMinute = 0;

  String? _lastAppliedAlarmStateSignature;
  Future<void> _alarmUpdates = Future<void>.value();

  /// Forces the next [updateAllAlarms] to run in full (after a time zone
  /// change the same settings mean new wall-clock instants).
  void invalidate() => _lastAppliedAlarmStateSignature = null;

  /// Cancel and reschedule only app-managed reminder notifications.
  Future<void> _cancelManagedReminderNotifications() async {
    for (final int id in _managedNotificationIds) {
      await _core.cancelNotification(id);
    }
  }

  // ==================== MORNING ADHKAR ALARM ====================

  /// Schedule morning adhkar alarm.
  Future<void> scheduleMorningAdhkarAlarm({int? hour, int? minute}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int h =
        hour ?? prefs.getInt(_morningAlarmHourKey) ?? _defaultMorningHour;
    final int m =
        minute ?? prefs.getInt(_morningAlarmMinuteKey) ?? _defaultMorningMinute;

    await _core.scheduleDailyNotification(
      id: _morningAdhkarNotificationId,
      title: appL10n.notificationServiceMessage19,
      body: appL10n.notificationServiceMessage20,
      hour: h,
      minute: m,
      payload: 'morning_adhkar',
    );
  }

  /// Cancel morning adhkar alarm.
  Future<void> cancelMorningAdhkarAlarm() async {
    await _core.cancelNotification(_morningAdhkarNotificationId);
  }

  // ==================== EVENING ADHKAR ALARM ====================

  /// Schedule evening adhkar alarm.
  Future<void> scheduleEveningAdhkarAlarm({int? hour, int? minute}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int h =
        hour ?? prefs.getInt(_eveningAlarmHourKey) ?? _defaultEveningHour;
    final int m =
        minute ?? prefs.getInt(_eveningAlarmMinuteKey) ?? _defaultEveningMinute;

    await _core.scheduleDailyNotification(
      id: _eveningAdhkarNotificationId,
      title: appL10n.notificationServiceMessage21,
      body: appL10n.notificationServiceMessage22,
      hour: h,
      minute: m,
      payload: 'evening_adhkar',
    );
  }

  /// Cancel evening adhkar alarm.
  Future<void> cancelEveningAdhkarAlarm() async {
    await _core.cancelNotification(_eveningAdhkarNotificationId);
  }

  // ==================== SURAH AL-MULK ALARM ====================

  /// Schedule Surah Al-Mulk alarm.
  Future<void> scheduleMulkAlarm({int? hour, int? minute}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int h = hour ?? prefs.getInt(_mulkAlarmHourKey) ?? _defaultMulkHour;
    final int m =
        minute ?? prefs.getInt(_mulkAlarmMinuteKey) ?? _defaultMulkMinute;

    await _core.scheduleDailyNotification(
      id: _mulkNotificationId,
      title: appL10n.notificationServiceMessage23,
      body: appL10n.notificationServiceMessage24,
      hour: h,
      minute: m,
      payload: 'mulk_surah',
    );
  }

  /// Cancel Surah Al-Mulk alarm.
  Future<void> cancelMulkAlarm() async {
    await _core.cancelNotification(_mulkNotificationId);
  }

  // ==================== SURAH AL-BAQARAH ALARM ====================

  /// Schedule Surah Al-Baqarah alarm.
  Future<void> scheduleBaqarahAlarm({int? hour, int? minute}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int h =
        hour ?? prefs.getInt(_baqarahAlarmHourKey) ?? _defaultBaqarahHour;
    final int m =
        minute ?? prefs.getInt(_baqarahAlarmMinuteKey) ?? _defaultBaqarahMinute;

    await _core.scheduleDailyNotification(
      id: _baqarahNotificationId,
      title: appL10n.notificationServiceMessage25,
      body: appL10n.notificationServiceMessage26,
      hour: h,
      minute: m,
      payload: 'baqarah_surah',
    );
  }

  /// Cancel Surah Al-Baqarah alarm.
  Future<void> cancelBaqarahAlarm() async {
    await _core.cancelNotification(_baqarahNotificationId);
  }

  // ==================== DAILY VERSE ====================

  /// Schedules the verse of each of the next seven days at the saved time.
  /// Rebuilt with the other reminders, so the week keeps rolling forward.
  Future<void> scheduleDailyVerseNotifications({
    int? hour,
    int? minute,
    DailyVerseSource? source,
  }) async {
    await _core.initialize(requestPermissions: false);
    if (!_core.isPluginAvailable) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int h = hour ?? prefs.getInt(_verseAlarmHourKey) ?? _defaultVerseHour;
    final int m =
        minute ?? prefs.getInt(_verseAlarmMinuteKey) ?? _defaultVerseMinute;
    await cancelDailyVerseNotifications();

    final DailyVerseSource verses = source ?? DailyVerseSource();
    final DigitStyle digits = await _core.digitStyle();
    final AndroidScheduleMode mode = await _core.androidScheduleMode();
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final tz.TZDateTime first = NotificationTiming.nextDailyOccurrence(
      now,
      h,
      m,
    );
    for (var day = 0; day < _dailyVerseDaysAhead; day++) {
      final tz.TZDateTime at = tz.TZDateTime(
        first.location,
        first.year,
        first.month,
        first.day + day,
        h,
        m,
      );
      final verse = await verses.verseFor(at);
      final content = NotificationContent.dailyVerseNotificationContent(
        verse,
        digits,
      );
      await _core.flutterLocalNotificationsPlugin.zonedSchedule(
        dailyVerseNotificationId(at),
        content.title,
        content.body,
        at,
        buildNotificationDetails(
          SakinaNotificationKind.dailyVerse,
          title: content.title,
          body: content.body,
          summary: content.summary,
        ),
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: jsonEncode({
          'type': 'daily_verse',
          'data': <String, dynamic>{
            'surahNumber': verse.surah,
            'ayahNumber': verse.ayah,
          },
        }),
      );
    }
    developer.log(
      'Daily verse scheduled for $_dailyVerseDaysAhead days from $first',
      name: 'sakina_app.notifications',
    );
  }

  Future<void> cancelDailyVerseNotifications() async {
    for (var weekday = 1; weekday <= 7; weekday++) {
      await _core.cancelNotification(4000 + weekday);
    }
  }

  // ==================== UPDATE ALL ALARMS ====================

  /// Update all active alarms based on settings. Updates run one at a time so
  /// a quick second toggle cannot have its cancellation overtaken by the first.
  Future<void> updateAllAlarms({
    required bool isMorningEnabled,
    required bool isEveningEnabled,
    required bool isMulkEnabled,
    required bool isBaqarahEnabled,
    required bool isDailyVerseEnabled,
  }) {
    final Future<void> update = _alarmUpdates.then(
      (_) => _applyAlarmState(
        isMorningEnabled: isMorningEnabled,
        isEveningEnabled: isEveningEnabled,
        isMulkEnabled: isMulkEnabled,
        isBaqarahEnabled: isBaqarahEnabled,
        isDailyVerseEnabled: isDailyVerseEnabled,
      ),
    );
    _alarmUpdates = update.catchError((Object _) {});
    return update;
  }

  Future<void> _applyAlarmState({
    required bool isMorningEnabled,
    required bool isEveningEnabled,
    required bool isMulkEnabled,
    required bool isBaqarahEnabled,
    required bool isDailyVerseEnabled,
  }) async {
    await _core.initialize(requestPermissions: false);

    // The verse window is a week of separate days, so a new day is a change.
    final DateTime today = DateTime.now();
    final SharedPreferences anchorPrefs = await SharedPreferences.getInstance();
    final int? morningAnchor = AnchoredReminders.morning(anchorPrefs);
    final int? eveningAnchor = AnchoredReminders.evening(anchorPrefs);
    final String newSignature =
        '${isMorningEnabled ? 1 : 0}${morningAnchor ?? '-'}-'
        '${isEveningEnabled ? 1 : 0}${eveningAnchor ?? '-'}-'
        '${isMulkEnabled ? 1 : 0}-'
        '${isBaqarahEnabled ? 1 : 0}-'
        '${isDailyVerseEnabled ? '${today.year}${today.month}${today.day}' : 0}';

    if (_lastAppliedAlarmStateSignature == newSignature) {
      developer.log(
        'Skipping alarm update: state unchanged',
        name: 'sakina_app.notifications',
      );
      return;
    }

    await _cancelManagedReminderNotifications();

    // An anchored reminder is scheduled with the prayer alerts instead.
    if (isMorningEnabled && morningAnchor == null) {
      await scheduleMorningAdhkarAlarm();
    }
    if (isEveningEnabled && eveningAnchor == null) {
      await scheduleEveningAdhkarAlarm();
    }
    if (isMulkEnabled) {
      await scheduleMulkAlarm();
    }
    if (isBaqarahEnabled) {
      await scheduleBaqarahAlarm();
    }
    if (isDailyVerseEnabled) {
      await _scheduleDailyVerseSafely();
    } else {
      await cancelDailyVerseNotifications();
    }

    _lastAppliedAlarmStateSignature = newSignature;

    developer.log(
      'Updated all alarms. Morning: $isMorningEnabled, '
      'Evening: $isEveningEnabled, '
      'Mulk: $isMulkEnabled, Baqarah: $isBaqarahEnabled, '
      'Verse: $isDailyVerseEnabled',
      name: 'sakina_app.notifications',
    );
  }

  /// A verse that cannot be read must not stop the other reminders.
  Future<void> _scheduleDailyVerseSafely({int? hour, int? minute}) async {
    try {
      await scheduleDailyVerseNotifications(hour: hour, minute: minute);
    } catch (error) {
      developer.log(
        'Daily verse scheduling failed',
        name: 'sakina_app.notifications',
        level: 1000,
        error: error,
      );
    }
  }

  /// Reschedule one alarm type without touching other notifications.
  Future<void> rescheduleSingleAlarm({
    required String type,
    required bool enabled,
    int? hour,
    int? minute,
  }) async {
    await _core.initialize(requestPermissions: false);
    switch (type) {
      case 'morning':
        await _core.cancelNotification(_morningAdhkarNotificationId);
        if (enabled) {
          await scheduleMorningAdhkarAlarm(hour: hour, minute: minute);
        }
        break;
      case 'evening':
        await _core.cancelNotification(_eveningAdhkarNotificationId);
        if (enabled) {
          await scheduleEveningAdhkarAlarm(hour: hour, minute: minute);
        }
        break;
      case 'mulk':
        await _core.cancelNotification(_mulkNotificationId);
        if (enabled) {
          await scheduleMulkAlarm(hour: hour, minute: minute);
        }
        break;
      case 'baqarah':
        await _core.cancelNotification(_baqarahNotificationId);
        if (enabled) {
          await scheduleBaqarahAlarm(hour: hour, minute: minute);
        }
        break;
      case 'verse':
        if (enabled) {
          await _scheduleDailyVerseSafely(hour: hour, minute: minute);
        } else {
          await cancelDailyVerseNotifications();
        }
        break;
      default:
        developer.log(
          'Unknown alarm type for reschedule: $type',
          name: 'sakina_app.notifications',
          level: 900,
        );
    }
  }

  /// Save alarm time to preferences.
  Future<void> saveAlarmTime({
    required String type,
    required int hour,
    required int minute,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    switch (type) {
      case 'morning':
        await prefs.setInt(_morningAlarmHourKey, hour);
        await prefs.setInt(_morningAlarmMinuteKey, minute);
        break;
      case 'evening':
        await prefs.setInt(_eveningAlarmHourKey, hour);
        await prefs.setInt(_eveningAlarmMinuteKey, minute);
        break;
      case 'mulk':
        await prefs.setInt(_mulkAlarmHourKey, hour);
        await prefs.setInt(_mulkAlarmMinuteKey, minute);
        break;
      case 'baqarah':
        await prefs.setInt(_baqarahAlarmHourKey, hour);
        await prefs.setInt(_baqarahAlarmMinuteKey, minute);
        break;
      case 'verse':
        await prefs.setInt(_verseAlarmHourKey, hour);
        await prefs.setInt(_verseAlarmMinuteKey, minute);
        break;
    }

    developer.log(
      'Saved $type alarm time: ${NotificationTiming.formatHHmm(hour, minute)}',
      name: 'sakina_app.notifications',
    );
  }

  /// Get saved alarm time.
  Future<Map<String, int>> getAlarmTime(String type) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    int hour = 0;
    int minute = 0;

    switch (type) {
      case 'morning':
        hour = prefs.getInt(_morningAlarmHourKey) ?? _defaultMorningHour;
        minute = prefs.getInt(_morningAlarmMinuteKey) ?? _defaultMorningMinute;
        break;
      case 'evening':
        hour = prefs.getInt(_eveningAlarmHourKey) ?? _defaultEveningHour;
        minute = prefs.getInt(_eveningAlarmMinuteKey) ?? _defaultEveningMinute;
        break;
      case 'mulk':
        hour = prefs.getInt(_mulkAlarmHourKey) ?? _defaultMulkHour;
        minute = prefs.getInt(_mulkAlarmMinuteKey) ?? _defaultMulkMinute;
        break;
      case 'baqarah':
        hour = prefs.getInt(_baqarahAlarmHourKey) ?? _defaultBaqarahHour;
        minute = prefs.getInt(_baqarahAlarmMinuteKey) ?? _defaultBaqarahMinute;
        break;
      case 'verse':
        hour = prefs.getInt(_verseAlarmHourKey) ?? _defaultVerseHour;
        minute = prefs.getInt(_verseAlarmMinuteKey) ?? _defaultVerseMinute;
        break;
    }

    return <String, int>{'hour': hour, 'minute': minute};
  }
}
