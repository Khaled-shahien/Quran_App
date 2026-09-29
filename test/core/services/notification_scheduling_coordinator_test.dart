import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/services/alarm_reschedule_task_service.dart';
import 'package:sakina_app/core/services/alarm_scheduler.dart';
import 'package:sakina_app/core/services/notification_scheduling_coordinator.dart';

class FakeAlarmScheduler implements AlarmScheduler {
  int initializeCalls = 0;
  int updateAllCalls = 0;
  final List<String> rescheduleTypes = <String>[];
  final List<Map<String, int>> savedTimes = <Map<String, int>>[];

  @override
  Future<void> initialize({bool requestPermissions = false}) async {
    initializeCalls += 1;
  }

  @override
  Future<void> updateAllAlarms({
    required bool isMorningEnabled,
    required bool isEveningEnabled,
    required bool isMulkEnabled,
    required bool isBaqarahEnabled,
  }) async {
    updateAllCalls += 1;
  }

  @override
  Future<void> saveAlarmTime({
    required String type,
    required int hour,
    required int minute,
  }) async {
    savedTimes.add({type: hour});
  }

  @override
  Future<void> rescheduleSingleAlarm({
    required String type,
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    rescheduleTypes.add(type);
  }

  @override
  Future<Map<String, int>> getAlarmTime(String type) async => {
    'hour': 7,
    'minute': 0,
  };
}

class FakeAlarmRescheduleTaskService implements AlarmRescheduleTaskService {
  final List<String> sources = <String>[];

  @override
  Future<void> registerImmediateRescheduleTask({
    String source = 'manual_settings_update',
  }) async {
    sources.add(source);
  }
}

void main() {
  group('NotificationSchedulingCoordinator', () {
    test('syncs alarm state through one scheduling boundary', () async {
      final scheduler = FakeAlarmScheduler();
      final rescheduleService = FakeAlarmRescheduleTaskService();
      final coordinator = NotificationSchedulingCoordinator(
        alarmScheduler: scheduler,
        rescheduleTaskService: rescheduleService,
      );

      await coordinator.syncFromSettings(
        isMorningEnabled: true,
        isEveningEnabled: false,
        isMulkEnabled: true,
        isBaqarahEnabled: false,
      );

      expect(scheduler.initializeCalls, 1);
      expect(scheduler.updateAllCalls, 1);
      expect(rescheduleService.sources, isEmpty);
    });

    test('requestReschedule delegates with the caller source', () async {
      final scheduler = FakeAlarmScheduler();
      final rescheduleService = FakeAlarmRescheduleTaskService();
      final coordinator = NotificationSchedulingCoordinator(
        alarmScheduler: scheduler,
        rescheduleTaskService: rescheduleService,
      );

      await coordinator.requestReschedule('toggle_morning');

      expect(rescheduleService.sources, ['toggle_morning']);
    });

    test(
      'setAlarmTime persists and reschedules through the same boundary',
      () async {
        final scheduler = FakeAlarmScheduler();
        final coordinator = NotificationSchedulingCoordinator(
          alarmScheduler: scheduler,
          rescheduleTaskService: FakeAlarmRescheduleTaskService(),
        );

        await coordinator.setAlarmTime(
          type: 'evening',
          enabled: true,
          hour: 18,
          minute: 15,
        );

        expect(scheduler.savedTimes, [
          <String, int>{'evening': 18},
        ]);
        expect(scheduler.rescheduleTypes, ['evening']);
      },
    );

    test('setAlarmTime rejects invalid clock values', () async {
      final scheduler = FakeAlarmScheduler();
      final coordinator = NotificationSchedulingCoordinator(
        alarmScheduler: scheduler,
        rescheduleTaskService: FakeAlarmRescheduleTaskService(),
      );

      expect(
        () => coordinator.setAlarmTime(
          type: 'morning',
          enabled: true,
          hour: 24,
          minute: 0,
        ),
        throwsArgumentError,
      );
      expect(scheduler.savedTimes, isEmpty);
      expect(scheduler.rescheduleTypes, isEmpty);
    });
  });
}
