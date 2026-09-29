import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';
import '../../features/prayers/data/data_sources/prayer_times_api_service.dart';
import '../../features/prayers/data/repositories/prayer_times_repository_impl.dart';
import '../../features/prayers/data/services/local_prayer_notification_scheduler.dart';
import '../../features/prayers/data/services/prayer_replenishment_service.dart';

const String kRescheduleAlarmsTaskName = 'reschedule_alarms';
const String kRescheduleAlarmsPeriodicUniqueName =
    'reschedule_alarms_periodic_task';
const String kRescheduleAlarmsOneOffUniqueName = 'reschedule_alarms_boot_task';
const String _kLastBackgroundRescheduleAtMsKey =
    'last_background_reschedule_at_ms';
const int _kBackgroundRescheduleThrottleMs = 45 * 1000;

/// Background task callback - MUST be a top-level function
@pragma('vm:entry-point')
void callbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();

  Workmanager().executeTask((task, inputData) async {
    developer.log(
      'Background task executed: $task',
      name: 'sakina_app.workmanager',
    );

    try {
      switch (task) {
        case kRescheduleAlarmsTaskName:
          await _handleRescheduleAlarms(inputData: inputData);
          break;
        default:
          developer.log(
            'Unknown task: $task',
            name: 'sakina_app.workmanager',
            level: 900,
          );
      }

      return true;
    } catch (e) {
      developer.log(
        'Error in background task',
        name: 'sakina_app.workmanager',
        level: 1000,
        error: e,
      );
      return false;
    }
  });
}

/// Handle alarm rescheduling
Future<void> _handleRescheduleAlarms({Map<String, dynamic>? inputData}) async {
  developer.log(
    'Rescheduling alarms after boot/update',
    name: 'sakina_app.workmanager',
  );

  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int lastRunMs = prefs.getInt(_kLastBackgroundRescheduleAtMsKey) ?? 0;

    // WorkManager can enqueue multiple near-identical startup jobs.
    if (inputData?['source'] != 'manual_settings_update' &&
        nowMs >= lastRunMs &&
        nowMs - lastRunMs < _kBackgroundRescheduleThrottleMs) {
      developer.log(
        'Skipping duplicate background reschedule execution',
        name: 'sakina_app.workmanager',
      );
      return;
    }

    final NotificationService notificationService = NotificationService();
    await notificationService.initialize(requestPermissions: false);

    // Reschedule only the alarms enabled in persisted settings.
    await notificationService.updateAllAlarms(
      isMorningEnabled: prefs.getBool('morning_alarm_enabled') ?? false,
      isEveningEnabled: prefs.getBool('evening_alarm_enabled') ?? false,
      isMulkEnabled: prefs.getBool('mulk_alarm_enabled') ?? false,
      isBaqarahEnabled: prefs.getBool('baqarah_alarm_enabled') ?? false,
    );

    await PrayerReplenishmentService(
      preferences: prefs,
      repository: PrayerTimesRepositoryImpl(
        apiService: PrayerTimesApiService(),
        sharedPreferences: prefs,
      ),
      scheduler: LocalPrayerNotificationScheduler(prefs: prefs),
    ).replenish();
    // A failed fetch/schedule must remain retryable by WorkManager.
    await prefs.setInt(_kLastBackgroundRescheduleAtMsKey, nowMs);

    developer.log(
      'Alarms rescheduled successfully',
      name: 'sakina_app.workmanager',
    );
  } catch (e) {
    developer.log(
      'Error rescheduling alarms',
      name: 'sakina_app.workmanager',
      level: 1000,
      error: e,
    );
    rethrow;
  }
}

/// WorkManager Service for background tasks
///
/// Handles:
/// - Boot persistence (reschedule alarms after device restart)
/// - Periodic alarm checks
/// - App update handling
class WorkManagerService {
  static final WorkManagerService _instance = WorkManagerService._internal();
  factory WorkManagerService() => _instance;
  WorkManagerService._internal();

  final Workmanager _workmanager = Workmanager();
  bool _isInitialized = false;

