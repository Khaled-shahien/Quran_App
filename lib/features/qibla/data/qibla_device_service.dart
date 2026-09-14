import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

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
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<Position> currentPosition() => Geolocator.getCurrentPosition(
    locationSettings: !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            forceLocationManager: true,
            accuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 25),
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 25),
          ),
  );

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
