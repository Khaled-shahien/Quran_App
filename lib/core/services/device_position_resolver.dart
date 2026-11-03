import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Resolves a device position that is accurate enough for prayer times and
/// the qibla bearing (city level).
///
/// Emulators return a mock fix instantly, but a real phone indoors can need
/// well over a minute for a GPS-only fix. A recent cached fix is used first,
/// otherwise a balanced (fused network + GPS) fix is requested, and an older
/// cached fix is the fallback when that request fails or times out.
class DevicePositionResolver {
  DevicePositionResolver({
    Future<Position?> Function()? lastKnown,
    Future<Position> Function(LocationSettings settings)? current,
    DateTime Function()? now,
  }) : _lastKnown = lastKnown ?? Geolocator.getLastKnownPosition,
       _current =
           current ??
           ((settings) =>
               Geolocator.getCurrentPosition(locationSettings: settings)),
       _now = now ?? DateTime.now;

  static const maxCachedAge = Duration(minutes: 30);
  static const timeLimit = Duration(seconds: 30);

  final Future<Position?> Function() _lastKnown;
  final Future<Position> Function(LocationSettings settings) _current;
  final DateTime Function() _now;

  /// Callers must check location services and permission first.
  Future<Position> resolve() async {
    final cached = await _cachedPosition();
    if (cached != null &&
        _now().difference(cached.timestamp).abs() <= maxCachedAge) {
      return cached;
    }
    try {
      // Outer timeout guards platforms that ignore the settings time limit.
      return await _current(
        _settings(),
      ).timeout(timeLimit + const Duration(seconds: 5));
    } on Exception {
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<Position?> _cachedPosition() async {
    try {
      return await _lastKnown();
    } on Exception {
      return null;
    }
  }

  static LocationSettings _settings() =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? AndroidSettings(accuracy: LocationAccuracy.medium, timeLimit: timeLimit)
      : const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: timeLimit,
        );
}
