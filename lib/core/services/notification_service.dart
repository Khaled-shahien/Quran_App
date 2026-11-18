import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../accessibility/digit_style.dart';
import 'daily_reminder_notifications.dart';
import 'notification_channels.dart';
import 'notification_content.dart';
import 'notification_style.dart';
import 'notification_tap_routing.dart';
import 'notification_timing.dart';
import 'prayer_alert_notifications.dart';
import '../../features/prayers/domain/adhan_voices.dart';

/// Notification Service for managing alarms and notifications.
///
/// The core owns the plugin: initialization, channels, permissions and the
/// scheduling primitives. What is scheduled lives beside it:
/// [DailyReminderNotifications] ([reminders]) and [PrayerAlertNotifications]
/// ([prayers]); wording in [NotificationContent], tap handling in
/// [NotificationTapRouting], clock rules in [NotificationTiming].
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Daily clock-time reminders.
  late final DailyReminderNotifications reminders = DailyReminderNotifications(
    this,
  );

  /// Prayer alerts and the reminders tied to them.
  late final PrayerAlertNotifications prayers = PrayerAlertNotifications(this);

  /// An id for a notification sent from the debug test screen. Kept in
  /// 90000–99999, above every id the app schedules (1001–4007), so a test
  /// can never replace a real reminder.
  static int debugNotificationId(DateTime now) =>
      90000 + now.millisecondsSinceEpoch.remainder(10000);

  /// Same key as NotificationPermissionService.requestedKey.
  static const String _permissionRequestedKey =
      'notification_permission_requested';

  bool _isInitialized = false;
  bool _isPluginAvailable = true;

  Future<void>? _initFuture;
  bool _launchNotificationHandled = false;

  bool get isPluginAvailable => _isPluginAvailable;

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
      // Buttons on iOS belong to categories registered here.
      final DarwinInitializationSettings iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: darwinNotificationCategories(),
      );

      final InitializationSettings initializationSettings =
          InitializationSettings(android: androidInit, iOS: iosInit);

      await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
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

  Future<void> _configureLocalTimezone() =>
      NotificationTiming.applyDeviceTimezone();

  /// Called on resume: after travel or a manual change in system settings
  /// the device zone can differ from the one this process started with.
  /// When it does, `tz.local` follows and the next [updateAllAlarms] runs
  /// in full, so daily reminders move to the new local wall time.
  Future<bool> refreshTimezoneIfChanged() async {
    await initialize(requestPermissions: false);
    final bool changed = await NotificationTiming.applyDeviceTimezone();
    if (changed) reminders.invalidate();
    return changed;
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
    // Channels of removed recordings would point at a sound that no longer
    // exists. Deleting a channel that was never created is a no-op.
    for (final id in AdhanVoices.retiredChannelIds) {
      await androidImplementation.deleteNotificationChannel(channelId: id);
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
    // Lets the permission state tell "never asked" from "refused"
    // (NotificationPermissionService.requestedKey).
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_permissionRequestedKey, true);
    } catch (_) {
      // The request itself does not depend on this record.
    }

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

  /// Exact when allowed, otherwise inexact (see
  /// [NotificationTiming.scheduleModeFor]).
  Future<AndroidScheduleMode> androidScheduleMode() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (androidImplementation == null) {
      return NotificationTiming.scheduleModeFor(canScheduleExact: null);
    }
    try {
      return NotificationTiming.scheduleModeFor(
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
      return NotificationTiming.scheduleModeFor(canScheduleExact: false);
    }
  }

  /// Handle notification tap.
  void _onNotificationTapped(NotificationResponse response) {
    NotificationTapRouting.routeNotificationResponse(
      id: response.id,
      actionId: response.actionId,
      payload: response.payload,
    );
  }

  /// Routes the notification that launched a terminated app, once per process.
  /// `onDidReceiveNotificationResponse` does not report this tap.
  Future<void> deliverLaunchNotification() async {
    if (_launchNotificationHandled) return;
    await initialize(requestPermissions: false);
    if (!_isPluginAvailable) return;
    _launchNotificationHandled = true;
    NotificationTapRouting.routeLaunchDetails(
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails(),
    );
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

    final NotificationDetails notificationDetails = buildNotificationDetails(
      SakinaNotificationKind.general,
      title: title,
      body: body,
    );

    final String resolvedType = (payload == null || payload.isEmpty)
        ? 'general'
        : payload;
    final String serializedPayload = jsonEncode({
      'type': resolvedType,
      'data': payloadData ?? <String, dynamic>{},
    });

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
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
        NotificationContent.dailyReminderContent(
          title: title,
          body: body,
          payload: payload,
        );

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final tz.TZDateTime scheduledDate = NotificationTiming.nextDailyOccurrence(
      now,
      hour,
      minute,
    );
    final tz.TZDateTime twoMinutesFromNow = now.add(const Duration(minutes: 2));

    final String formattedTime = NotificationTiming.formatHHmm(hour, minute);
    final String triggerTime = NotificationTiming.formatHHmm(
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

    final NotificationDetails notificationDetails = buildNotificationDetails(
      NotificationContent.dailyReminderKind(payload),
      title: localizedContent.title,
      body: localizedContent.body,
    );

    final String resolvedType = (payload == null || payload.isEmpty)
        ? 'general'
        : payload;
    final String serializedPayload = jsonEncode({
      'type': resolvedType,
      'data': payloadData ?? <String, dynamic>{},
    });

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: localizedContent.title,
      body: localizedContent.body,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: await androidScheduleMode(),
      payload: serializedPayload,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    developer.log(
      'Daily notification $id scheduled for $formattedTime',
      name: 'sakina_app.notifications',
    );
  }

  /// Schedule a one-time notification at a fixed DateTime.
  Future<void> scheduleOneTimeNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? payload,
    Map<String, dynamic>? payloadData,
    SakinaNotificationKind kind = SakinaNotificationKind.test,
  }) async {
    await initialize(requestPermissions: false);
    if (!_isPluginAvailable) return;

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduleAtLocal = tz.TZDateTime.from(scheduledAt, tz.local);

    if (scheduleAtLocal.isBefore(now.add(const Duration(seconds: 5)))) {
      scheduleAtLocal = now.add(const Duration(seconds: 5));
    }

    final NotificationDetails notificationDetails = buildNotificationDetails(
      kind,
      title: title,
      body: body,
    );

    final String resolvedType = (payload == null || payload.isEmpty)
        ? 'general'
        : payload;
    final String serializedPayload = jsonEncode({
      'type': resolvedType,
      'data': payloadData ?? <String, dynamic>{},
    });

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduleAtLocal,
      notificationDetails: notificationDetails,
      androidScheduleMode: await androidScheduleMode(),
      payload: serializedPayload,
    );

    developer.log(
      'One-time notification $id scheduled for $scheduleAtLocal',
      name: 'sakina_app.notifications',
    );
  }

  /// The user's digit style for times shown in notifications.
  Future<DigitStyle> digitStyle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return digitStyleFromName(prefs.get(digitStylePreferenceKey));
    } catch (_) {
      return DigitStyle.western;
    }
  }

  /// Cancel a scheduled notification.
  Future<void> cancelNotification(int id) async {
    await initialize(requestPermissions: false);
    if (!_isPluginAvailable) return;

    await flutterLocalNotificationsPlugin.cancel(id: id);
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

    final NotificationDetails notificationDetails = buildNotificationDetails(
      SakinaNotificationKind.test,
      title: title,
      body: body,
    );

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
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
