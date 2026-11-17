import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

/// The app's view of notification access, read from the system each time
/// (the user can change it in system settings at any moment).
enum NotificationPermissionStatus {
  /// Not allowed yet and never asked from this app.
  notRequested,

  /// Notifications can be shown (iOS provisional counts as allowed).
  granted,

  /// Refused, and the system will still show its dialog again
  /// (Android 13+ after a single refusal).
  denied,

  /// Only system settings can allow them: Android after repeated refusal
  /// or before Android 13, iOS after any refusal or when restricted.
  permanentlyDenied,

  /// The platform reports nothing (web, tests, plugin missing).
  unsupported,
}

/// Platform calls, isolated so the flow is testable.
abstract class NotificationPermissionPlatform {
  /// Null when the platform cannot tell.
  Future<bool?> isEnabled();

  /// Shows the system dialog where the system allows it.
  Future<bool> request();

  /// Android: whether the system would still show its dialog after a
  /// refusal. Null on other platforms.
  Future<bool?> shouldShowRationale();

  Future<bool> openSettings();
}

class PluginNotificationPermissionPlatform
    implements NotificationPermissionPlatform {
  PluginNotificationPermissionPlatform({NotificationService? service})
    : _service = service ?? NotificationService.instance;

  final NotificationService _service;
  static const MethodChannel _channel = MethodChannel('sakina/permissions');

  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get _apple =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  Future<bool?> isEnabled() async {
    final plugin = _service.flutterLocalNotificationsPlugin;
    if (_android) {
      return plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
    }
    if (_apple) {
      final options = await plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions();
      if (options == null) return null;
      return options.isEnabled || options.isProvisionalEnabled;
    }
    return null;
  }

  @override
  Future<bool> request() => _service.requestPermissions();

  @override
  Future<bool?> shouldShowRationale() async {
    if (!_android) return null;
    return _channel.invokeMethod<bool>('shouldShowNotificationRationale');
  }

  @override
  Future<bool> openSettings() async {
    if (_android) {
      try {
        final opened = await _channel.invokeMethod<bool>(
          'openNotificationSettings',
        );
        if (opened ?? false) return true;
      } on PlatformException {
        // Falls back to the app's settings page below.
      } on MissingPluginException {
        // Same fallback.
      }
    }
    // iOS: the app's page in Settings, which lists Notifications.
    return Geolocator.openAppSettings();
  }
}

/// The one place that reads, asks for and explains notification access.
///
/// The system dialog is shown only from an explicit user action, after the
/// app has explained why, and never once the system refuses to show it.
class NotificationPermissionService {
  NotificationPermissionService({
    required SharedPreferences prefs,
    NotificationPermissionPlatform? platform,
  }) : _prefs = prefs,
       _platform = platform ?? PluginNotificationPermissionPlatform();

  /// Set whenever the system dialog was requested from this app (also by
  /// [NotificationService.requestPermissions] from other screens).
  static const String requestedKey = 'notification_permission_requested';

  final SharedPreferences _prefs;
  final NotificationPermissionPlatform _platform;

  bool get _requestedBefore => _prefs.get(requestedKey) == true;

  Future<NotificationPermissionStatus> status() async {
    final bool? enabled;
    try {
      enabled = await _platform.isEnabled();
    } catch (_) {
      // Includes a plugin that is not registered (tests, other isolates).
      return NotificationPermissionStatus.unsupported;
    }
    if (enabled == null) return NotificationPermissionStatus.unsupported;
    if (enabled) return NotificationPermissionStatus.granted;
    if (!_requestedBefore) return NotificationPermissionStatus.notRequested;
    bool? rationale;
    try {
      rationale = await _platform.shouldShowRationale();
    } catch (_) {
      rationale = null;
    }
    // Android shows its dialog again only while it would show a rationale;
    // iOS (null) never shows it a second time.
    return rationale == true
        ? NotificationPermissionStatus.denied
        : NotificationPermissionStatus.permanentlyDenied;
  }

  /// Asks the system when it still can, then reports the real state.
  Future<NotificationPermissionStatus> request() async {
    final current = await status();
    if (current != NotificationPermissionStatus.notRequested &&
        current != NotificationPermissionStatus.denied) {
      return current;
    }
    try {
      await _prefs.setBool(requestedKey, true);
      await _platform.request();
    } catch (_) {
      // The state read below is what counts.
    }
    return status();
  }

  Future<bool> openSettings() async {
    try {
      return await _platform.openSettings();
    } catch (_) {
      return false;
    }
  }
}
