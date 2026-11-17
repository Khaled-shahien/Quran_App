import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'device_position_resolver.dart';
import 'location_fix.dart';

/// The app's view of location access, rebuilt from the operating system
/// every time it is read (the user can change it in system settings while
/// the app is in the background).
enum LocationAccessStatus {
  /// Never asked from this app; the system dialog can be shown.
  notRequested,

  /// Foreground ("while in use") or full access.
  granted,

  /// Refused, but the system will still show its dialog again.
  denied,

  /// Refused permanently (Android after repeated refusal, iOS after one,
  /// or restricted by policy). Only system settings can change it.
  permanentlyDenied,

  /// The device's location services are switched off.
  servicesDisabled,

  /// No location support on this platform.
  unsupported,
}

/// Platform calls, isolated so permission flows are testable without GPS.
abstract class LocationPlatform {
  bool get isSupported;
  Future<bool> isServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<bool> openAppSettings();
  Future<bool> openLocationSettings();
  Future<DeviceLocationFix> currentFix();
}

class GeolocatorLocationPlatform implements LocationPlatform {
  GeolocatorLocationPlatform({DevicePositionResolver? resolver})
    : _resolver = resolver;

  final DevicePositionResolver? _resolver;

  @override
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  @override
  Future<DeviceLocationFix> currentFix() =>
      (_resolver ?? DevicePositionResolver()).resolveFix();
}

/// The access problem that stopped a location lookup.
class LocationAccessException implements Exception {
  const LocationAccessException(this.status);
  final LocationAccessStatus status;

  @override
  String toString() => 'LocationAccessException($status)';
}

/// The one place that asks for location access and reads device fixes, for
/// prayer times, the qibla and first-run setup.
///
/// Only foreground access is ever requested. The system dialog is shown
/// only from an explicit user action ([request]), never again once the
/// system reports a permanent refusal.
class LocationAccessService {
  LocationAccessService({LocationPlatform? platform, SharedPreferences? prefs})
    : _platform = platform ?? GeolocatorLocationPlatform(),
      _prefs = prefs;

  /// Set once the system dialog was shown from this app. Geolocator reports
  /// "denied" both before the first request and after a refusal.
  static const String requestedKey = 'location_permission_requested';

  final LocationPlatform _platform;
  final SharedPreferences? _prefs;

  bool get _requestedBefore => _prefs?.get(requestedKey) == true;

  /// Reads the current state from the system.
  Future<LocationAccessStatus> status() async {
    if (!_platform.isSupported) return LocationAccessStatus.unsupported;
    try {
      final permission = await _platform.checkPermission();
      final mapped = _map(permission);
      if (mapped != LocationAccessStatus.granted) return mapped;
      if (!await _platform.isServiceEnabled()) {
        return LocationAccessStatus.servicesDisabled;
      }
      return LocationAccessStatus.granted;
    } catch (_) {
      return LocationAccessStatus.unsupported;
    }
  }

  /// Shows the system dialog when the system still allows it, and returns
  /// the resulting state. Never requests background access.
  Future<LocationAccessStatus> request() async {
    final current = await status();
    if (current != LocationAccessStatus.notRequested &&
        current != LocationAccessStatus.denied) {
      return current;
    }
    try {
      await _prefs?.setBool(requestedKey, true);
      final result = await _platform.requestPermission();
      final mapped = _map(result);
      if (mapped != LocationAccessStatus.granted) {
        // Right after a refusal "denied" means "refused", not "never asked".
        return mapped == LocationAccessStatus.notRequested
            ? LocationAccessStatus.denied
            : mapped;
      }
      return await _platform.isServiceEnabled()
          ? LocationAccessStatus.granted
          : LocationAccessStatus.servicesDisabled;
    } on PermissionRequestInProgressException {
      return LocationAccessStatus.denied;
    } catch (_) {
      return LocationAccessStatus.unsupported;
    }
  }

  /// A validated device fix. Requests access first when [requestAccess] and
  /// the system still allows it; otherwise fails fast without any dialog.
  ///
  /// Throws [LocationAccessException] for access problems, and the
  /// resolver's errors (timeout, [LocationFixException]) for fix problems.
  Future<DeviceLocationFix> currentFix({bool requestAccess = true}) async {
    var access = await status();
    if (requestAccess &&
        (access == LocationAccessStatus.notRequested ||
            access == LocationAccessStatus.denied)) {
      access = await request();
    }
    if (access != LocationAccessStatus.granted) {
      throw LocationAccessException(access);
    }
    return _platform.currentFix();
  }

  /// Opens the page that can fix [status]: location services, or this
  /// app's permission page.
  Future<bool> openSettings(LocationAccessStatus status) async {
    try {
      return status == LocationAccessStatus.servicesDisabled
          ? await _platform.openLocationSettings()
          : await _platform.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  LocationAccessStatus _map(
    LocationPermission permission,
  ) => switch (permission) {
    LocationPermission.always ||
    LocationPermission.whileInUse => LocationAccessStatus.granted,
    LocationPermission.deniedForever => LocationAccessStatus.permanentlyDenied,
    LocationPermission.denied =>
      _requestedBefore
          ? LocationAccessStatus.denied
          : LocationAccessStatus.notRequested,
    LocationPermission.unableToDetermine => LocationAccessStatus.unsupported,
  };
}
