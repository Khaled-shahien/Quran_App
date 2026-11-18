import 'package:sakina_app/features/prayers/domain/prayer_time_adjustments.dart';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/core/services/location_access_service.dart';
import 'package:sakina_app/core/services/location_fix.dart';
import 'package:sakina_app/features/prayers/domain/entities/prayer_times_entity.dart';
import 'package:sakina_app/features/prayers/domain/prayer_calculation_policy.dart';
import 'package:sakina_app/features/prayers/domain/prayer_city.dart';
import 'package:sakina_app/features/prayers/domain/prayer_location_source.dart';
import 'package:sakina_app/features/prayers/domain/repositories/prayer_times_repository.dart';
import 'package:sakina_app/features/prayers/domain/services/prayer_notification_scheduler.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_times_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/permission_fakes.dart';

final _now = DateTime(2026, 11, 17, 12);

class _Clock implements PrayerTimesClock {
  DateTime value = _now;
  @override
  DateTime now() => value;
}

/// Records every calculation, with the coordinates it used.
class _Repository implements PrayerTimesRepository {
  final calls = <({double latitude, double longitude, String? zone})>[];

  @override
  Future<Result<PrayerTimesEntity>> getPrayerTimes(
    DateTime date,
    double latitude,
    double longitude, {
    int calculationMethod = PrayerCalculationPolicy.defaultMethod,
    AsrMadhab madhab = AsrMadhab.standard,
    String? timeZone,
    PrayerTimeAdjustments adjustments = PrayerTimeAdjustments.none,
  }) async {
    calls.add((latitude: latitude, longitude: longitude, zone: timeZone));
    return Success(
      PrayerTimesEntity(
        fajr: '05:00',
        sunrise: '06:20',
        dhuhr: '12:15',
        asr: '15:40',
        maghrib: '18:30',
        isha: '19:45',
        latitude: latitude,
        longitude: longitude,
        calculationMethod: calculationMethod,
      ),
    );
  }
}

/// Counts the single scheduling boundary: one cancel and one schedule per
/// accepted location.
class _Scheduler implements PrayerNotificationScheduler {
  int cancels = 0;
  final scheduled = <({double latitude, double longitude})>[];

  @override
  Future<void> cancelPrayerNotifications() async => cancels++;

  @override
  Future<void> schedulePrayerNotifications({
    required PrayerTimesEntity prayerTimes,
    required DateTime date,
  }) async => scheduled.add((
    latitude: prayerTimes.latitude!,
    longitude: prayerTimes.longitude!,
  ));
}

const _cairo = PrayerCity(
  name: 'القاهرة',
  country: 'مصر',
  englishName: 'Cairo',
  latitude: 30.06263,
  longitude: 31.24967,
);

Future<CityMatch?> _cities(double latitude, double longitude) async =>
    NearestCity.find(latitude, longitude, const [_cairo]);

