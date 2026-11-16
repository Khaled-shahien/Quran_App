import 'notification_service.dart';

/// Abstraction for alarm scheduling operations used by settings logic.
abstract class AlarmScheduler {
  Future<void> initialize({bool requestPermissions = false});

  Future<void> updateAllAlarms({
    required bool isMorningEnabled,
    required bool isEveningEnabled,
    required bool isMulkEnabled,
    required bool isBaqarahEnabled,
    required bool isDailyVerseEnabled,
  });

  Future<void> saveAlarmTime({
    required String type,
    required int hour,
    required int minute,
  });

  Future<void> rescheduleSingleAlarm({
    required String type,
    required bool enabled,
    required int hour,
    required int minute,
  });

  Future<Map<String, int>> getAlarmTime(String type);
}

class NotificationAlarmScheduler implements AlarmScheduler {
  final NotificationService _notificationService;

  NotificationAlarmScheduler({NotificationService? notificationService})
    : _notificationService = notificationService ?? NotificationService();

  @override
  Future<Map<String, int>> getAlarmTime(String type) {
    return _notificationService.getAlarmTime(type);
  }

  @override
  Future<void> initialize({bool requestPermissions = false}) {
    return _notificationService.initialize(
      requestPermissions: requestPermissions,
    );
  }

  @override
  Future<void> rescheduleSingleAlarm({
    required String type,
    required bool enabled,
    required int hour,
    required int minute,
  }) {
    return _notificationService.rescheduleSingleAlarm(
      type: type,
      enabled: enabled,
      hour: hour,
      minute: minute,
    );
  }

  @override
  Future<void> saveAlarmTime({
    required String type,
    required int hour,
    required int minute,
  }) {
    return _notificationService.saveAlarmTime(
      type: type,
      hour: hour,
      minute: minute,
    );
  }

  @override
  Future<void> updateAllAlarms({
    required bool isMorningEnabled,
    required bool isEveningEnabled,
    required bool isMulkEnabled,
    required bool isBaqarahEnabled,
    required bool isDailyVerseEnabled,
  }) {
    return _notificationService.updateAllAlarms(
      isMorningEnabled: isMorningEnabled,
      isEveningEnabled: isEveningEnabled,
      isMulkEnabled: isMulkEnabled,
      isBaqarahEnabled: isBaqarahEnabled,
      isDailyVerseEnabled: isDailyVerseEnabled,
    );
  }
}
