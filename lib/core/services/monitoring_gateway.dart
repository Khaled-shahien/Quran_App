import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// SDK boundary for independently testing consent and redaction behavior.
abstract class MonitoringGateway {
  Future<void> setCrashCollection(bool enabled);
  Future<void> setAnalyticsCollection(bool enabled);
  Future<void> deleteUnsentReports();
  Future<void> resetAnalyticsData();
  Future<void> logEvent(String name);
  Future<void> recordError(String type, StackTrace stack);
}

class FirebaseMonitoringGateway implements MonitoringGateway {
  @override
  Future<void> setCrashCollection(bool enabled) =>
      FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);
  @override
  Future<void> setAnalyticsCollection(bool enabled) =>
      FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
  @override
  Future<void> deleteUnsentReports() =>
      FirebaseCrashlytics.instance.deleteUnsentReports();
  @override
  Future<void> resetAnalyticsData() =>
      FirebaseAnalytics.instance.resetAnalyticsData();
  @override
  Future<void> logEvent(String name) =>
      FirebaseAnalytics.instance.logEvent(name: name);
  @override
  Future<void> recordError(String type, StackTrace stack) =>
      FirebaseCrashlytics.instance.recordError(type, stack, fatal: true);
}
