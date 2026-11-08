import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// SDK boundary for independently testing consent and redaction behavior.
abstract class MonitoringGateway {
  Future<void> setCrashCollection(bool enabled);
  Future<void> deleteUnsentReports();
  Future<void> recordError(String type, StackTrace stack);
}

class FirebaseMonitoringGateway implements MonitoringGateway {
  @override
  Future<void> setCrashCollection(bool enabled) =>
      FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);
  @override
  Future<void> deleteUnsentReports() =>
      FirebaseCrashlytics.instance.deleteUnsentReports();
  @override
  Future<void> recordError(String type, StackTrace stack) =>
      FirebaseCrashlytics.instance.recordError(type, stack, fatal: true);
}
