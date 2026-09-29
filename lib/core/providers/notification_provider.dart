import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_facades.dart';

/// Notification Provider for state management
///
/// Manages:
/// - Test notification controls
/// - Pending notifications list
class NotificationProvider extends ChangeNotifier {
  final SharedPreferences prefs;
  final LocalNotificationGateway _notificationGateway;

  bool _isInitialized = false;
  final bool _isLoading = false;
  List<Map<String, dynamic>> _pendingNotifications = [];
  final List<String> _debugLogs = [];

  NotificationProvider({
    required this.prefs,
    LocalNotificationGateway? notificationGateway,
  }) : _notificationGateway =
           notificationGateway ?? NotificationServiceGateway();

  /// Initialize notification services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications first (fast)
      await _notificationGateway.initialize(requestPermissions: false);

      _isInitialized = true;
      _addLog('Notification services initialized');
      notifyListeners();
    } catch (e) {
      _addLog('Error initializing: $e');
      // Don't rethrow - allow app to continue even if init fails
    }
  }

  /// Request notification permissions
  Future<void> requestPermissions() async {
    try {
      await _notificationGateway.requestPermissions();
      _addLog('Permissions requested');
    } catch (e) {
      _addLog('Error requesting permissions: $e');
    }
  }

  /// Schedule immediate test notification
  Future<void> scheduleTestNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await _notificationGateway.testNotification(
        id: id,
        title: title,
        body: body,
      );
      _addLog('Test notification shown: $title');
      notifyListeners();
    } catch (e) {
      _addLog('Error showing test notification: $e');
      rethrow;
    }
  }

  /// Schedule notification in 1 minute
  Future<void> scheduleDelayedNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      final DateTime scheduledTime = DateTime.now().add(
        const Duration(minutes: 1),
      );

      await _notificationGateway.scheduleOneTimeNotification(
        id: id,
        title: title,
        body: body,
        scheduledAt: scheduledTime,
        payload: 'test',
      );

      _addLog('Delayed notification scheduled for ${scheduledTime.toString()}');
      notifyListeners();
    } catch (e) {
      _addLog('Error scheduling delayed notification: $e');
      rethrow;
    }
  }

  /// Schedule test notification after exactly 5 minutes (for testing)
  Future<void> scheduleTestAlarmAfter5Minutes({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      final DateTime scheduledTime = DateTime.now().add(
        const Duration(minutes: 5),
      );

      await _notificationGateway.scheduleOneTimeNotification(
        id: id,
        title: title,
        body: body,
        scheduledAt: scheduledTime,
        payload: 'test',
      );

      _addLog(
        'Test alarm scheduled for ${scheduledTime.toString()} (in 5 minutes)',
      );
      notifyListeners();
    } catch (e) {
      _addLog('Error scheduling test alarm: $e');
      rethrow;
    }
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _notificationGateway.cancelNotification(id);
      _addLog('Notification cancelled: $id');
      notifyListeners();
    } catch (e) {
      _addLog('Error cancelling notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationGateway.cancelAllNotifications();
      _addLog('All notifications cancelled');
      notifyListeners();
    } catch (e) {
      _addLog('Error cancelling all notifications: $e');
    }
  }

  /// Get pending notifications
  Future<List<Map<String, dynamic>>> getPendingNotifications() async {
    try {
      final pending = await _notificationGateway.getPendingNotifications();
      _pendingNotifications = pending
          .whereType<PendingNotificationRequest>()
          .map(
            (p) => {
              'id': p.id,
              'title': p.title,
              'body': p.body,
              'payload': p.payload,
            },
          )
          .toList();

      _addLog('Pending notifications: ${_pendingNotifications.length}');
      notifyListeners();
      return _pendingNotifications;
    } catch (e) {
      _addLog('Error getting pending notifications: $e');
      return [];
    }
  }

  /// Reschedule all alarms
  Future<void> rescheduleAllAlarms() async {
    try {
      await _notificationGateway.updateAllAlarms(
        isMorningEnabled: prefs.getBool('morning_alarm_enabled') ?? true,
        isEveningEnabled: prefs.getBool('evening_alarm_enabled') ?? true,
        isMulkEnabled: prefs.getBool('mulk_alarm_enabled') ?? true,
        isBaqarahEnabled: prefs.getBool('baqarah_alarm_enabled') ?? true,
      );
      _addLog('All alarms rescheduled');
      notifyListeners();
    } catch (e) {
      _addLog('Error rescheduling alarms: $e');
    }
  }

  /// Add debug log
  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    _debugLogs.insert(0, '[$timestamp] $message');
    if (_debugLogs.length > 50) {
      _debugLogs.removeLast();
    }
    notifyListeners();
  }

  /// Clear debug logs
  void clearLogs() {
    _debugLogs.clear();
    notifyListeners();
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get pendingNotifications => _pendingNotifications;
  List<String> get debugLogs => _debugLogs;
}
