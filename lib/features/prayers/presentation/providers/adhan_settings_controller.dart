import 'package:flutter/foundation.dart';

import '../../data/repositories/adhan_settings_store.dart';
import '../../domain/adhan_voices.dart';
import '../../domain/entities/adhan_settings.dart';

/// Platform hooks the adhan settings need, kept behind functions so the
/// controller is testable without notification plugins.
class AdhanPlatform {
  const AdhanPlatform({
    required this.reschedule,
    required this.canScheduleExact,
    required this.requestExact,
    required this.scheduleTest,
    this.requestNotifications,
  });

  /// Re-plans today's alerts with the new settings.
  final Future<void> Function() reschedule;
  final Future<bool?> Function() canScheduleExact;
  final Future<bool?> Function() requestExact;
  final Future<void> Function(AdhanSettings settings) scheduleTest;

  /// Asks for permission to show notifications; false when refused. Null
  /// where no permission is needed.
  final Future<bool> Function()? requestNotifications;
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

  /// Ignores ids that are not a bundled recording.
  Future<void> setVoice(DailyPrayer prayer, String voiceId) {
    if (AdhanVoices.byId(voiceId) == null) {
      return Future.value();
    }
    return _update(_settings.withVoice(prayer, voiceId));
  }

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

  /// Schedules the test alert. Returns false, scheduling nothing, when
  /// notifications are not allowed: the system would drop the alert
  /// silently and the user would wait for something that never comes.
  Future<bool> scheduleTest() async {
    final allowed = await _platform.requestNotifications?.call() ?? true;
    if (!allowed) return false;
    await _platform.scheduleTest(_settings);
    return true;
  }

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