  /// Initialize WorkManager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _workmanager.initialize(callbackDispatcher);

      developer.log(
        'WorkManager initialized successfully',
        name: 'sakina_app.workmanager',
      );
      _isInitialized = true;

      // Keep a periodic safety task registered across app runs/reboots.
      await registerRescheduleTask();
    } catch (e) {
      developer.log(
        'Error initializing WorkManager',
        name: 'sakina_app.workmanager',
        level: 1000,
        error: e,
      );
    }
  }

  /// Register boot reschedule task
  Future<void> registerRescheduleTask() async {
    try {
      final Constraints constraints = Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
      );

      // Register periodic task to reschedule alarms as a fallback safety net.
      await _workmanager.registerPeriodicTask(
        kRescheduleAlarmsPeriodicUniqueName,
        kRescheduleAlarmsTaskName,
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        frequency: const Duration(hours: 12),
        initialDelay: const Duration(minutes: 10),
        constraints: constraints,
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 10),
        inputData: {'source': 'periodic'},
      );

      developer.log(
        'Reschedule task registered',
        name: 'sakina_app.workmanager',
      );
    } catch (e) {
      developer.log(
        'Error registering reschedule task',
        name: 'sakina_app.workmanager',
        level: 1000,
        error: e,
      );
    }
  }

  /// Register immediate one-off reschedule task (used after boot/update).
  Future<void> registerBootRescheduleTask({
    String source = 'boot_or_update',
  }) async {
    try {
      final Constraints constraints = Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
      );

      await _workmanager.registerOneOffTask(
        kRescheduleAlarmsOneOffUniqueName,
        kRescheduleAlarmsTaskName,
        existingWorkPolicy: ExistingWorkPolicy.replace,
        initialDelay: const Duration(seconds: 20),
        constraints: constraints,
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 5),
        inputData: {'source': source},
      );
      developer.log(
        'Boot reschedule task registered',
        name: 'sakina_app.workmanager',
      );
    } catch (e) {
      developer.log(
        'Error registering boot reschedule task',
        name: 'sakina_app.workmanager',
        level: 1000,
        error: e,
      );
    }
  }

  /// Register immediate one-off reschedule after user settings changes.
  Future<void> registerImmediateRescheduleTask({
    String source = 'manual_settings_update',
  }) async {
    try {
      await _workmanager.registerOneOffTask(
        '${kRescheduleAlarmsOneOffUniqueName}_manual',
        kRescheduleAlarmsTaskName,
        existingWorkPolicy: ExistingWorkPolicy.replace,
        initialDelay: const Duration(seconds: 3),
        constraints: Constraints(networkType: NetworkType.notRequired),
        inputData: {'source': source},
      );
      developer.log(
        'Immediate reschedule task registered',
        name: 'sakina_app.workmanager',
      );
    } catch (e) {
      developer.log(
        'Error registering immediate reschedule task',
        name: 'sakina_app.workmanager',
        level: 1000,
        error: e,
      );
    }
  }

  /// Cancel reschedule task
  Future<void> cancelRescheduleTask() async {
    try {
      await _workmanager.cancelByUniqueName(
        kRescheduleAlarmsPeriodicUniqueName,
      );
      await _workmanager.cancelByUniqueName(kRescheduleAlarmsOneOffUniqueName);
      developer.log(
        'Reschedule task cancelled',
        name: 'sakina_app.workmanager',
      );
    } catch (e) {
      developer.log(
        'Error cancelling reschedule task',
        name: 'sakina_app.workmanager',
        level: 1000,
        error: e,
      );
    }
  }

  /// Cancel all WorkManager tasks
  Future<void> cancelAllTasks() async {
    try {
      await _workmanager.cancelAll();
      developer.log(
        'All WorkManager tasks cancelled',
        name: 'sakina_app.workmanager',
      );
    } catch (e) {
      developer.log(
        'Error cancelling all tasks',
        name: 'sakina_app.workmanager',
        level: 1000,
        error: e,
      );
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
