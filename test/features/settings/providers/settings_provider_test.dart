import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina_app/core/services/alarm_reschedule_task_service.dart';
import 'package:sakina_app/core/services/alarm_scheduler.dart';
import 'package:sakina_app/core/providers/settings_provider.dart';

class FakeAlarmScheduler implements AlarmScheduler {
  int initializeCalls = 0;
  int updateAllCalls = 0;
  int saveTimeCalls = 0;
  int rescheduleSingleCalls = 0;
  String? lastRescheduledType;

  @override
  Future<Map<String, int>> getAlarmTime(String type) async {
    return <String, int>{'hour': 7, 'minute': 0};
  }

  @override
  Future<void> initialize({bool requestPermissions = false}) async {
    initializeCalls++;
  }

  @override
  Future<void> rescheduleSingleAlarm({
    required String type,
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    rescheduleSingleCalls++;
    lastRescheduledType = type;
  }

  @override
  Future<void> saveAlarmTime({
    required String type,
    required int hour,
    required int minute,
  }) async {
    saveTimeCalls++;
  }

  @override
  Future<void> updateAllAlarms({
    required bool isMorningEnabled,
    required bool isEveningEnabled,
    required bool isMulkEnabled,
    required bool isBaqarahEnabled,
  }) async {
    updateAllCalls++;
  }
}

class FakeRescheduleTaskService implements AlarmRescheduleTaskService {
  int calls = 0;
  String? lastSource;

  @override
  Future<void> registerImmediateRescheduleTask({
    String source = 'manual_settings_update',
  }) async {
    calls++;
    lastSource = source;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> flushAsyncTasks() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  test('SettingsProvider persists morning alarm toggle', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fakeAlarmScheduler = FakeAlarmScheduler();
    final fakeRescheduleTaskService = FakeRescheduleTaskService();

    final provider = SettingsProvider(
      prefs: prefs,
      alarmScheduler: fakeAlarmScheduler,
      rescheduleTaskService: fakeRescheduleTaskService,
    );

    await flushAsyncTasks();

    await provider.toggleMorningAlarm(true);
    await flushAsyncTasks();

    expect(provider.isMorningAlarmEnabled, isTrue);
    expect(prefs.getBool('morning_alarm_enabled'), isTrue);
    expect(fakeAlarmScheduler.updateAllCalls, greaterThanOrEqualTo(1));
    expect(fakeRescheduleTaskService.calls, greaterThanOrEqualTo(1));
    expect(fakeRescheduleTaskService.lastSource, 'toggle_morning');
  });

  test(
    'SettingsProvider reschedules selected alarm when time changes',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fakeAlarmScheduler = FakeAlarmScheduler();
      final fakeRescheduleTaskService = FakeRescheduleTaskService();

      final provider = SettingsProvider(
        prefs: prefs,
        alarmScheduler: fakeAlarmScheduler,
        rescheduleTaskService: fakeRescheduleTaskService,
      );

      await provider.toggleEveningAlarm(true);
      await provider.setAlarmTime(type: 'evening', hour: 18, minute: 15);
      await flushAsyncTasks();

      expect(fakeAlarmScheduler.saveTimeCalls, 1);
      expect(fakeAlarmScheduler.rescheduleSingleCalls, 1);
      expect(fakeAlarmScheduler.lastRescheduledType, 'evening');
      expect(fakeRescheduleTaskService.lastSource, 'set_alarm_time_evening');
    },
  );

  test('SettingsProvider ignores malformed persisted alarm values', () async {
    SharedPreferences.setMockInitialValues({
      'morning_alarm_enabled': 'not-a-bool',
      'evening_alarm_enabled': 123,
      'mulk_alarm_enabled': true,
      'baqarah_alarm_enabled': 'false',
    });
    final prefs = await SharedPreferences.getInstance();

    final provider = SettingsProvider(
      prefs: prefs,
      alarmScheduler: FakeAlarmScheduler(),
      rescheduleTaskService: FakeRescheduleTaskService(),
    );

    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(provider.isMorningAlarmEnabled, isFalse);
    expect(provider.isEveningAlarmEnabled, isFalse);
    expect(provider.isMulkAlarmEnabled, isTrue);
    expect(provider.isBaqarahAlarmEnabled, isFalse);

    expect(prefs.getBool('morning_alarm_enabled'), isFalse);
    expect(prefs.getBool('evening_alarm_enabled'), isFalse);
    expect(prefs.getBool('mulk_alarm_enabled'), isTrue);
    expect(prefs.getBool('baqarah_alarm_enabled'), isFalse);
  });
}
