import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/alarm_scheduler.dart';
import '../services/alarm_reschedule_task_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SharedPreferences prefs;
  final AlarmScheduler _alarmScheduler;
  final AlarmRescheduleTaskService _rescheduleTaskService;

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
  }) : _alarmScheduler = alarmScheduler ?? NotificationAlarmScheduler(),
       _rescheduleTaskService =
           rescheduleTaskService ?? WorkManagerAlarmRescheduleTaskService() {
    _loadSettings();
  }

  bool get isMorningAlarmEnabled => _isMorningAlarmEnabled;
  bool get isEveningAlarmEnabled => _isEveningAlarmEnabled;
  bool get isMulkAlarmEnabled => _isMulkAlarmEnabled;
  bool get isBaqarahAlarmEnabled => _isBaqarahAlarmEnabled;

  void _loadSettings() async {
    _isMorningAlarmEnabled = prefs.getBool(_morningAlarmKey) ?? false;
    _isEveningAlarmEnabled = prefs.getBool(_eveningAlarmKey) ?? false;
    _isMulkAlarmEnabled = prefs.getBool(_mulkAlarmKey) ?? false;
    _isBaqarahAlarmEnabled = prefs.getBool(_baqarahAlarmKey) ?? false;

    notifyListeners();

    // Keep startup responsive: sync alarms in background without adding
    // another startup one-off WorkManager task.
    unawaited(_syncAlarmsFromSettings());
  }

  Future<void> _syncAlarmsFromSettings() async {
    await _alarmScheduler.initialize(requestPermissions: false);
    await _updateAllAlarms();
  }

  /// Update all alarms based on current settings
  Future<void> _updateAllAlarms() async {
    await _alarmScheduler.updateAllAlarms(
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
    unawaited(
      _rescheduleTaskService.registerImmediateRescheduleTask(
        source: 'toggle_morning',
      ),
    );
  }

  Future<void> toggleEveningAlarm(bool value) async {
    _isEveningAlarmEnabled = value;
    await prefs.setBool(_eveningAlarmKey, value);
    notifyListeners();

    unawaited(_updateAllAlarms());
    unawaited(
      _rescheduleTaskService.registerImmediateRescheduleTask(
        source: 'toggle_evening',
      ),
    );
  }

  Future<void> toggleMulkAlarm(bool value) async {
    _isMulkAlarmEnabled = value;
    await prefs.setBool(_mulkAlarmKey, value);
    notifyListeners();

    unawaited(_updateAllAlarms());
    unawaited(
      _rescheduleTaskService.registerImmediateRescheduleTask(
        source: 'toggle_mulk',
      ),
    );
  }

  Future<void> toggleBaqarahAlarm(bool value) async {
    _isBaqarahAlarmEnabled = value;
    await prefs.setBool(_baqarahAlarmKey, value);
    notifyListeners();

    unawaited(_updateAllAlarms());
    unawaited(
      _rescheduleTaskService.registerImmediateRescheduleTask(
        source: 'toggle_baqarah',
      ),
    );
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

    // Save the new time
    await _alarmScheduler.saveAlarmTime(type: type, hour: hour, minute: minute);
    developer.log(
      'Saved alarm time to preferences',
      name: 'sakina_app.settings',
    );

    // Reschedule only the selected alarm to avoid unnecessary work.
    switch (type) {
      case 'morning':
        await _alarmScheduler.rescheduleSingleAlarm(
          type: type,
          enabled: _isMorningAlarmEnabled,
          hour: hour,
          minute: minute,
        );
        developer.log(
          'Rescheduled morning adhkar alarm',
          name: 'sakina_app.settings',
        );
        break;
      case 'evening':
        await _alarmScheduler.rescheduleSingleAlarm(
          type: type,
          enabled: _isEveningAlarmEnabled,
          hour: hour,
          minute: minute,
        );
        developer.log(
          'Rescheduled evening adhkar alarm',
          name: 'sakina_app.settings',
        );
        break;
      case 'mulk':
        await _alarmScheduler.rescheduleSingleAlarm(
          type: type,
          enabled: _isMulkAlarmEnabled,
          hour: hour,
          minute: minute,
        );
        developer.log('Rescheduled mulk alarm', name: 'sakina_app.settings');
        break;
      case 'baqarah':
        await _alarmScheduler.rescheduleSingleAlarm(
          type: type,
          enabled: _isBaqarahAlarmEnabled,
          hour: hour,
          minute: minute,
        );
        developer.log('Rescheduled baqarah alarm', name: 'sakina_app.settings');
        break;
    }

    unawaited(
      _rescheduleTaskService.registerImmediateRescheduleTask(
        source: 'set_alarm_time_$type',
      ),
    );

    notifyListeners();
    developer.log('Alarm time set completed', name: 'sakina_app.settings');
  }

  /// Get saved alarm time
  Future<Map<String, int>> getAlarmTime(String type) async {
    return await _alarmScheduler.getAlarmTime(type);
  }
}
