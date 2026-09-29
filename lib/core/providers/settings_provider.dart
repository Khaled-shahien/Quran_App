import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/alarm_scheduler.dart';
import '../services/alarm_reschedule_task_service.dart';
import '../services/notification_scheduling_coordinator.dart';

class SettingsProvider extends ChangeNotifier {
  final SharedPreferences prefs;
  final NotificationSchedulingCoordinator _schedulingCoordinator;

  // Alarm keys
  static const String _morningAlarmKey = 'morning_alarm_enabled';
  static const String _eveningAlarmKey = 'evening_alarm_enabled';
  static const String _mulkAlarmKey = 'mulk_alarm_enabled';
  static const String _baqarahAlarmKey = 'baqarah_alarm_enabled';

  bool _isMorningAlarmEnabled = false;
  bool _isEveningAlarmEnabled = false;
  bool _isMulkAlarmEnabled = false;
  bool _isBaqarahAlarmEnabled = false;

  SettingsProvider({
    required this.prefs,
    AlarmScheduler? alarmScheduler,
    AlarmRescheduleTaskService? rescheduleTaskService,
    NotificationSchedulingCoordinator? schedulingCoordinator,
  }) : _schedulingCoordinator = schedulingCoordinator ??
           NotificationSchedulingCoordinator(
             alarmScheduler: alarmScheduler ?? NotificationAlarmScheduler(),
             rescheduleTaskService:
                 rescheduleTaskService ?? WorkManagerAlarmRescheduleTaskService(),
           ) {
    _loadSettings();
  }

  bool get isMorningAlarmEnabled => _isMorningAlarmEnabled;
  bool get isEveningAlarmEnabled => _isEveningAlarmEnabled;
  bool get isMulkAlarmEnabled => _isMulkAlarmEnabled;
  bool get isBaqarahAlarmEnabled => _isBaqarahAlarmEnabled;

  static bool _validatedBoolValue(
    SharedPreferences preferences,
    String key, {
    required bool fallback,
  }) {
    final value = preferences.get(key);

    if (value is bool) {
      return value;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') {
        preferences.setBool(key, true);
        return true;
      }
      if (normalized == 'false') {
        preferences.setBool(key, false);
        return false;
      }
    }

    preferences.setBool(key, fallback);
    return fallback;
  }

  void _loadSettings() async {
    _isMorningAlarmEnabled = _validatedBoolValue(
      prefs,
      _morningAlarmKey,
      fallback: false,
    );
    _isEveningAlarmEnabled = _validatedBoolValue(
      prefs,
      _eveningAlarmKey,
      fallback: false,
    );
    _isMulkAlarmEnabled = _validatedBoolValue(
      prefs,
      _mulkAlarmKey,
      fallback: false,
    );
    _isBaqarahAlarmEnabled = _validatedBoolValue(
      prefs,
      _baqarahAlarmKey,
      fallback: false,
    );

    notifyListeners();

    // Keep startup responsive: sync alarms in background without adding
    // another startup one-off WorkManager task.
    unawaited(_syncAlarmsFromSettings());
  }

  Future<void> _syncAlarmsFromSettings() async {
    await _schedulingCoordinator.syncFromSettings(
      isMorningEnabled: _isMorningAlarmEnabled,
      isEveningEnabled: _isEveningAlarmEnabled,
      isMulkEnabled: _isMulkAlarmEnabled,
      isBaqarahEnabled: _isBaqarahAlarmEnabled,
    );
  }

  /// Update all alarms based on current settings
  Future<void> _updateAllAlarms() async {
    await _schedulingCoordinator.syncFromSettings(
      isMorningEnabled: _isMorningAlarmEnabled,
      isEveningEnabled: _isEveningAlarmEnabled,
      isMulkEnabled: _isMulkAlarmEnabled,
      isBaqarahEnabled: _isBaqarahAlarmEnabled,
    );
  }

  Future<void> toggleMorningAlarm(bool value) async {
    _isMorningAlarmEnabled = value;
    await prefs.setBool(_morningAlarmKey, value);
    notifyListeners();

    unawaited(_updateAllAlarms());
    unawaited(_schedulingCoordinator.requestReschedule('toggle_morning'));
  }

  Future<void> toggleEveningAlarm(bool value) async {
    _isEveningAlarmEnabled = value;
    await prefs.setBool(_eveningAlarmKey, value);
    notifyListeners();

    unawaited(_updateAllAlarms());
    unawaited(_schedulingCoordinator.requestReschedule('toggle_evening'));
  }

  Future<void> toggleMulkAlarm(bool value) async {
    _isMulkAlarmEnabled = value;
    await prefs.setBool(_mulkAlarmKey, value);
    notifyListeners();

    unawaited(_updateAllAlarms());
    unawaited(_schedulingCoordinator.requestReschedule('toggle_mulk'));
  }

  Future<void> toggleBaqarahAlarm(bool value) async {
    _isBaqarahAlarmEnabled = value;
    await prefs.setBool(_baqarahAlarmKey, value);
    notifyListeners();

    unawaited(_updateAllAlarms());
    unawaited(_schedulingCoordinator.requestReschedule('toggle_baqarah'));
  }

  /// Set custom alarm time for a specific type
  Future<void> setAlarmTime({
    required String type,
    required int hour,
    required int minute,
  }) async {
    developer.log(
      'Setting $type alarm to '
      '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}',
      name: 'sakina_app.settings',
    );

    final enabled = switch (type) {
      'morning' => _isMorningAlarmEnabled,
      'evening' => _isEveningAlarmEnabled,
      'mulk' => _isMulkAlarmEnabled,
      'baqarah' => _isBaqarahAlarmEnabled,
      _ => throw ArgumentError('Unknown alarm type: $type'),
    };

    await _schedulingCoordinator.setAlarmTime(
      type: type,
      enabled: enabled,
      hour: hour,
      minute: minute,
    );
    developer.log('Saved and rescheduled alarm time', name: 'sakina_app.settings');

    // Keep the background schedule in sync after the selected alarm changes.
    switch (type) {
      case 'morning':
        developer.log(
          'Rescheduled morning adhkar alarm',
          name: 'sakina_app.settings',
        );
        break;
      case 'evening':
        developer.log(
          'Rescheduled evening adhkar alarm',
          name: 'sakina_app.settings',
        );
        break;
      case 'mulk':
        developer.log('Rescheduled mulk alarm', name: 'sakina_app.settings');
        break;
      case 'baqarah':
        developer.log('Rescheduled baqarah alarm', name: 'sakina_app.settings');
        break;
    }

    unawaited(_schedulingCoordinator.requestReschedule('set_alarm_time_$type'));

    notifyListeners();
    developer.log('Alarm time set completed', name: 'sakina_app.settings');
  }

  /// Get saved alarm time
  Future<Map<String, int>> getAlarmTime(String type) async {
    return await _schedulingCoordinator.getAlarmTime(type);
  }
}
