import 'package:flutter/foundation.dart';

import '../../data/repositories/adhan_settings_store.dart';
import '../../domain/adhan_voices.dart';
import '../../domain/after_adhan.dart';
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
    this.quietAccess,
    this.openQuietAccess,
    this.fullScreenAllowed,
    this.openFullScreen,
  });

  /// Re-plans today's alerts with the new settings.
  final Future<void> Function() reschedule;
  final Future<bool?> Function() canScheduleExact;
  final Future<bool?> Function() requestExact;
  final Future<void> Function(AdhanSettings settings) scheduleTest;

  /// Asks for permission to show notifications; false when refused. Null
  /// where no permission is needed.
  final Future<bool> Function()? requestNotifications;

  /// Do Not Disturb access, and opening the system page that grants it.
  final Future<bool?> Function()? quietAccess;
  final Future<void> Function()? openQuietAccess;

  /// Full-screen alarms (Android 14+ lets the user withdraw them).
  final Future<bool?> Function()? fullScreenAllowed;
  final Future<void> Function()? openFullScreen;
}

class AdhanSettingsController extends ChangeNotifier {
  AdhanSettingsController({
    required AdhanSettingsStore store,
    required AdhanPlatform platform,
    AfterAdhanSettingsStore? afterStore,
  }) : _store = store,
       _platform = platform,
       _afterStore = afterStore,
       _settings = store.read(),
       _after = afterStore?.read() ?? const AfterAdhanSettings();

  final AdhanSettingsStore _store;
  final AdhanPlatform _platform;
  final AfterAdhanSettingsStore? _afterStore;
  AdhanSettings _settings;
  AfterAdhanSettings _after;
  bool? _quietAccess;
  bool? _fullScreenAllowed;

  /// The quiet period and Fajr wake alarm; null where not offered.
  AfterAdhanSettings? get afterAdhan => _afterStore == null ? null : _after;

  /// Null where unknown or not applicable.
  bool? get quietAccess => _quietAccess;
  bool? get fullScreenAllowed => _fullScreenAllowed;

  /// Re-reads the two system permissions (on open and on return).
  Future<void> refreshAfterAdhanAccess() async {
    _quietAccess = await _platform.quietAccess?.call();
    _fullScreenAllowed = await _platform.fullScreenAllowed?.call();
    _notify();
  }

  Future<void> openQuietAccess() async => _platform.openQuietAccess?.call();

  Future<void> openFullScreenSettings() async =>
      _platform.openFullScreen?.call();

  Future<void> setQuietMinutes(int minutes) {
    if (!AfterAdhanSettings.quietOptions.contains(minutes)) {
      return Future.value();
    }
    return _updateAfter(_after.copyWith(quietMinutes: minutes));
  }

  Future<void> setFajrWake(bool on) =>
      _updateAfter(_after.copyWith(fajrWake: on));

  Future<void> setSnoozeMinutes(int minutes) {
    if (!AfterAdhanSettings.snoozeOptions.contains(minutes)) {
      return Future.value();
    }
    return _updateAfter(_after.copyWith(snoozeMinutes: minutes));
  }

  Future<void> _updateAfter(AfterAdhanSettings next) async {
    final store = _afterStore;
    if (store == null) return;
    _after = next;
    _notify();
    await store.write(next);
    await _platform.reschedule();
  }

  bool? _exactAllowed;
  bool _disposed = false;

  AdhanSettings get settings => _settings;

  /// Null where exact timing needs no permission.
  bool? get exactAllowed => _exactAllowed;

  /// Re-reads whether exact alarms are allowed. When that changed since the
  /// last check (the user granted or revoked it in system settings), the
  /// alerts are re-planned: Android cancels pending exact alarms on revoke,
  /// and a grant makes exact timing available again (audit NOTIF-06).
  Future<void> refreshExactStatus() async {
    final bool? previous = _exactAllowed;
    _exactAllowed = await _platform.canScheduleExact();
    _notify();
    if (previous != null &&
        _exactAllowed != null &&
        previous != _exactAllowed) {
      await _platform.reschedule();
    }
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
