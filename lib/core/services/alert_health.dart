import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'diagnostics_log.dart';
import 'notification_permission_service.dart';
import 'workmanager_service.dart';

/// Something that can stop a prayer alert from arriving on time.
enum AlertHealthIssue {
  /// The system does not allow the app's notifications.
  notificationsOff,

  /// Prayer alerts are switched off in Settings.
  prayerAlertsDisabled,

  /// No prayer location yet, so there is nothing to schedule.
  noLocation,

  /// Alerts are on, but none is waiting in the system.
  nothingScheduled,

  /// Android may deliver alerts late (exact alarms not allowed).
  exactAlarmsOff,

  /// Battery optimisation can delay or skip background rescheduling.
  batteryRestricted,

  /// The last background reschedule failed after the last success.
  backgroundFailing,
}

/// A read of everything that decides whether prayer alerts will arrive.
/// `null` means the platform does not report that item (not a problem).
class AlertHealthSnapshot {
  const AlertHealthSnapshot({
    required this.notifications,
    required this.prayerAlertsEnabled,
    required this.hasLocation,
    required this.pendingPrayerAlerts,
    this.exactAlarms,
    this.batteryUnrestricted,
    this.lastBackgroundRun,
    this.lastBackgroundError,
  });

  final NotificationPermissionStatus notifications;
  final bool prayerAlertsEnabled;
  final bool hasLocation;

  /// Prayer alerts and reminders waiting in the system right now.
  final int pendingPrayerAlerts;
  final bool? exactAlarms;
  final bool? batteryUnrestricted;
  final DateTime? lastBackgroundRun;
  final DateTime? lastBackgroundError;

  bool get notificationsAllowed =>
      notifications == NotificationPermissionStatus.granted ||
      notifications == NotificationPermissionStatus.unsupported;

  /// Most serious first.
  List<AlertHealthIssue> get issues => [
    if (!notificationsAllowed) AlertHealthIssue.notificationsOff,
    if (!prayerAlertsEnabled) AlertHealthIssue.prayerAlertsDisabled,
    if (!hasLocation) AlertHealthIssue.noLocation,
    if (notificationsAllowed &&
        prayerAlertsEnabled &&
        hasLocation &&
        pendingPrayerAlerts == 0)
      AlertHealthIssue.nothingScheduled,
    if (exactAlarms == false) AlertHealthIssue.exactAlarmsOff,
    if (batteryUnrestricted == false) AlertHealthIssue.batteryRestricted,
    if (lastBackgroundError != null &&
        (lastBackgroundRun == null ||
            lastBackgroundError!.isAfter(lastBackgroundRun!)))
      AlertHealthIssue.backgroundFailing,
  ];

  bool get healthy => issues.isEmpty;
}

/// Prayer alert IDs (2011–2075) and their reminders (3011–3075).
bool isPrayerAlertId(int id) =>
    (id >= 2011 && id <= 2075) || (id >= 3011 && id <= 3075);

/// Collects an [AlertHealthSnapshot]. Every source is injectable; a source
/// that throws is reported as unknown rather than failing the check.
class AlertHealthChecker {
  AlertHealthChecker({
    required SharedPreferences prefs,
    required Future<NotificationPermissionStatus> Function() notificationStatus,
    required Future<bool?> Function() exactAlarms,
    required Future<List<int>> Function() pendingIds,
    Future<bool?> Function()? batteryUnrestricted,
  }) : _prefs = prefs,
       _notificationStatus = notificationStatus,
       _exactAlarms = exactAlarms,
       _pendingIds = pendingIds,
       _batteryUnrestricted =
           batteryUnrestricted ?? BatteryOptimization.isUnrestricted;

  final SharedPreferences _prefs;
  final Future<NotificationPermissionStatus> Function() _notificationStatus;
  final Future<bool?> Function() _exactAlarms;
  final Future<List<int>> Function() _pendingIds;
  final Future<bool?> Function() _batteryUnrestricted;

  static Future<T?> _safe<T>(Future<T?> Function() read) async {
    try {
      return await read();
    } catch (_) {
      return null;
    }
  }

  Future<AlertHealthSnapshot> check() async {
    final NotificationPermissionStatus status =
        await _safe(_notificationStatus) ??
        NotificationPermissionStatus.unsupported;
    final List<int> pending = await _safe(_pendingIds) ?? const [];
    final int? okMs = _prefs.getInt(kLastBackgroundRescheduleAtMsKey);
    final Object? errorAt = _prefs.get(DiagnosticsLog.backgroundErrorAtKey);
    return AlertHealthSnapshot(
      notifications: status,
      prayerAlertsEnabled:
          _prefs.getBool('prayer_notifications_enabled') ?? true,
      hasLocation:
          _prefs.get('prayer_latitude') is double &&
          _prefs.get('prayer_longitude') is double,
      pendingPrayerAlerts: pending.where(isPrayerAlertId).length,
      exactAlarms: await _safe(_exactAlarms),
      batteryUnrestricted: await _safe(_batteryUnrestricted),
      lastBackgroundRun: okMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(okMs),
      lastBackgroundError: errorAt is String
          ? DateTime.tryParse(errorAt)?.toLocal()
          : null,
    );
  }
}

/// Android battery optimisation for this app, through `sakina/permissions`.
abstract final class BatteryOptimization {
  static const MethodChannel _channel = MethodChannel('sakina/permissions');

  static bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// True when Android does not restrict the app, null where unknown.
  static Future<bool?> isUnrestricted() async {
    if (!_android) return null;
    return _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
  }

  /// Opens the system list where the app can be set to "unrestricted".
  static Future<bool> openSettings() async {
    if (!_android) return false;
    try {
      return await _channel.invokeMethod<bool>(
            'openBatteryOptimizationSettings',
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }
}
