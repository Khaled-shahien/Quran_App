import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sakina_app/core/services/device_position_resolver.dart';
import 'package:sakina_app/core/services/location_access_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QiblaHeading {
  const QiblaHeading(this.degrees, {this.needsCalibration = false});
  final double degrees;
  final bool needsCalibration;
}

/// Device access is isolated so permission and sensor failures are testable.
class QiblaDeviceService {
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<bool> locationEnabled() => Geolocator.isLocationServiceEnabled();
  Future<LocationPermission> permission() => Geolocator.checkPermission();
  Future<LocationPermission> requestPermission() async {
    // Shared with LocationAccessService, so first-run setup and prayer
    // screens know the system dialog was already shown.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(LocationAccessService.requestedKey, true);
    } catch (_) {
      // The request does not depend on this record.
    }
    return Geolocator.requestPermission();
  }

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<Position> currentPosition() => DevicePositionResolver().resolve();

  Stream<QiblaHeading> headings(Position position) =>
      const EventChannel('sakina/qibla_heading')
          .receiveBroadcastStream({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'altitude': position.altitude,
          })
          .map((event) {
            final data = Map<Object?, Object?>.from(event as Map);
            return QiblaHeading(
              (data['heading'] as num).toDouble(),
              needsCalibration: data['needsCalibration'] as bool? ?? true,
            );
          });
}
