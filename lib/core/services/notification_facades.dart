import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_service.dart';

/// Abstraction for local notification operations used by providers.
abstract class LocalNotificationGateway {
  /// Initializes local notifications and optionally requests permissions.
  Future<void> initialize({bool requestPermissions = false});

  /// Requests platform notification permissions from the user.
  Future<void> requestPermissions();

  /// Triggers a foreground test notification for diagnostics.
  Future<void> testNotification({
    required int id,
    required String title,
    required String body,
  });

  /// Schedules a one-time notification at [scheduledAt].
  Future<void> scheduleOneTimeNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? payload,
  });

  /// Cancels a specific pending notification by id.
  Future<void> cancelNotification(int id);

  /// Cancels all scheduled and shown notifications.
  Future<void> cancelAllNotifications();

  /// Returns currently pending notifications from the platform plugin.
  Future<List<PendingNotificationRequest>> getPendingNotifications();

  /// Rebuilds alarm schedules based on current feature toggles.
  Future<void> updateAllAlarms({
    required bool isMorningEnabled,
    required bool isEveningEnabled,
    required bool isMulkEnabled,
    required bool isBaqarahEnabled,
  });
}

/// Adapter that forwards [LocalNotificationGateway] calls to [NotificationService].
class NotificationServiceGateway implements LocalNotificationGateway {
  final NotificationService _notificationService;

  NotificationServiceGateway({NotificationService? notificationService})
    : _notificationService = notificationService ?? NotificationService();

  @override
  Future<void> cancelAllNotifications() {
    return _notificationService.cancelAllNotifications();
  }

  @override
  Future<void> cancelNotification(int id) {
    return _notificationService.cancelNotification(id);
  }

  @override
  Future<List<PendingNotificationRequest>> getPendingNotifications() {
    return _notificationService.getPendingNotifications();
  }

  @override
  Future<void> initialize({bool requestPermissions = false}) {
    return _notificationService.initialize(
      requestPermissions: requestPermissions,
    );
  }

  @override
  Future<void> requestPermissions() {
    return _notificationService.requestPermissions();
  }

  @override
  Future<void> scheduleOneTimeNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? payload,
  }) {
    return _notificationService.scheduleOneTimeNotification(
      id: id,
      title: title,
      body: body,
      scheduledAt: scheduledAt,
      payload: payload,
    );
  }

  @override
  Future<void> testNotification({
    required int id,
    required String title,
    required String body,
  }) {
    return _notificationService.testNotification(
      id: id,
      title: title,
      body: body,
    );
  }

  @override
  Future<void> updateAllAlarms({
    required bool isMorningEnabled,
    required bool isEveningEnabled,
    required bool isMulkEnabled,
    required bool isBaqarahEnabled,
  }) {
    return _notificationService.updateAllAlarms(
      isMorningEnabled: isMorningEnabled,
      isEveningEnabled: isEveningEnabled,
      isMulkEnabled: isMulkEnabled,
      isBaqarahEnabled: isBaqarahEnabled,
    );
  }
}
