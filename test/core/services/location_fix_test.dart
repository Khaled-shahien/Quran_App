import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/services/location_fix.dart';

import '../../helpers/permission_fakes.dart';

void main() {
  group('DeviceLocationFix.validate', () {
    LocationFixProblem? problemOf({
      double latitude = 30.0444,
      double longitude = 31.2357,
      double accuracy = 50,
    }) => DeviceLocationFix.validate(
      fakePosition(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
      ),
      LocationFixSource.fresh,
    ).problem;

    test('accepts a normal city-level fix', () {
      final result = DeviceLocationFix.validate(
        fakePosition(accuracy: 30),
        LocationFixSource.fresh,
      );
      expect(result.problem, isNull);
      expect(result.fix!.latitude, 30.0444);
      expect(result.fix!.accuracyMeters, 30);
      expect(result.fix!.isApproximate, isFalse);
      expect(result.fix!.position, isNotNull);
    });

    test('refuses out-of-range and non-finite coordinates', () {
      expect(problemOf(latitude: 91), LocationFixProblem.outOfRange);
      expect(problemOf(latitude: -90.5), LocationFixProblem.outOfRange);
      expect(problemOf(longitude: 181), LocationFixProblem.outOfRange);
      expect(problemOf(latitude: double.nan), LocationFixProblem.outOfRange);
      expect(
        problemOf(longitude: double.infinity),
        LocationFixProblem.outOfRange,
      );
    });

    test('refuses (0, 0), the value of an unset fix', () {
      expect(
        problemOf(latitude: 0, longitude: 0),
        LocationFixProblem.nullIsland,
      );
      // A real place on the equator or the meridian is fine.
      expect(problemOf(latitude: 0, longitude: 32.58), isNull);
      expect(problemOf(latitude: 51.48, longitude: 0), isNull);
    });

    test('refuses invalid (negative or NaN) accuracy', () {
      expect(problemOf(accuracy: -1), LocationFixProblem.invalidAccuracy);
      expect(
        problemOf(accuracy: double.nan),
        LocationFixProblem.invalidAccuracy,
      );
    });

    test('refuses fixes too vague to name the right city', () {
      expect(
        problemOf(accuracy: LocationQuality.maxUsableAccuracyMeters + 1),
        LocationFixProblem.tooInaccurate,
      );
      expect(
        problemOf(accuracy: double.infinity),
        LocationFixProblem.tooInaccurate,
      );
    });

    test('keeps an approximate (Android coarse) fix and marks it', () {
      final fix = DeviceLocationFix.validate(
        fakePosition(accuracy: 2000),
        LocationFixSource.fresh,
      ).fix!;
      expect(fix.isApproximate, isTrue);
    });

    test('treats a zero accuracy as unknown, not as perfect', () {
      final fix = DeviceLocationFix.validate(
        fakePosition(accuracy: 0),
        LocationFixSource.fresh,
      ).fix!;
      expect(fix.accuracyMeters, isNull);
      expect(fix.isApproximate, isTrue);
    });
  });

  test('age is never negative for a timestamp ahead of the clock', () {
    final fix = fakeFix(timestamp: DateTime(2026, 11, 17, 12, 5));
    expect(fix.age(DateTime(2026, 11, 17, 12)), Duration.zero);
    expect(fix.age(DateTime(2026, 11, 17, 13, 5)), const Duration(hours: 1));
  });

  test('isValidCoordinate bounds', () {
    expect(isValidCoordinate(90, 180), isTrue);
    expect(isValidCoordinate(-90, -180), isTrue);
    expect(isValidCoordinate(90.0001, 0), isFalse);
    expect(isValidCoordinate(0, -180.0001), isFalse);
  });
}
