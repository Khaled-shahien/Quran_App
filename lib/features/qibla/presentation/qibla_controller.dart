import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../data/qibla_device_service.dart';
import '../domain/qibla_direction.dart';

enum QiblaStatus {
  loading,
  ready,
  locationOff,
  denied,
  deniedForever,
  locationError,
  unsupported,
}

class QiblaController extends ChangeNotifier {
  QiblaController({QiblaDeviceService? device})
    : device = device ?? QiblaDeviceService();

  final QiblaDeviceService device;
  QiblaStatus status = QiblaStatus.loading;
  double? bearing;
  QiblaHeading? heading;
  bool sensorUnavailable = false;
  bool nearKaaba = false;
  bool _busy = false;
  int _generation = 0;
  StreamSubscription<QiblaHeading>? _subscription;
  Timer? _sensorTimer;

  double? get turn => heading == null || bearing == null
      ? null
      : qiblaTurn(bearing!, heading!.degrees);
  bool get aligned =>
      turn != null &&
      turn!.abs() <= 5 &&
      !heading!.needsCalibration &&
      !sensorUnavailable;

  Future<void> start({bool requestPermission = true}) async {
    if (_busy) return;
    _busy = true;
    final generation = ++_generation;
    bool current() => generation == _generation;
    _sensorTimer?.cancel();
    await _subscription?.cancel();
    _subscription = null;
    if (!current()) return;
    status = QiblaStatus.loading;
    bearing = null;
    heading = null;
    nearKaaba = false;
    sensorUnavailable = false;
    notifyListeners();
    try {
      if (!device.isSupported) {
        status = QiblaStatus.unsupported;
        return;
      }
      final enabled = await device.locationEnabled();
      if (!current()) return;
      if (!enabled) {
        status = QiblaStatus.locationOff;
        return;
      }
      var permission = await device.permission();
      if (!current()) return;
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await device.requestPermission();
        if (!current()) return;
      }
      if (permission == LocationPermission.deniedForever) {
        status = QiblaStatus.deniedForever;
        return;
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        status = QiblaStatus.denied;
        return;
      }
      final position = await device.currentPosition();
      if (!current()) return;
      bearing = qiblaBearing(position.latitude, position.longitude);
      nearKaaba =
          Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            21.422487,
            39.826206,
          ) <
          100;
      status = QiblaStatus.ready;
      if (nearKaaba) return;
      _sensorTimer = Timer(const Duration(seconds: 10), () {
        if (!current()) return;
        heading = null;
        sensorUnavailable = true;
        notifyListeners();
      });
      _subscription = device
          .headings(position)
          .listen(
            (value) {
              if (!current() || !value.degrees.isFinite || value.degrees < 0) {
                return;
              }
              _sensorTimer?.cancel();
              heading = value;
              sensorUnavailable = false;
              notifyListeners();
            },
            onError: (Object error) {
              if (!current()) return;
              _sensorTimer?.cancel();
              heading = null;
              sensorUnavailable = true;
              notifyListeners();
            },
            onDone: () {
              if (!current()) return;
              _sensorTimer?.cancel();
              heading = null;
              sensorUnavailable = true;
              notifyListeners();
            },
          );
    } on Exception {
      if (current()) status = QiblaStatus.locationError;
    } finally {
      if (current()) {
        _busy = false;
        notifyListeners();
      }
    }
  }

  Future<bool> openSettings() => status == QiblaStatus.locationOff
      ? device.openLocationSettings()
      : device.openAppSettings();

  void pause() {
    ++_generation;
    _busy = false;
    _sensorTimer?.cancel();
    unawaited(_subscription?.cancel());
    _subscription = null;
    heading = null;
  }

  @override
  void dispose() {
    pause();
    super.dispose();
  }
}
