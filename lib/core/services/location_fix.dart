import 'package:geolocator/geolocator.dart';

/// How a device fix was obtained. Only [fresh] and [recentCache] describe
/// where the phone is now; [staleCache] is the last place the phone knew,
/// used only when a new fix could not be had, and always shown as such.
enum LocationFixSource { fresh, recentCache, staleCache }

/// Limits for accepting a device position for prayer times and the qibla.
///
/// Prayer times move by about 4 minutes per degree of longitude, so a fix
/// within a few kilometres changes them by seconds. The limits reject fixes
/// that are invalid or too vague to name the right city, not ones that are
/// merely approximate (Android grants only approximate location here).
abstract final class LocationQuality {
  /// A fix less precise than this is rejected: it may be a cell or IP
  /// estimate that can sit in a neighbouring city.
  static const double maxUsableAccuracyMeters = 20000;

  /// Above this the fix is reported to the user as approximate.
  static const double approximateAccuracyMeters = 1000;

  /// A cached fix this recent is used without asking for a new one.
  static const Duration maxRecentCacheAge = Duration(minutes: 10);

  /// When a new fix fails, a cached one up to this old is still offered,
  /// marked [LocationFixSource.staleCache]. Older ones are never used.
  static const Duration maxFallbackCacheAge = Duration(hours: 24);

  /// A saved device location older than this is refreshed when the app
  /// comes to the foreground (never in the background).
  static const Duration deviceLocationRefreshAge = Duration(hours: 6);

  /// Moves shorter than this do not change displayed prayer minutes, so
  /// they neither recalculate nor reschedule notifications.
  static const double significantMoveMeters = 5000;
}

/// Why a position was refused.
enum LocationFixProblem {
  outOfRange,
  nullIsland,
  invalidAccuracy,
  tooInaccurate,
  tooOld,
}

class LocationFixException implements Exception {
  const LocationFixException(this.problem);
  final LocationFixProblem problem;

  @override
  String toString() => 'LocationFixException($problem)';
}

/// True for finite coordinates inside the valid latitude/longitude ranges.
bool isValidCoordinate(double latitude, double longitude) =>
    latitude.isFinite &&
    longitude.isFinite &&
    latitude.abs() <= 90 &&
    longitude.abs() <= 180;

/// A validated device position with what is known about its quality.
class DeviceLocationFix {
  const DeviceLocationFix({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.source,
    this.accuracyMeters,
    this.position,
  });

  final double latitude;
  final double longitude;

  /// When the platform measured the position.
  final DateTime timestamp;
  final LocationFixSource source;

  /// Radius of 68% confidence; null when the platform did not report it.
  final double? accuracyMeters;

  /// The platform position, when the fix came from one (the qibla compass
  /// needs its altitude).
  final Position? position;

  bool get isApproximate =>
      accuracyMeters == null ||
      accuracyMeters! > LocationQuality.approximateAccuracyMeters;

  bool get isStale => source == LocationFixSource.staleCache;

  Duration age(DateTime now) {
    final difference = now.difference(timestamp);
    return difference.isNegative ? Duration.zero : difference;
  }

  /// Checks [position] and wraps it, or returns why it cannot be used.
  ///
  /// Exactly (0, 0) is refused: it is what an unset or failed fix reports,
  /// not a place anyone prays. A negative accuracy is iOS's "invalid".
  /// A zero accuracy means "unknown" on some devices and is kept as null.
  static ({DeviceLocationFix? fix, LocationFixProblem? problem}) validate(
    Position position,
    LocationFixSource source,
  ) {
    final latitude = position.latitude;
    final longitude = position.longitude;
    if (!isValidCoordinate(latitude, longitude)) {
      return (fix: null, problem: LocationFixProblem.outOfRange);
    }
    if (latitude == 0 && longitude == 0) {
      return (fix: null, problem: LocationFixProblem.nullIsland);
    }
    final reported = position.accuracy;
    if (reported.isNaN || reported < 0) {
      return (fix: null, problem: LocationFixProblem.invalidAccuracy);
    }
    final double? accuracy = reported == 0 ? null : reported;
    if (accuracy != null &&
        accuracy > LocationQuality.maxUsableAccuracyMeters) {
      return (fix: null, problem: LocationFixProblem.tooInaccurate);
    }
    return (
      fix: DeviceLocationFix(
        latitude: latitude,
        longitude: longitude,
        timestamp: position.timestamp,
        source: source,
        accuracyMeters: accuracy,
        position: position,
      ),
      problem: null,
    );
  }
}
