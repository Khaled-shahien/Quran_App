import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:sakina_app/core/services/location_access_service.dart';
import 'package:sakina_app/core/services/location_fix.dart';
import 'package:sakina_app/core/services/notification_permission_service.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_times_provider.dart';

/// A position as the platform would report it.
Position fakePosition({
  double latitude = 30.0444,
  double longitude = 31.2357,
  DateTime? timestamp,
  double accuracy = 50,
}) => Position(
  latitude: latitude,
  longitude: longitude,
  timestamp: timestamp ?? DateTime(2026, 11, 17, 12),
  accuracy: accuracy,
  altitude: 20,
  altitudeAccuracy: 5,
  heading: 0,
  headingAccuracy: 1,
  speed: 0,
  speedAccuracy: 1,
);

DeviceLocationFix fakeFix({
  double latitude = 30.0444,
  double longitude = 31.2357,
  DateTime? timestamp,
  double? accuracy = 2000,
  LocationFixSource source = LocationFixSource.fresh,
}) => DeviceLocationFix(
  latitude: latitude,
  longitude: longitude,
  timestamp: timestamp ?? DateTime(2026, 11, 17, 12),
  source: source,
  accuracyMeters: accuracy,
);

/// Notification permission as a phone would report it, with call counts.
class FakeNotificationPlatform implements NotificationPermissionPlatform {
  FakeNotificationPlatform({
    this.enabled = false,
    this.rationale,
    this.grantOnRequest = false,
    this.throwOnCheck = false,
  });

  bool? enabled;

  /// Android's "would still show the dialog"; null on iOS.
  bool? rationale;
  bool grantOnRequest;
  bool throwOnCheck;
  int requests = 0;
  int settingsOpened = 0;

  @override
  Future<bool?> isEnabled() async {
    if (throwOnCheck) throw StateError('plugin missing');
    return enabled;
  }

  @override
  Future<bool> request() async {
    requests++;
    if (grantOnRequest) enabled = true;
    return enabled ?? false;
  }

  @override
  Future<bool?> shouldShowRationale() async => rationale;

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return true;
  }
}

/// Location access and fixes without GPS hardware.
class FakeLocationPlatform implements LocationPlatform {
  FakeLocationPlatform({
    this.permission = LocationPermission.denied,
    this.servicesEnabled = true,
    this.resultOnRequest = LocationPermission.whileInUse,
    DeviceLocationFix? fix,
    this.supported = true,
  }) : fix = fix ?? fakeFix();

  LocationPermission permission;
  bool servicesEnabled;
  LocationPermission resultOnRequest;
  DeviceLocationFix fix;
  Object? fixError;
  bool supported;
  int requests = 0;
  int fixes = 0;
  int appSettingsOpened = 0;
  int locationSettingsOpened = 0;

  @override
  bool get isSupported => supported;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<bool> isServiceEnabled() async => servicesEnabled;

  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    permission = resultOnRequest;
    return permission;
  }

  @override
  Future<DeviceLocationFix> currentFix() async {
    fixes++;
    final error = fixError;
    if (error != null) throw error;
    return fix;
  }

  @override
  Future<bool> openAppSettings() async {
    appSettingsOpened++;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    locationSettingsOpened++;
    return true;
  }
}

/// A device location service for [PrayerTimesProvider] tests.
class FakeDeviceFixService implements DeviceFixLocationService {
  FakeDeviceFixService(this.fix);

  DeviceLocationFix fix;
  Object? error;
  Completer<DeviceLocationFix>? pending;
  final List<bool> requestAccessCalls = [];

  @override
  Future<DeviceLocationFix> currentFix({bool requestAccess = true}) async {
    requestAccessCalls.add(requestAccess);
    final waiting = pending;
    if (waiting != null) return waiting.future;
    final failure = error;
    if (failure != null) throw failure;
    return fix;
  }

  @override
  Future<Coordinates> getCurrentCoordinates() async {
    final value = await currentFix();
    return (latitude: value.latitude, longitude: value.longitude);
  }
}
