import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sakina_app/core/services/device_position_resolver.dart';
import 'package:sakina_app/core/services/location_fix.dart';

final _now = DateTime(2026, 11, 3, 12);

Position _position(
  double latitude,
  DateTime timestamp, {
  double longitude = 31.2357,
  double accuracy = 50,
}) => Position(
  latitude: latitude,
  longitude: longitude,
  timestamp: timestamp,
  accuracy: accuracy,
  altitude: 20,
  altitudeAccuracy: 5,
  heading: 0,
  headingAccuracy: 1,
  speed: 0,
  speedAccuracy: 1,
);

void main() {
  group('DevicePositionResolver', () {
    test('uses a recent cached fix without waiting for a new one', () async {
      var currentCalls = 0;
      final resolver = DevicePositionResolver(
        lastKnown: () async =>
            _position(1, _now.subtract(const Duration(minutes: 5))),
        current: (_) async {
          currentCalls++;
          return _position(2, _now);
        },
        now: () => _now,
      );

      expect((await resolver.resolve()).latitude, 1);
      expect(currentCalls, 0);
    });

    test('requests a balanced fix when the cache is stale', () async {
      LocationSettings? used;
      final resolver = DevicePositionResolver(
        lastKnown: () async =>
            _position(1, _now.subtract(const Duration(hours: 3))),
        current: (settings) async {
          used = settings;
          return _position(2, _now);
        },
        now: () => _now,
      );

      expect((await resolver.resolve()).latitude, 2);
      expect(used!.accuracy, LocationAccuracy.medium);
      expect(used!.timeLimit, DevicePositionResolver.timeLimit);
    });

    test(
      'falls back to a stale cached fix when the request times out',
      () async {
        final resolver = DevicePositionResolver(
          lastKnown: () async =>
              _position(1, _now.subtract(const Duration(hours: 3))),
          current: (_) async => throw TimeoutException('no fix'),
          now: () => _now,
        );

        expect((await resolver.resolve()).latitude, 1);
      },
    );

    test('rethrows when there is neither a cache nor a fresh fix', () async {
      final resolver = DevicePositionResolver(
        lastKnown: () async => throw const LocationServiceDisabledException(),
        current: (_) async => throw TimeoutException('no fix'),
        now: () => _now,
      );

      await expectLater(resolver.resolve(), throwsA(isA<TimeoutException>()));
    });

    test(
      'a cached fix older than a few minutes is not used as current',
      () async {
        var currentCalls = 0;
        final resolver = DevicePositionResolver(
          lastKnown: () async =>
              _position(1, _now.subtract(const Duration(minutes: 20))),
          current: (_) async {
            currentCalls++;
            return _position(2, _now);
          },
          now: () => _now,
        );

        final fix = await resolver.resolveFix();
        expect(fix.latitude, 2);
        expect(fix.source, LocationFixSource.fresh);
        expect(currentCalls, 1);
      },
    );

    test('the fallback cache is marked stale, never as current', () async {
      final resolver = DevicePositionResolver(
        lastKnown: () async =>
            _position(1, _now.subtract(const Duration(hours: 3))),
        current: (_) async => throw TimeoutException('no fix'),
        now: () => _now,
      );

      final fix = await resolver.resolveFix();
      expect(fix.source, LocationFixSource.staleCache);
      expect(fix.isStale, isTrue);
    });

    test('a cached fix older than a day is never used', () async {
      final resolver = DevicePositionResolver(
        lastKnown: () async =>
            _position(1, _now.subtract(const Duration(days: 2))),
        current: (_) async => throw TimeoutException('no fix'),
        now: () => _now,
      );

      await expectLater(
        resolver.resolveFix(),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('a recent but vague cached fix is not used as current', () async {
      var currentCalls = 0;
      final resolver = DevicePositionResolver(
        lastKnown: () async => _position(
          1,
          _now.subtract(const Duration(minutes: 2)),
          accuracy: 50000,
        ),
        current: (_) async {
          currentCalls++;
          return _position(2, _now, accuracy: 900);
        },
        now: () => _now,
      );

      expect((await resolver.resolveFix()).latitude, 2);
      expect(currentCalls, 1);
    });

    test('an unset (0, 0) current fix is refused', () async {
      final resolver = DevicePositionResolver(
        lastKnown: () async => null,
        current: (_) async => _position(0, _now, longitude: 0),
        now: () => _now,
      );

      await expectLater(
        resolver.resolveFix(),
        throwsA(
          isA<LocationFixException>().having(
            (e) => e.problem,
            'problem',
            LocationFixProblem.nullIsland,
          ),
        ),
      );
    });

    test('a vague current fix falls back to a usable cached one', () async {
      final resolver = DevicePositionResolver(
        lastKnown: () async =>
            _position(1, _now.subtract(const Duration(hours: 1))),
        current: (_) async => _position(2, _now, accuracy: 80000),
        now: () => _now,
      );

      final fix = await resolver.resolveFix();
      expect(fix.latitude, 1);
      expect(fix.isStale, isTrue);
    });

    test('a vague current fix with no cache reports the reason', () async {
      final resolver = DevicePositionResolver(
        lastKnown: () async => null,
        current: (_) async => _position(2, _now, accuracy: 80000),
        now: () => _now,
      );

      await expectLater(
        resolver.resolveFix(),
        throwsA(
          isA<LocationFixException>().having(
            (e) => e.problem,
            'problem',
            LocationFixProblem.tooInaccurate,
          ),
        ),
      );
    });
  });
}
