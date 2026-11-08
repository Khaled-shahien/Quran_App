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
import 'local_timezone_fallback.dart';
import 'notification_channels.dart';
import '../../features/prayers/domain/entities/adhan_settings.dart';
import '../../features/prayers/domain/prayer_notification_ids.dart';
import '../../features/prayers/domain/services/prayer_alert_planner.dart';

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
  bool _launchNotificationHandled = false;
  Future<void> _alarmUpdates = Future<void>.value();

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

    _initFuture = _doInitialize();
    await _initFuture;
    // Outside _doInitialize: requesting awaits initialization to finish.
    if (requestPermissions) await this.requestPermissions();
  }

  Future<void> _doInitialize() async {
    try {
      if (!tz.timeZoneDatabase.isInitialized) tzdata.initializeTimeZones();
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
      tz.setLocalLocation(
        fallbackLocationForOffset(DateTime.now().timeZoneOffset),
      );
      developer.log(
        'Failed to resolve local timezone, using current UTC offset',
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

    for (final channel in NotificationChannels.all()) {
      await androidImplementation.createNotificationChannel(channel);
    }

    developer.log(
      'Android notification channels ensured',
      name: 'sakina_app.notifications',
    );
  }

  /// Request runtime notification permissions. Returns false only when the
  /// platform reports that notifications were refused.
  Future<bool> requestPermissions() async {
    await initialize(requestPermissions: false);
    if (!_isPluginAvailable || kIsWeb) return true;

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
      // Exact alarms are requested separately, from a screen that first
      // explains why (see requestExactAlarmPermission).
      if (granted == false) return false;
    }

    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();

    if (iosImplementation != null &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      final bool? granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (granted == false) return false;
    }
    return true;
  }

  /// Whether prayer alerts can fire at the exact minute. Null when the
  /// platform has no such restriction (iOS, Android before 12).
  Future<bool?> canScheduleExactAlarms() async {
    await initialize(requestPermissions: false);
    if (!_isPluginAvailable ||
        defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    try {
      return await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.canScheduleExactNotifications();
    } catch (_) {
      return null;
    }
  }

  /// Opens the system "Alarms & reminders" page. Call only after explaining
  /// why to the user. Returns the new state when known.
  Future<bool?> requestExactAlarmPermission() async {
    await initialize(requestPermissions: false);
    if (!_isPluginAvailable ||
        defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    try {
      return await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestExactAlarmsPermission();
    } catch (error) {
      developer.log(
        'Exact alarm permission request unavailable',
        name: 'sakina_app.notifications',
        level: 900,
        error: error,
      );
      return null;
    }
  }

  /// Exact access can be denied or revoked. Scheduling exactly would then
  /// throw, so a slightly late reminder is the fallback to no reminder at all.
  @visibleForTesting
  static AndroidScheduleMode scheduleModeFor({
    required bool? canScheduleExact,
  }) => canScheduleExact == false
      ? AndroidScheduleMode.inexactAllowWhileIdle
      : AndroidScheduleMode.exactAllowWhileIdle;

  Future<AndroidScheduleMode> _androidScheduleMode() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (androidImplementation == null) {
      return scheduleModeFor(canScheduleExact: null);
    }
    try {
      return scheduleModeFor(
        canScheduleExact: await androidImplementation
            .canScheduleExactNotifications(),
      );
    } catch (e) {
      developer.log(
        'Exact alarm access check failed',
        name: 'sakina_app.notifications',
        level: 900,
        error: e,
      );
      return scheduleModeFor(canScheduleExact: false);
    }
  }

  /// The next wall-clock [hour]:[minute] at least two minutes after [now].
  /// Calendar arithmetic keeps the time correct across a daylight-saving
  /// change, which adding 24 hours would shift by an hour.
  @visibleForTesting
  static tz.TZDateTime nextDailyOccurrence(
    tz.TZDateTime now,
    int hour,
    int minute,
  ) {
    final tz.TZDateTime today = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!today.isBefore(now.add(const Duration(minutes: 2)))) return today;
    return tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + 1,
      hour,
      minute,
    );
  }

  /// Handle notification tap.
  void _onNotificationTapped(NotificationResponse response) {
    routeNotificationPayload(response.payload);
  }

  /// Routes the notification that launched a terminated app, once per process.
  /// `onDidReceiveNotificationResponse` does not report this tap.
  Future<void> deliverLaunchNotification() async {
    if (_launchNotificationHandled) return;
    await initialize(requestPermissions: false);
    if (!_isPluginAvailable) return;
    _launchNotificationHandled = true;
    routeLaunchDetails(
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails(),
    );
  }

  @visibleForTesting
  static void routeLaunchDetails(NotificationAppLaunchDetails? details) {
    if (details == null || !details.didNotificationLaunchApp) return;
    routeNotificationPayload(details.notificationResponse?.payload);
  }

  @visibleForTesting
  static void routeNotificationPayload(String? rawPayload) {
    final String payload = rawPayload ?? '';
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
          NotificationChannels.defaultId,
          NotificationChannels.defaultName,
          channelDescription: NotificationChannels.defaultDescription,
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
    final tz.TZDateTime scheduledDate = nextDailyOccurrence(now, hour, minute);
    final tz.TZDateTime twoMinutesFromNow = now.add(const Duration(minutes: 2));

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
          NotificationChannels.alarmsId,
          NotificationChannels.alarmsName,
          channelDescription: NotificationChannels.alarmsDescription,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          playSound: true,
          enableVibration: true,
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
      androidScheduleMode: await _androidScheduleMode(),
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
          NotificationChannels.testId,
          NotificationChannels.testName,
          channelDescription: NotificationChannels.testDescription,
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
      androidScheduleMode: await _androidScheduleMode(),
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
  ///
  /// [mode] picks the channel: the alert sound (also used for "adhan" until
  /// licensed recordings are bundled) or a silent notification.
  Future<void> schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
    PrayerAlertMode mode = PrayerAlertMode.sound,
    bool isReminder = false,
    int reminderMinutes = 0,
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

    final bool withSound = mode != PrayerAlertMode.notificationOnly;
    final AndroidNotificationDetails androidNotificationDetails = isReminder
        ? AndroidNotificationDetails(
            NotificationChannels.prayerReminderId,
            appL10n.prayerReminderChannel,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
          )
        : withSound
        ? AndroidNotificationDetails(
            NotificationChannels.prayerId,
            NotificationChannels.prayerName,
            channelDescription: NotificationChannels.prayerDescription,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
            // Platform default sound until a licensed adhan is bundled.
            playSound: true,
            enableVibration: true,
            category: AndroidNotificationCategory.alarm,
          )
        : AndroidNotificationDetails(
            NotificationChannels.prayerSilentId,
            appL10n.prayerSilentChannel,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
            playSound: false,
            enableVibration: true,
            category: AndroidNotificationCategory.reminder,
          );

    final DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: withSound,
          interruptionLevel: isReminder
              ? InterruptionLevel.active
              : InterruptionLevel.timeSensitive,
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
      isReminder
          ? appL10n.prayerReminderBody('$reminderMinutes', prayerName)
          : appL10n.notificationServiceMessage17((prayerName).toString()),
      isReminder ? null : appL10n.prayerNotificationBody,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: await _androidScheduleMode(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: serializedPayload,
    );

    developer.log(
      'Prayer notification $id scheduled for $prayerName at $scheduledDate',
      name: 'sakina_app.notifications',
    );
  }

  /// Replace only the supplied calendar day's slot, preserving other days.
  Future<void> scheduleAllPrayersForDate({
    required Map<String, DateTime> prayerTimes,
    AdhanSettings settings = const AdhanSettings(),
  }) async {
    if (prayerTimes.isEmpty) return;
    final date = prayerTimes.values.first;
    for (final legacyId in _prayerNotificationIdsByName.values) {
      await cancelNotification(legacyId);
      await cancelNotification(prayerNotificationId(legacyId, date));
      await cancelNotification(prayerReminderNotificationId(legacyId, date));
    }

    final times = <DailyPrayer, DateTime>{};
    final names = <DailyPrayer, String>{};
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
      final prayer = DailyPrayer.values[id - 2001];
      times[prayer] = entry.value;
      names[prayer] = entry.key;
    }

    for (final alert in planPrayerAlerts(
      times: times,
      names: names,
      settings: settings,
      now: DateTime.now(),
    )) {
      await schedulePrayerNotification(
        id: alert.id,
        prayerName: alert.prayerName,
        prayerTime: alert.at,
        mode: alert.mode,
        isReminder: alert.kind == PlannedAlertKind.reminder,
        reminderMinutes: settings.reminderMinutes,
      );
    }
  }

  /// Shows a prayer alert in 10 seconds so the user can check it works on
  /// this device, using the alert type chosen for Fajr.
  Future<void> scheduleTestPrayerAlert(AdhanSettings settings) async {
    final mode = settings.modeFor(DailyPrayer.fajr);
    await schedulePrayerNotification(
      id: _testPrayerAlertId,
      prayerName: _prayerNotificationIdsByName.keys.first,
      prayerTime: DateTime.now().add(const Duration(seconds: 10)),
      mode: mode == PrayerAlertMode.silent ? PrayerAlertMode.sound : mode,
    );
  }

  static const int _testPrayerAlertId = 2999;

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

    for (final int id in allPrayerNotificationIds()) {
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

  /// Update all active alarms based on settings. Updates run one at a time so
  /// a quick second toggle cannot have its cancellation overtaken by the first.
  Future<void> updateAllAlarms({
    required bool isMorningEnabled,
    required bool isEveningEnabled,
    required bool isMulkEnabled,
    required bool isBaqarahEnabled,
  }) {
    final Future<void> update = _alarmUpdates.then(
      (_) => _applyAlarmState(
        isMorningEnabled: isMorningEnabled,
        isEveningEnabled: isEveningEnabled,
        isMulkEnabled: isMulkEnabled,
        isBaqarahEnabled: isBaqarahEnabled,
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
          NotificationChannels.testId,
          NotificationChannels.testName,
          channelDescription: NotificationChannels.testDescription,
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
