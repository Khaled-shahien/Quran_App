import 'alarm_reschedule_task_service.dart';
import 'alarm_scheduler.dart';

/// Coordinates alarm scheduling state so settings updates and background
/// reschedules flow through a single boundary.
class NotificationSchedulingCoordinator {
  NotificationSchedulingCoordinator({
    AlarmScheduler? alarmScheduler,
    AlarmRescheduleTaskService? rescheduleTaskService,
  }) : _alarmScheduler = alarmScheduler ?? NotificationAlarmScheduler(),
       _rescheduleTaskService =
           rescheduleTaskService ?? WorkManagerAlarmRescheduleTaskService();

  final AlarmScheduler _alarmScheduler;
  final AlarmRescheduleTaskService _rescheduleTaskService;

  Future<void> syncFromSettings({
    required bool isMorningEnabled,
    required bool isEveningEnabled,
    required bool isMulkEnabled,
    required bool isBaqarahEnabled,
  }) async {
    await _alarmScheduler.initialize(requestPermissions: false);
    await _alarmScheduler.updateAllAlarms(
      isMorningEnabled: isMorningEnabled,
      isEveningEnabled: isEveningEnabled,
      isMulkEnabled: isMulkEnabled,
      isBaqarahEnabled: isBaqarahEnabled,
    );
  }

  Future<void> requestReschedule(String source) async {
    await _rescheduleTaskService.registerImmediateRescheduleTask(
      source: source,
    );
  }

  Future<void> setAlarmTime({
    required String type,
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw ArgumentError('Invalid alarm time');
    }

    await _alarmScheduler.saveAlarmTime(type: type, hour: hour, minute: minute);
    await _alarmScheduler.rescheduleSingleAlarm(
      type: type,
      enabled: enabled,
      hour: hour,
      minute: minute,
    );
  }

  Future<Map<String, int>> getAlarmTime(String type) {
    return _alarmScheduler.getAlarmTime(type);
  }
}