void main() {
  late SharedPreferences prefs;
  late _Repository repository;
  late _Scheduler scheduler;
  late _Clock clock;
  late FakeDeviceFixService device;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repository = _Repository();
    scheduler = _Scheduler();
    clock = _Clock();
    device = FakeDeviceFixService(fakeFix(timestamp: _now));
  });

  PrayerTimesProvider create({
    Future<CityMatch?> Function(double, double)? nearestCity,
  }) {
    final provider = PrayerTimesProvider(
      repository: repository,
      preferences: prefs,
      clock: clock,
      deviceLocationService: device,
      notificationScheduler: scheduler,
      nearestCity: nearestCity ?? _cities,
    );
    addTearDown(provider.dispose);
    return provider;
  }

  group('device location', () {
    test('is saved as a device location with its fix, named offline', () async {
      final provider = create();
      await provider.useDeviceLocation();

      expect(provider.locationSource, PrayerLocationSource.device);
      expect(provider.locationLabel, 'القاهرة، مصر');
      expect(provider.locationAccuracyMeters, 2000);
      expect(provider.locationFixedAt, _now);
      expect(prefs.getString(PrayerLocationSource.preferenceKey), 'device');
      expect(
        prefs.getInt(PrayerLocationSource.fixedAtKey),
        _now.millisecondsSinceEpoch,
      );
      // Follows the device timezone.
      expect(prefs.getString('prayer_timezone'), isNull);
      expect(repository.calls.first.latitude, 30.0444);
      expect(scheduler.scheduled.single.latitude, 30.0444);
    });

    test('far from any listed city keeps a neutral label', () async {
      device.fix = fakeFix(latitude: 31.0409, longitude: 31.3785);
      final provider = create();
      await provider.useDeviceLocation();
      expect(provider.locationLabel, 'موقع الجهاز');
    });

    test('a failing city lookup still saves the location', () async {
      final provider = create(
        nearestCity: (_, _) async => throw StateError('asset unreadable'),
      );
      await provider.useDeviceLocation();
      expect(provider.hasData, isTrue);
      expect(provider.locationLabel, 'موقع الجهاز');
    });

    test('a last-known fallback is flagged for the user', () async {
      device.fix = fakeFix(source: LocationFixSource.staleCache);
      final provider = create();
      await provider.useDeviceLocation();
      expect(provider.lastFixWasStale, isTrue);
      expect(provider.hasData, isTrue);
    });

    test('a failed lookup keeps the saved location and its times', () async {
      final provider = create();
      await provider.selectLocation(21.4225, 39.8262, 'مكة', 4);
      final cancelsBefore = scheduler.cancels;

      device.error = const PrayerLocationException(
        'denied',
        access: LocationAccessStatus.permanentlyDenied,
      );
      await provider.useDeviceLocation();

      expect(provider.hasError, isFalse);
      expect(provider.hasData, isTrue);
      expect(provider.locationLabel, 'مكة');
      expect(provider.selectedCoordinates!.latitude, 21.4225);
      expect(provider.lastLocationError!.needsSettings, isTrue);
      expect(prefs.getDouble('prayer_latitude'), 21.4225);
      expect(scheduler.cancels, cancelsBefore, reason: 'nothing rescheduled');
    });

    test('with no saved location a failure is shown as the error', () async {
      device.error = const PrayerLocationException('no access');
      final provider = create();
      await provider.useDeviceLocation();
      expect(provider.errorMessage, 'no access');
      expect(provider.needsLocation, isFalse);
    });

    test('source, fix time and accuracy survive a restart', () async {
      await create().useDeviceLocation();
      final restored = create();
      expect(restored.locationSource, PrayerLocationSource.device);
      expect(restored.locationFixedAt, _now);
      expect(restored.locationAccuracyMeters, 2000);
    });

    test('a manual city replaces the device source and its fix data', () async {
      final provider = create();
      await provider.useDeviceLocation();
      await provider.selectLocation(31.2, 29.9, 'الإسكندرية', 5);

      expect(provider.locationSource, PrayerLocationSource.manual);
      expect(provider.locationFixedAt, isNull);
      expect(prefs.getString(PrayerLocationSource.preferenceKey), 'manual');
      expect(prefs.get(PrayerLocationSource.fixedAtKey), isNull);
      expect(prefs.get(PrayerLocationSource.accuracyKey), isNull);
    });

    test(
      'installs from before the source setting keep their meaning',
      () async {
        SharedPreferences.setMockInitialValues({
          'prayer_latitude': 30.0,
          'prayer_longitude': 31.0,
          'prayer_location_label': 'موقع الجهاز',
        });
        prefs = await SharedPreferences.getInstance();
        expect(create().locationSource, PrayerLocationSource.device);

        SharedPreferences.setMockInitialValues({
          'prayer_latitude': 30.0,
          'prayer_longitude': 31.0,
          'prayer_location_label': 'القاهرة، مصر',
        });
        prefs = await SharedPreferences.getInstance();
        expect(create().locationSource, PrayerLocationSource.manual);
      },
    );
  });

  group('automatic refresh of a device location', () {
    Future<PrayerTimesProvider> deviceLocated() async {
      final provider = create();
      await provider.useDeviceLocation();
      repository.calls.clear();
      scheduler.cancels = 0;
      scheduler.scheduled.clear();
      device.requestAccessCalls.clear();
      return provider;
    }

    test('does nothing while the fix is recent', () async {
      final provider = await deviceLocated();
      clock.value = _now.add(const Duration(hours: 1));
      expect(await provider.refreshDeviceLocationIfStale(), isFalse);
      expect(device.requestAccessCalls, isEmpty, reason: 'no GPS request');
    });

    test('a real move recalculates and reschedules once', () async {
      final provider = await deviceLocated();
      clock.value = _now.add(const Duration(hours: 7));
      // Alexandria, about 180 km away.
      device.fix = fakeFix(
        latitude: 31.2,
        longitude: 29.9,
        timestamp: clock.value,
      );

      expect(await provider.refreshDeviceLocationIfStale(), isTrue);
      expect(device.requestAccessCalls, [false], reason: 'never a dialog');
      expect(provider.selectedCoordinates, (latitude: 31.2, longitude: 29.9));
      expect(prefs.getDouble('prayer_latitude'), 31.2);
      expect(scheduler.cancels, 1);
      expect(scheduler.scheduled.single.latitude, 31.2);
      expect(repository.calls.every((c) => c.latitude == 31.2), isTrue);
      expect(provider.locationSource, PrayerLocationSource.device);
    });

    test('a small move only records the check', () async {
      final provider = await deviceLocated();
      clock.value = _now.add(const Duration(hours: 7));
      device.fix = fakeFix(
        latitude: 30.0544, // about 1 km north
        timestamp: clock.value,
      );

      expect(await provider.refreshDeviceLocationIfStale(), isFalse);
      expect(scheduler.cancels, 0);
      expect(repository.calls, isEmpty);
      expect(provider.locationFixedAt, clock.value);
      expect(
        prefs.getInt(PrayerLocationSource.fixedAtKey),
        clock.value.millisecondsSinceEpoch,
      );
    });

    test('a manual location is never refreshed', () async {
      final provider = create();
      await provider.selectLocation(31.2, 29.9, 'الإسكندرية', 5);
      clock.value = _now.add(const Duration(days: 3));
      expect(await provider.refreshDeviceLocationIfStale(), isFalse);
      expect(device.requestAccessCalls, isEmpty);
    });

    test('a failure or a last-known fix keeps the saved location', () async {
      final provider = await deviceLocated();
      clock.value = _now.add(const Duration(hours: 7));
      device.error = const PrayerLocationException('off');
      expect(await provider.refreshDeviceLocationIfStale(), isFalse);

      device.error = null;
      device.fix = fakeFix(
        latitude: 31.2,
        longitude: 29.9,
        source: LocationFixSource.staleCache,
      );
      expect(await provider.refreshDeviceLocationIfStale(), isFalse);
      expect(provider.selectedCoordinates!.latitude, 30.0444);
      expect(scheduler.cancels, 0);
    });

    test('a city chosen while the fix is pending wins', () async {
      final provider = await deviceLocated();
      clock.value = _now.add(const Duration(hours: 7));
      device.pending = Completer<DeviceLocationFix>();

      final refresh = provider.refreshDeviceLocationIfStale();
      await provider.selectLocation(21.4225, 39.8262, 'مكة', 4);
      device.pending!.complete(fakeFix(latitude: 31.2, longitude: 29.9));

      expect(await refresh, isFalse);
      expect(provider.locationLabel, 'مكة');
      expect(provider.locationSource, PrayerLocationSource.manual);
      expect(prefs.getDouble('prayer_latitude'), 21.4225);
    });

    test('concurrent triggers share one lookup', () async {
      final provider = await deviceLocated();
      clock.value = _now.add(const Duration(hours: 7));
      device.pending = Completer<DeviceLocationFix>();
      final first = provider.refreshDeviceLocationIfStale();
      final second = provider.refreshDeviceLocationIfStale();
      device.pending!.complete(
        fakeFix(latitude: 31.2, longitude: 29.9, timestamp: clock.value),
      );
      await Future.wait([first, second]);
      expect(device.requestAccessCalls, hasLength(1));
      expect(scheduler.cancels, 1);
    });
  });
}
