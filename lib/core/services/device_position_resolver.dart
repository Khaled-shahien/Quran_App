import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'location_fix.dart';

/// Resolves a device position that is accurate enough for prayer times and
/// the qibla bearing (city level), and says how it was obtained.
///
/// Emulators return a mock fix instantly, but a real phone indoors can need
/// well over a minute for a GPS-only fix. A cached fix from the last few
/// minutes is used first; otherwise a balanced (fused network + GPS) fix is
/// requested. Only when that fails is an older cached fix (up to a day) used,
/// and it is then marked [LocationFixSource.staleCache] so callers can say
/// so instead of presenting it as the current position.
///
/// Every position is validated ([DeviceLocationFix.validate]): out-of-range,
/// (0, 0), invalid-accuracy and very vague fixes are refused.
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

  static const maxCachedAge = LocationQuality.maxRecentCacheAge;
  static const timeLimit = Duration(seconds: 30);

  final Future<Position?> Function() _lastKnown;
  final Future<Position> Function(LocationSettings settings) _current;
  final DateTime Function() _now;

  /// Callers must check location services and permission first.
  Future<Position> resolve() async {
    final fix = await resolveFix();
    return fix.position!;
  }

  /// Callers must check location services and permission first.
  ///
  /// Throws the platform error (timeout, services off, ...) when there is
  /// neither a new fix nor a usable cached one, or a [LocationFixException]
  /// when the only positions available were refused.
  Future<DeviceLocationFix> resolveFix() async {
    final cached = await _cachedPosition();
    final now = _now();
    final recent = cached == null
        ? null
        : DeviceLocationFix.validate(cached, LocationFixSource.recentCache);
    if (recent?.fix != null &&
        recent!.fix!.age(now) <= LocationQuality.maxRecentCacheAge) {
      return recent.fix!;
    }

    Exception failure;
    StackTrace failureStack;
    try {
      // Outer timeout guards platforms that ignore the settings time limit.
      final position = await _current(
        _settings(),
      ).timeout(timeLimit + const Duration(seconds: 5));
      final checked = DeviceLocationFix.validate(
        position,
        LocationFixSource.fresh,
      );
      if (checked.fix != null) return checked.fix!;
      failure = LocationFixException(checked.problem!);
      failureStack = StackTrace.current;
    } on Exception catch (error, stack) {
      failure = error;
      failureStack = stack;
    }

    // Only when no new fix could be had: the last known place, if it is
    // valid and less than a day old, marked as such.
    final fallback = cached == null
        ? null
        : DeviceLocationFix.validate(cached, LocationFixSource.staleCache).fix;
    if (fallback != null &&
        fallback.age(_now()) <= LocationQuality.maxFallbackCacheAge) {
      return fallback;
    }
    Error.throwWithStackTrace(failure, failureStack);
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
