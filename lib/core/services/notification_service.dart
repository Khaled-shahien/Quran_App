import 'package:sakina_app/l10n/localization.dart';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../navigation/notification_router.dart';

/// Notification Service for managing alarms and notifications.
///
/// This service handles:
/// - Morning Adhkar alarm (7:00 AM)
/// - Evening Adhkar alarm (5:30 PM)
/// - Surah Al-Mulk alarm (9:00 PM)
/// - Surah Al-Baqarah alarm (8:30 PM)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Notification IDs
  static const int _morningAdhkarNotificationId = 1001;
  static const int _eveningAdhkarNotificationId = 1002;
  static const int _mulkNotificationId = 1003;
  static const int _baqarahNotificationId = 1004;
  static const int _fajrPrayerNotificationId = 2001;
  static const int _dhuhrPrayerNotificationId = 2002;
  static const int _asrPrayerNotificationId = 2003;
  static const int _maghribPrayerNotificationId = 2004;
  static const int _ishaPrayerNotificationId = 2005;
  static const List<int> _managedNotificationIds = <int>[
    _morningAdhkarNotificationId,
    _eveningAdhkarNotificationId,
    _mulkNotificationId,
    _baqarahNotificationId,
  ];
  static const Map<String, int> _prayerNotificationIdsByName = <String, int>{
    'الفجر': _fajrPrayerNotificationId,
    'الظهر': _dhuhrPrayerNotificationId,
    'العصر': _asrPrayerNotificationId,
    'المغرب': _maghribPrayerNotificationId,
    'العشاء': _ishaPrayerNotificationId,
  };

  static const String _defaultChannelId = 'sakina_app_channel';
  static final String _defaultChannelName = appL10n.notificationServiceMessage1;
  static final String _defaultChannelDescription =
      appL10n.notificationServiceMessage2;

  static const String _alarmsChannelId = 'sakina_alarms_channel';
  static final String _alarmsChannelName = appL10n.notificationServiceMessage3;
  static final String _alarmsChannelDescription =
      appL10n.notificationServiceMessage4;

  static const String _prayerChannelId = 'prayer_times_default_sound_v2';
  static final String _prayerChannelName = appL10n.notificationServiceMessage5;
  static final String _prayerChannelDescription =
      appL10n.notificationServiceMessage6;

  static const String _testChannelId = 'test_channel';
  static final String _testChannelName = appL10n.notificationServiceMessage7;
  static final String _testChannelDescription =
      appL10n.notificationServiceMessage8;

  // Alarm time keys
  static const String _morningAlarmHourKey = 'morning_alarm_hour';
  static const String _morningAlarmMinuteKey = 'morning_alarm_minute';
  static const String _eveningAlarmHourKey = 'evening_alarm_hour';
  static const String _eveningAlarmMinuteKey = 'evening_alarm_minute';
  static const String _mulkAlarmHourKey = 'mulk_alarm_hour';
  static const String _mulkAlarmMinuteKey = 'mulk_alarm_minute';
  static const String _baqarahAlarmHourKey = 'baqarah_alarm_hour';
  static const String _baqarahAlarmMinuteKey = 'baqarah_alarm_minute';

  // Default times
  static const int _defaultMorningHour = 7;
  static const int _defaultMorningMinute = 0;
  static const int _defaultEveningHour = 17; // 5 PM
  static const int _defaultEveningMinute = 30;
  static const int _defaultMulkHour = 21; // 9 PM
  static const int _defaultMulkMinute = 0;
  static const int _defaultBaqarahHour = 20; // 8 PM
  static const int _defaultBaqarahMinute = 30;

  bool _isInitialized = false;
  bool _isPluginAvailable = true;
  String? _lastAppliedAlarmStateSignature;
  Future<void>? _initFuture;

  /// Initialize the notification service.
  Future<void> initialize({bool requestPermissions = false}) async {
    if (_isInitialized) {
      if (requestPermissions) await this.requestPermissions();
      return;
    }
    if (_initFuture != null) {
      await _initFuture;
      if (requestPermissions) {
        await this.requestPermissions();
      }
      return;
    }

    _initFuture = _doInitialize(requestPermissions);
    await _initFuture;
  }

  Future<void> _doInitialize(bool requestPermissions) async {
    try {
      tzdata.initializeTimeZones();
      await _configureLocalTimezone();

      const AndroidInitializationSettings androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(android: androidInit, iOS: iosInit);

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      await _createAndroidNotificationChannels();

      if (requestPermissions) {
        await this.requestPermissions();
      }

      _isPluginAvailable = true;
      developer.log(
        'Notification Service initialized successfully',
        name: 'sakina_app.notifications',
      );
    } catch (e) {
      _isPluginAvailable = false;
      developer.log(
        'Notification Service unavailable on this platform/context: $e',
        name: 'sakina_app.notifications',
        level: 1000,
        error: e,
      );
    } finally {
      _isInitialized = true;
      _initFuture = null;
    }
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final String timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (e) {
      // Fallback to Africa/Cairo as explicitly required for time-based calculations
      tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
      developer.log(
        'Failed to resolve local timezone, falling back to Africa/Cairo',
        name: 'sakina_app.notifications',
        level: 900,
        error: e,
      );
    }
    developer.log(
      'Notification timezone configured. Final selected timezone: ${tz.local.name}',
      name: 'sakina_app.notifications',
    );
  }

  Future<void> _createAndroidNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation == null) {
      return;
    }

    await androidImplementation.createNotificationChannel(
      AndroidNotificationChannel(
        _defaultChannelId,
        _defaultChannelName,
        description: _defaultChannelDescription,
        importance: Importance.high,
      ),
    );

    await androidImplementation.createNotificationChannel(
      AndroidNotificationChannel(
        _alarmsChannelId,
        _alarmsChannelName,
        description: _alarmsChannelDescription,
        importance: Importance.max,
      ),
    );

    await androidImplementation.createNotificationChannel(
      AndroidNotificationChannel(
        _prayerChannelId,
        _prayerChannelName,
        description: _prayerChannelDescription,
        importance: Importance.max,
        // Platform default sound until a licensed adhan is bundled.
        playSound: true,
        enableVibration: true,
      ),
    );

    await androidImplementation.createNotificationChannel(
      AndroidNotificationChannel(
        _testChannelId,
        _testChannelName,
        description: _testChannelDescription,
        importance: Importance.max,
      ),
    );

    developer.log(
      'Android notification channels ensured',
      name: 'sakina_app.notifications',
    );
  }

  /// Request runtime notification permissions.
  Future<void> requestPermissions() async {
    await initialize(requestPermissions: false);
    if (!_isPluginAvailable || kIsWeb) return;

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null &&
        defaultTargetPlatform == TargetPlatform.android) {
      final bool? granted = await androidImplementation
          .requestNotificationsPermission();
      developer.log(
        'Android notification permission granted: $granted',
        name: 'sakina_app.notifications',
      );

      try {
        final bool? exactAlarmPermission = await androidImplementation
            .requestExactAlarmsPermission();
        developer.log(
          'Android exact alarm permission granted: $exactAlarmPermission',
          name: 'sakina_app.notifications',
        );
      } catch (e) {
        developer.log(
          'Exact alarm permission request unavailable',
          name: 'sakina_app.notifications',
          level: 900,
          error: e,
        );
      }
    }

    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();

    if (iosImplementation != null &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Handle notification tap.
  void _onNotificationTapped(NotificationResponse response) {
    final String payload = response.payload ?? '';
    if (payload.isEmpty) {
      NotificationRouter.handleNotification(type: 'general');
      return;
    }

    try {
      final dynamic decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        final String type = decoded['type']?.toString() ?? 'general';
        final dynamic rawData = decoded['data'];
        final Map<String, dynamic> data = rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : <String, dynamic>{};
        NotificationRouter.handleNotification(type: type, data: data);
        return;
      }
    } catch (_) {
      // Plain string payloads are treated as a notification type.
    }

    NotificationRouter.handleNotification(type: payload);
  }

  /// Show a simple notification.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    Map<String, dynamic>? payloadData,
  }) async {
    await initialize(requestPermissions: false);
    if (!_isPluginAvailable) return;

    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          _defaultChannelId,
          _defaultChannelName,
          channelDescription: _defaultChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
        );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    final String resolvedType = (payload == null || payload.isEmpty)
        ? 'general'
        : payload;
    final String serializedPayload = jsonEncode({
      'type': resolvedType,
      'data': payloadData ?? <String, dynamic>{},
    });

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: serializedPayload,
    );
  }

  /// Schedule a daily notification at a specific time.
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
    Map<String, dynamic>? payloadData,
  }) async {
    await initialize(requestPermissions: false);
    if (!_isPluginAvailable) return;

    final ({String title, String body}) localizedContent =
        _resolveDailyNotificationContent(
          title: title,
          body: body,
          payload: payload,
        );

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    final tz.TZDateTime twoMinutesFromNow = now.add(const Duration(minutes: 2));

    if (scheduledDate.isBefore(twoMinutesFromNow)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final String formattedTime = _formatTimeHHmm(hour, minute);
    final String triggerTime = _formatTimeHHmm(
      scheduledDate.hour,
      scheduledDate.minute,
    );

    developer.log(
      'Scheduling notification $id for $formattedTime at $scheduledDate',
      name: 'sakina_app.notifications',
    );
    developer.log('Current time: $now', name: 'sakina_app.notifications');
    developer.log(
      'Two minutes from now: $twoMinutesFromNow',
      name: 'sakina_app.notifications',
    );
    developer.log(
      'Will trigger at: $triggerTime',
      name: 'sakina_app.notifications',
    );

    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          _alarmsChannelId,
          _alarmsChannelName,
          channelDescription: _alarmsChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
        );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    final String resolvedType = (payload == null || payload.isEmpty)
        ? 'general'
        : payload;
    final String serializedPayload = jsonEncode({
      'type': resolvedType,
      'data': payloadData ?? <String, dynamic>{},
    });

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      localizedContent.title,
      localizedContent.body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: serializedPayload,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    developer.log(
      'Daily notification $id scheduled for $formattedTime',
      name: 'sakina_app.notifications',
    );
  }

  ({String title, String body}) _resolveDailyNotificationContent({
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

  /// Schedule a one-time notification at a fixed DateTime.
  Future<void> scheduleOneTimeNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? payload,
    Map<String, dynamic>? payloadData,
  }) async {
    await initialize(requestPermissions: false);
    if (!_isPluginAvailable) return;

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduleAtLocal = tz.TZDateTime.from(scheduledAt, tz.local);

    if (scheduleAtLocal.isBefore(now.add(const Duration(seconds: 5)))) {
      scheduleAtLocal = now.add(const Duration(seconds: 5));
    }

    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          _testChannelId,
          _testChannelName,
          channelDescription: _testChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          playSound: true,
          enableVibration: true,
        );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    final String resolvedType = (payload == null || payload.isEmpty)
        ? 'general'
        : payload;
    final String serializedPayload = jsonEncode({
      'type': resolvedType,
      'data': payloadData ?? <String, dynamic>{},
    });

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduleAtLocal,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: serializedPayload,
    );

    developer.log(
      'One-time notification $id scheduled for $scheduleAtLocal',
      name: 'sakina_app.notifications',
    );
  }

  /// Schedule a one-time notification for a prayer time.
  Future<void> schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
  }) async {
    await initialize(requestPermissions: false);
    if (!_isPluginAvailable) return;

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

    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          _prayerChannelId,
          _prayerChannelName,
          channelDescription: _prayerChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          // Platform default sound until a licensed adhan is bundled.
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
        );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    final String serializedPayload = jsonEncode({
      'type': 'prayer_time',
      'data': <String, dynamic>{
        'prayerName': prayerName,
        'scheduledAt': prayerTime.toIso8601String(),
      },
    });

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      appL10n.notificationServiceMessage17((prayerName).toString()),
      appL10n.notificationServiceMessage18,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: serializedPayload,
    );

    developer.log(
      'Prayer notification $id scheduled for $prayerName at $scheduledDate',
      name: 'sakina_app.notifications',
    );
  }

  /// Schedule all prayer notifications for the provided day.
  Future<void> scheduleAllPrayersToday({
    required Map<String, DateTime> prayerTimes,
  }) async {
    await cancelAllPrayerNotifications();

    for (final MapEntry<String, DateTime> entry in prayerTimes.entries) {
      final int? id = _prayerNotificationIdsByName[entry.key];
      if (id == null) {
        developer.log(
          'Skipping unknown prayer notification key: ${entry.key}',
          name: 'sakina_app.notifications',
          level: 900,
        );
        continue;
      }

      await schedulePrayerNotification(
        id: id,
        prayerName: entry.key,
        prayerTime: entry.value,
      );
    }
  }

  String _formatTimeHHmm(int hour, int minute) {
    final String h = hour.toString().padLeft(2, '0');
    final String m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Cancel a scheduled notification.
  Future<void> cancelNotification(int id) async {
    await initialize(requestPermissions: false);
    if (!_isPluginAvailable) return;

    await flutterLocalNotificationsPlugin.cancel(id);
    developer.log(
      'Cancelled notification $id',
      name: 'sakina_app.notifications',
    );
  }

  /// Cancel all notifications.
  Future<void> cancelAllNotifications() async {
    await initialize(requestPermissions: false);
    if (!_isPluginAvailable) return;

    await flutterLocalNotificationsPlugin.cancelAll();
    developer.log(
      'Cancelled all notifications',
      name: 'sakina_app.notifications',
    );
  }

  /// Cancel all prayer time notifications.
  Future<void> cancelAllPrayerNotifications() async {
    await initialize(requestPermissions: false);
    if (!_isPluginAvailable) return;

    for (final int id in _prayerNotificationIdsByName.values) {
      await flutterLocalNotificationsPlugin.cancel(id);
    }

    developer.log(
      'Cancelled all prayer notifications',
      name: 'sakina_app.notifications',
    );
  }

  /// Cancel and reschedule only app-managed reminder notifications.
  Future<void> _cancelManagedReminderNotifications() async {
    for (final int id in _managedNotificationIds) {
      await cancelNotification(id);
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

    await scheduleDailyNotification(
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
    await cancelNotification(_morningAdhkarNotificationId);
  }

  // ==================== EVENING ADHKAR ALARM ====================

  /// Schedule evening adhkar alarm.
  Future<void> scheduleEveningAdhkarAlarm({int? hour, int? minute}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int h =
        hour ?? prefs.getInt(_eveningAlarmHourKey) ?? _defaultEveningHour;
    final int m =
        minute ?? prefs.getInt(_eveningAlarmMinuteKey) ?? _defaultEveningMinute;

    await scheduleDailyNotification(
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
    await cancelNotification(_eveningAdhkarNotificationId);
  }

  // ==================== SURAH AL-MULK ALARM ====================

  /// Schedule Surah Al-Mulk alarm.
  Future<void> scheduleMulkAlarm({int? hour, int? minute}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int h = hour ?? prefs.getInt(_mulkAlarmHourKey) ?? _defaultMulkHour;
    final int m =
        minute ?? prefs.getInt(_mulkAlarmMinuteKey) ?? _defaultMulkMinute;

    await scheduleDailyNotification(
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
    await cancelNotification(_mulkNotificationId);
  }

  // ==================== SURAH AL-BAQARAH ALARM ====================

  /// Schedule Surah Al-Baqarah alarm.
  Future<void> scheduleBaqarahAlarm({int? hour, int? minute}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int h =
        hour ?? prefs.getInt(_baqarahAlarmHourKey) ?? _defaultBaqarahHour;
    final int m =
        minute ?? prefs.getInt(_baqarahAlarmMinuteKey) ?? _defaultBaqarahMinute;

    await scheduleDailyNotification(
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
    await cancelNotification(_baqarahNotificationId);
  }

  // ==================== UPDATE ALL ALARMS ====================

  /// Update all active alarms based on settings.
  Future<void> updateAllAlarms({
    required bool isMorningEnabled,
    required bool isEveningEnabled,
    required bool isMulkEnabled,
    required bool isBaqarahEnabled,
  }) async {
    await initialize(requestPermissions: false);

    final String newSignature =
        '${isMorningEnabled ? 1 : 0}-'
        '${isEveningEnabled ? 1 : 0}-'
        '${isMulkEnabled ? 1 : 0}-'
        '${isBaqarahEnabled ? 1 : 0}';

    if (_lastAppliedAlarmStateSignature == newSignature) {
      developer.log(
        'Skipping alarm update: state unchanged',
        name: 'sakina_app.notifications',
      );
      return;
    }

    await _cancelManagedReminderNotifications();

    if (isMorningEnabled) {
      await scheduleMorningAdhkarAlarm();
    }
    if (isEveningEnabled) {
      await scheduleEveningAdhkarAlarm();
    }
    if (isMulkEnabled) {
      await scheduleMulkAlarm();
    }
    if (isBaqarahEnabled) {
      await scheduleBaqarahAlarm();
    }

    _lastAppliedAlarmStateSignature = newSignature;

    developer.log(
      'Updated all alarms. Morning: $isMorningEnabled, '
      'Evening: $isEveningEnabled, '
      'Mulk: $isMulkEnabled, Baqarah: $isBaqarahEnabled',
      name: 'sakina_app.notifications',
    );
  }

  /// Reschedule one alarm type without touching other notifications.
  Future<void> rescheduleSingleAlarm({
    required String type,
    required bool enabled,
    int? hour,
    int? minute,
  }) async {
    await initialize(requestPermissions: false);
    switch (type) {
      case 'morning':
        await cancelNotification(_morningAdhkarNotificationId);
        if (enabled) {
          await scheduleMorningAdhkarAlarm(hour: hour, minute: minute);
        }
        break;
      case 'evening':
        await cancelNotification(_eveningAdhkarNotificationId);
        if (enabled) {
          await scheduleEveningAdhkarAlarm(hour: hour, minute: minute);
        }
        break;
      case 'mulk':
        await cancelNotification(_mulkNotificationId);
        if (enabled) {
          await scheduleMulkAlarm(hour: hour, minute: minute);
        }
        break;
      case 'baqarah':
        await cancelNotification(_baqarahNotificationId);
        if (enabled) {
          await scheduleBaqarahAlarm(hour: hour, minute: minute);
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
    }

    developer.log(
      'Saved $type alarm time: ${_formatTimeHHmm(hour, minute)}',
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
    }

    return <String, int>{'hour': hour, 'minute': minute};
  }

  /// Test notification - shows immediate notification to verify system works.
  Future<void> testNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await initialize(requestPermissions: false);
    if (!_isPluginAvailable) return;

    developer.log(
      'TEST NOTIFICATION: $title',
      name: 'sakina_app.notifications',
    );
    developer.log('Body: $body', name: 'sakina_app.notifications');

    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          _testChannelId,
          _testChannelName,
          channelDescription: _testChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          playSound: true,
          enableVibration: true,
        );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: 'test',
    );

    developer.log(
      'Test notification shown successfully',
      name: 'sakina_app.notifications',
    );
  }

  /// Check pending notifications.
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    await initialize(requestPermissions: false);
    if (!_isPluginAvailable) return <PendingNotificationRequest>[];

    final List<PendingNotificationRequest> pending =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    developer.log(
      'Pending notifications: ${pending.length}',
      name: 'sakina_app.notifications',
    );
    for (final PendingNotificationRequest notification in pending) {
      developer.log(
        'ID: ${notification.id}, Title: ${notification.title}',
        name: 'sakina_app.notifications',
      );
    }

    return pending;
  }
}
