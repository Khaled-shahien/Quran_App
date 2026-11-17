import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'diagnostics_log.dart';
import 'notification_service.dart';
import 'scheduling_generation.dart';

import '../../features/prayers/data/repositories/prayer_times_repository_impl.dart';
import '../../features/prayers/data/services/local_prayer_notification_scheduler.dart';
import '../../features/prayers/data/services/prayer_replenishment_service.dart';

const String kRescheduleAlarmsTaskName = 'reschedule_alarms';
const String kRescheduleAlarmsPeriodicUniqueName =
    'reschedule_alarms_periodic_task';
const String kRescheduleAlarmsOneOffUniqueName = 'reschedule_alarms_boot_task';

/// When the last background reschedule finished successfully.
const String kLastBackgroundRescheduleAtMsKey =
    'last_background_reschedule_at_ms';
const int _kBackgroundRescheduleThrottleMs = 45 * 1000;
const Set<String> _unthrottledSources = {
  'manual_settings_update',
  'time_change',
};

/// Background task callback - MUST be a top-level function
@pragma('vm:entry-point')
void callbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();

  Workmanager().executeTask(
    (task, inputData) => runBackgroundTask(task, inputData),
  );
}

/// Runs one WorkManager task. Returns false on failure so WorkManager
/// retries it with backoff.
@visibleForTesting
Future<bool> runBackgroundTask(
  String task,
  Map<String, dynamic>? inputData, {
  Future<void> Function({Map<String, dynamic>? inputData})? reschedule,
}) async {
  developer.log(
    'Background task executed: $task',
    name: 'sakina_app.workmanager',
  );

  try {
    switch (task) {
      case kRescheduleAlarmsTaskName:
      // iOS reports periodic work by its unique name, not its task name.
      case kRescheduleAlarmsPeriodicUniqueName:
        await (reschedule ?? handleRescheduleAlarms)(inputData: inputData);
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
}

Future<void> _updateRemindersFromSettings(SharedPreferences prefs) async {
  final NotificationService notificationService = NotificationService();
  await notificationService.initialize(requestPermissions: false);
  // Reschedule only the alarms enabled in persisted settings.
  await notificationService.updateAllAlarms(
    isMorningEnabled: prefs.getBool('morning_alarm_enabled') ?? false,
    isEveningEnabled: prefs.getBool('evening_alarm_enabled') ?? false,
    isMulkEnabled: prefs.getBool('mulk_alarm_enabled') ?? false,
    isBaqarahEnabled: prefs.getBool('baqarah_alarm_enabled') ?? false,
    isDailyVerseEnabled: prefs.getBool('daily_verse_alarm_enabled') ?? false,
  );
}

Future<void> _replenishPrayers(SharedPreferences prefs, int generation) =>
    PrayerReplenishmentService(
      preferences: prefs,
      repository: PrayerTimesRepositoryImpl(),
      scheduler: LocalPrayerNotificationScheduler(prefs: prefs),
      expectedGeneration: generation,
    ).replenish();

/// Reschedules daily reminders and the next prayer days from saved settings.
///
/// Skips a run that follows another within 45 s (WorkManager can enqueue
/// several near-identical startup jobs), and stops without writing once the
/// app has rescheduled meanwhile ([SchedulingGeneration]). Errors are
/// rethrown so WorkManager retries; the success time is saved only after
/// everything succeeded.
@visibleForTesting
Future<void> handleRescheduleAlarms({
  Map<String, dynamic>? inputData,
  Future<SharedPreferences> Function()? preferences,
  Future<void> Function(SharedPreferences prefs)? updateReminders,
  Future<void> Function(SharedPreferences prefs, int generation)?
  replenishPrayers,
  DateTime Function()? now,
}) async {
  developer.log(
    'Rescheduling alarms after boot/update',
    name: 'sakina_app.workmanager',
  );

  SharedPreferences? loaded;
  try {
    final SharedPreferences prefs = loaded =
        await (preferences ?? SharedPreferences.getInstance)();
    await prefs.reload();
    final int nowMs = (now ?? DateTime.now)().millisecondsSinceEpoch;
    final int lastRunMs = prefs.getInt(kLastBackgroundRescheduleAtMsKey) ?? 0;

    // A settings update or a clock/timezone change must always be applied.
    if (!_unthrottledSources.contains(inputData?['source']) &&
        nowMs >= lastRunMs &&
        nowMs - lastRunMs < _kBackgroundRescheduleThrottleMs) {
      developer.log(
        'Skipping duplicate background reschedule execution',
        name: 'sakina_app.workmanager',
      );
      return;
    }

    // The UI isolate advances this whenever it reschedules; if it does so
    // while this run is going, this run stops instead of overwriting it.
    final int generation = SchedulingGeneration.read(prefs);

    await prefs.reload();
    if (SchedulingGeneration.read(prefs) != generation) {
      developer.log(
        'Background reschedule superseded by the app',
        name: 'sakina_app.workmanager',
      );
      return;
    }

    await (updateReminders ?? _updateRemindersFromSettings)(prefs);
    await (replenishPrayers ?? _replenishPrayers)(prefs, generation);
    // A failed fetch/schedule must remain retryable by WorkManager.
    await prefs.setInt(kLastBackgroundRescheduleAtMsKey, nowMs);

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
    // Visible in Settings → diagnostics; release builds drop log output.
    await DiagnosticsLog.record(e, source: 'background', preferences: loaded);
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
  bool _isPeriodicTaskRegistered = false;
  bool _isBootTaskRegistered = false;
  DateTime? _lastImmediateRescheduleAt;

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
    if (_isPeriodicTaskRegistered) return;

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

      _isPeriodicTaskRegistered = true;
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
  /// One-off tasks run as iOS `BGProcessingTask`s, whose identifiers
  /// would have to be listed in Info.plist. iOS keeps pending notifications
  /// across reboots and the app reschedules in the foreground, so only the
  /// periodic task is used there (audit NOTIF-04).
  @visibleForTesting
  static bool get supportsOneOffTasks =>
      kIsWeb || defaultTargetPlatform != TargetPlatform.iOS;

  Future<void> registerBootRescheduleTask({
    String source = 'boot_or_update',
  }) async {
    if (_isBootTaskRegistered || !supportsOneOffTasks) return;

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
      _isBootTaskRegistered = true;
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
    if (!supportsOneOffTasks) return;
    final DateTime now = DateTime.now();
    final DateTime? last = _lastImmediateRescheduleAt;
    if (last != null && now.difference(last) < const Duration(seconds: 20)) {
      developer.log(
        'Skipping duplicate immediate reschedule request from $source',
        name: 'sakina_app.workmanager',
        level: 900,
      );
      return;
    }

    _lastImmediateRescheduleAt = now;

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
