import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/services/scheduling_generation.dart';
import 'package:sakina_app/core/services/workmanager_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The WorkManager background path: throttle, manual bypass, retry on
/// failure, and yielding to the app (audit TEST-01, task P6-01).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  timeChangeTests();
  platformTests();

  final at = DateTime.utc(2026, 1, 10, 9);
  late SharedPreferences prefs;
  late List<String> calls;
  late int? replenishGeneration;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    calls = [];
    replenishGeneration = null;
  });

  Future<void> run({
    Map<String, dynamic>? inputData,
    Future<void> Function(SharedPreferences)? updateReminders,
    Future<void> Function(SharedPreferences, int)? replenishPrayers,
    DateTime? now,
  }) => handleRescheduleAlarms(
    inputData: inputData,
    preferences: () async => prefs,
    updateReminders: updateReminders ?? (_) async => calls.add('reminders'),
    replenishPrayers:
        replenishPrayers ??
        (_, generation) async {
          calls.add('prayers');
          replenishGeneration = generation;
        },
    now: () => now ?? at,
  );

  test('reschedules reminders, then prayers, and records success', () async {
    await SchedulingGeneration.bump(prefs);
    await run();
    expect(calls, ['reminders', 'prayers']);
    expect(replenishGeneration, 1, reason: 'the generation it started from');
    expect(
      prefs.getInt(kLastBackgroundRescheduleAtMsKey),
      at.millisecondsSinceEpoch,
    );
  });

  test('a second run within 45 seconds is skipped', () async {
    await run();
    calls.clear();
    await run(now: at.add(const Duration(seconds: 30)));
    expect(calls, isEmpty);
    await run(now: at.add(const Duration(seconds: 46)));
    expect(calls, ['reminders', 'prayers']);
  });

  test('a manual settings update is never throttled', () async {
    await run();
    calls.clear();
    await run(
      inputData: {'source': 'manual_settings_update'},
      now: at.add(const Duration(seconds: 5)),
    );
    expect(calls, ['reminders', 'prayers']);
  });

  test('a clock set back does not block the next run', () async {
    await run();
    calls.clear();
    await run(now: at.subtract(const Duration(hours: 1)));
    expect(calls, ['reminders', 'prayers']);
  });

  test('a failure is rethrown and leaves the run retryable', () async {
    await expectLater(
      run(replenishPrayers: (_, _) async => throw StateError('broken')),
      throwsStateError,
    );
    expect(prefs.getInt(kLastBackgroundRescheduleAtMsKey), isNull);
    // The retry a few seconds later is not throttled away.
    await run(now: at.add(const Duration(seconds: 5)));
    expect(calls, contains('prayers'));
  });

  test('the task runner reports failure so WorkManager retries', () async {
    expect(
      await runBackgroundTask(
        kRescheduleAlarmsTaskName,
        null,
        reschedule: ({inputData}) async => throw StateError('broken'),
      ),
      isFalse,
    );
  });

  test('the task runner accepts both the task and periodic names', () async {
    final seen = <String?>[];
    Future<void> reschedule({Map<String, dynamic>? inputData}) async =>
        seen.add(inputData?['source'] as String?);
    expect(
      await runBackgroundTask(kRescheduleAlarmsTaskName, {
        'source': 'boot',
      }, reschedule: reschedule),
      isTrue,
    );
    expect(
      await runBackgroundTask(kRescheduleAlarmsPeriodicUniqueName, {
        'source': 'periodic',
      }, reschedule: reschedule),
      isTrue,
    );
    expect(seen, ['boot', 'periodic']);
  });

  test('an unknown task succeeds without rescheduling', () async {
    var ran = false;
    expect(
      await runBackgroundTask(
        'something_else',
        null,
        reschedule: ({inputData}) async => ran = true,
      ),
      isTrue,
    );
    expect(ran, isFalse);
  });
}

void timeChangeTests() {
  test('a timezone or clock change is never throttled', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final at = DateTime.utc(2026, 1, 10, 9);
    var runs = 0;
    Future<void> run(String source, DateTime now) => handleRescheduleAlarms(
      inputData: {'source': source},
      preferences: () async => prefs,
      updateReminders: (_) async => runs++,
      replenishPrayers: (_, _) async {},
      now: () => now,
    );
    await run('boot_receiver', at);
    await run('time_change', at.add(const Duration(seconds: 10)));
    expect(runs, 2);
  });
}

void platformTests() {
  test('one-off tasks are not used on iOS', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(WorkManagerService.supportsOneOffTasks, isFalse);
  });

  test('one-off tasks are used on Android', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(WorkManagerService.supportsOneOffTasks, isTrue);
  });
}
