import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Optional monitoring. Never includes location, Quran queries or reading history.
class MonitoringService extends ChangeNotifier {
  MonitoringService._();
  static final instance = MonitoringService._();
  static const configured = bool.fromEnvironment('ENABLE_FIREBASE_MONITORING');
  SharedPreferences? _preferences;
  bool available = false;
  bool enabled = false;

  Future<void> initialize(SharedPreferences preferences) async {
    if (!configured ||
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
    } catch (_) {
      available = false;
      enabled = false;
    }
  }

  Future<void> setEnabled(bool value) async {
    if (!available) return;
    // Disable the Dart handlers before any asynchronous SDK work on opt-out.
    enabled = false;
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(value);
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(value);
    if (!value) {
      await FirebaseCrashlytics.instance.deleteUnsentReports();
      await FirebaseAnalytics.instance.resetAnalyticsData();
    }
    await _preferences?.setBool('monitoring_enabled', value);
    enabled = value;
    notifyListeners();
  }

  Future<void> _record(Object error, StackTrace stack) async {
    try {
      // Exception messages can contain request URLs or user input.
      await FirebaseCrashlytics.instance.recordError(
        error.runtimeType.toString(),
        stack,
        fatal: true,
      );
    } catch (_) {
      /* Monitoring must never cause another crash. */
    }
  }

  Future<void> event(String name) async {
    if (!enabled) return;
    const allowed = {'app_open', 'settings_open'};
    if (!allowed.contains(name)) return;
    try {
      await FirebaseAnalytics.instance.logEvent(name: name);
    } catch (_) {}
  }
}
