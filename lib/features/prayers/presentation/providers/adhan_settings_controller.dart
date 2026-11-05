import 'package:flutter/foundation.dart';

import '../../data/repositories/adhan_settings_store.dart';
import '../../domain/entities/adhan_settings.dart';

/// Platform hooks the adhan settings need, kept behind functions so the
/// controller is testable without notification plugins.
class AdhanPlatform {
  const AdhanPlatform({
    required this.reschedule,
    required this.canScheduleExact,
    required this.requestExact,
    required this.scheduleTest,
  });

  /// Re-plans today's alerts with the new settings.
  final Future<void> Function() reschedule;
  final Future<bool?> Function() canScheduleExact;
  final Future<bool?> Function() requestExact;
  final Future<void> Function(AdhanSettings settings) scheduleTest;
}

class AdhanSettingsController extends ChangeNotifier {
  AdhanSettingsController({
    required AdhanSettingsStore store,
    required AdhanPlatform platform,
  }) : _store = store,
       _platform = platform,
       _settings = store.read();

  final AdhanSettingsStore _store;
  final AdhanPlatform _platform;
  AdhanSettings _settings;
  bool? _exactAllowed;
  bool _disposed = false;

  AdhanSettings get settings => _settings;

  /// Null where exact timing needs no permission.
  bool? get exactAllowed => _exactAllowed;

  Future<void> refreshExactStatus() async {
    _exactAllowed = await _platform.canScheduleExact();
    _notify();
  }

  Future<void> setMode(DailyPrayer prayer, PrayerAlertMode mode) =>
      _update(_settings.withMode(prayer, mode));

  Future<void> setReminderMinutes(int minutes) {
    if (!AdhanSettings.reminderOptions.contains(minutes)) {
      return Future.value();
    }
    return _update(_settings.copyWith(reminderMinutes: minutes));
  }

  /// Call after the user read why exact alarms matter.
  Future<void> requestExactAlarms() async {
    final result = await _platform.requestExact();
    _exactAllowed = result ?? await _platform.canScheduleExact();
    _notify();
    if (_exactAllowed == true) await _platform.reschedule();
  }

  Future<void> scheduleTest() => _platform.scheduleTest(_settings);

  Future<void> _update(AdhanSettings next) async {
    _settings = next;
    _notify();
    await _store.write(next);
    await _platform.reschedule();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
