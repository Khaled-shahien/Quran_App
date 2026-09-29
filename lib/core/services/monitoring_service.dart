import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'monitoring_gateway.dart';

/// Optional monitoring. Never includes location, Quran queries or reading history.
class MonitoringService extends ChangeNotifier {
  MonitoringService({MonitoringGateway? gateway, bool? configurationEnabled})
    : _gateway = gateway ?? FirebaseMonitoringGateway(),
      _configurationEnabled = configurationEnabled ?? configured;
  static final instance = MonitoringService();
  static const configured = bool.fromEnvironment('ENABLE_FIREBASE_MONITORING');
  final MonitoringGateway _gateway;
  final bool _configurationEnabled;
  Future<void> _pending = Future<void>.value();
  int _revision = 0;
  bool _initialized = false;
  SharedPreferences? _preferences;
  bool available = false;
  bool enabled = false;

  Future<void> initialize(SharedPreferences preferences) async {
    if (_initialized ||
        !_configurationEnabled ||
        kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    _preferences = preferences;
    try {
      available = true;
      await setEnabled(preferences.getBool('monitoring_enabled') ?? false);
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        previous?.call(details);
        if (enabled) {
          unawaited(
            _record(details.exception, details.stack ?? StackTrace.current),
          );
        }
      };
      final previousPlatform = PlatformDispatcher.instance.onError;
      PlatformDispatcher.instance.onError = (error, stack) {
        if (enabled) unawaited(_record(error, stack));
        return previousPlatform?.call(error, stack) ?? false;
      };
      await event('app_open');
      _initialized = true;
    } catch (_) {
      available = false;
      enabled = false;
    }
  }

  Future<void> setEnabled(bool value) {
    if (!available) return Future<void>.value();
    final revision = ++_revision;
    // Stop Dart event/error forwarding immediately, including queued opt-outs.
    enabled = false;
    notifyListeners();
    final operation = _pending.then((_) => _applyConsent(value, revision));
    _pending = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> _saveConsent(bool value) async {
    if (!await _preferences!.setBool('monitoring_enabled', value)) {
      throw StateError('Monitoring consent could not be saved');
    }
  }

  Future<void> _disableSdk() async {
    // Attempt both SDKs and both cleanup operations even if one fails.
    await Future.wait([
      Future.sync(() => _gateway.setCrashCollection(false)),
      Future.sync(() => _gateway.setAnalyticsCollection(false)),
      Future.sync(_gateway.deleteUnsentReports),
      Future.sync(_gateway.resetAnalyticsData),
    ]);
  }

  Future<void> _applyConsent(bool value, int revision) async {
    if (revision != _revision) return;
    try {
      // Persist off first so a failed SDK operation cannot restore old consent
      // on the next launch. Do not report an opt-in whose save failed.
      await _saveConsent(false);
      if (!value) {
        await _disableSdk();
      } else {
        await Future.wait([
          Future.sync(() => _gateway.setCrashCollection(true)),
          Future.sync(() => _gateway.setAnalyticsCollection(true)),
        ]);
        if (revision != _revision) {
          await _disableSdk();
          return;
        }
        await _saveConsent(true);
        enabled = revision == _revision;
      }
    } catch (_) {
      enabled = false;
      try {
        await _saveConsent(false);
      } catch (_) {}
      try {
        await _disableSdk();
      } catch (_) {}
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _record(Object error, StackTrace stack) async {
    try {
      // Exception messages can contain request URLs or user input.
      await _gateway.recordError(error.runtimeType.toString(), stack);
    } catch (_) {
      /* Monitoring must never cause another crash. */
    }
  }

  Future<void> event(String name) async {
    if (!enabled) return;
    const allowed = {'app_open', 'settings_open'};
    if (!allowed.contains(name)) return;
    try {
      await _gateway.logEvent(name);
    } catch (_) {}
  }
}
