import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sakina_app/core/services/device_position_resolver.dart';

final _now = DateTime(2026, 11, 3, 12);

Position _position(double latitude, DateTime timestamp) => Position(
  latitude: latitude,
  longitude: 31.2357,
  timestamp: timestamp,
  accuracy: 50,
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
  });
}
