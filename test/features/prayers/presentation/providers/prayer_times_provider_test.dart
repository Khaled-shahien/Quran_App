import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/prayers/domain/Entities/prayer_times_entity.dart';
import 'package:sakina_app/features/prayers/domain/repositories/prayer_times_repository.dart';
import 'package:sakina_app/features/prayers/domain/services/prayer_notification_scheduler.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_times_provider.dart';

class FakePrayerTimesRepository implements PrayerTimesRepository {
  DateTime? lastDate;
  double? lastLatitude;
  double? lastLongitude;
  int? lastCalculationMethod;

  @override
  Future<PrayerTimesEntity> getPrayerTimes(
    DateTime date,
    double latitude,
    double longitude, {
    int calculationMethod = 3,
  }) async {
    lastDate = date;
    lastLatitude = latitude;
    lastLongitude = longitude;
    lastCalculationMethod = calculationMethod;

    return PrayerTimesEntity(
      fajr: '05:00',
      sunrise: '06:20',
      dhuhr: '12:15',
      asr: '15:40',
      maghrib: '18:30',
      isha: '19:45',
      latitude: latitude,
      longitude: longitude,
      calculationMethod: calculationMethod,
    );
  }
}

class FakePrayerTimesClock implements PrayerTimesClock {
  FakePrayerTimesClock(this._now);

  final DateTime _now;

  @override
  DateTime now() => _now;
}

class FakePrayerLocationService implements PrayerLocationService {
  FakePrayerLocationService({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  Future<Coordinates> getCurrentCoordinates() async {
    return (latitude: latitude, longitude: longitude);
  }
}

class PendingPrayerLocationService implements PrayerLocationService {
  final result = Completer<Coordinates>();

  @override
  Future<Coordinates> getCurrentCoordinates() => result.future;
}

class PendingCancellationScheduler extends NoopPrayerNotificationScheduler {
  final cancellations = <Completer<void>>[];

  @override
  Future<void> cancelPrayerNotifications() {
    final completion = Completer<void>();
    cancellations.add(completion);
    return completion.future;
  }
}

class FailingPreferences implements SharedPreferences {
  bool fail = true;
  bool returnFalse = false;
  final values = <String, Object>{};

  @override
  Object? get(String key) => values[key];
  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }

  @override
  double? getDouble(String key) => null;
  @override
  String? getString(String key) => null;
  @override
  int? getInt(String key) => null;
  @override
  Future<bool> setDouble(String key, double value) async {
    values[key] = value;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    values[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    if (fail) {
      if (returnFalse) return false;
      throw StateError('Storage unavailable');
    }
    values[key] = value;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('cancellation failure retains data and permits retry', () async {
    final scheduler = PendingCancellationScheduler();
    final repository = FakePrayerTimesRepository();
    final provider = PrayerTimesProvider(
      repository: repository,
      notificationScheduler: scheduler,
    );
    addTearDown(provider.dispose);
    await provider.fetchPrayerTimes(DateTime(2026, 9, 28), 30, 31);
    final previous = provider.prayerTimes;
    var notifications = 0;
    provider.addListener(() => notifications++);
    final save = provider.selectLocation(21.4, 39.8, 'مكة', 4);
    scheduler.cancellations.single.completeError(StateError('cancel failed'));
    await save;
    expect(provider.prayerTimes, same(previous));
    expect(provider.selectedCoordinates, (latitude: 30.0, longitude: 31.0));
    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, contains('حاول مرة أخرى'));
    expect(repository.lastLatitude, 30);
    expect(notifications, 2);
    final retry = provider.selectLocation(21.4, 39.8, 'مكة', 4);
    scheduler.cancellations.last.complete();
    await retry;
    expect(provider.hasError, isFalse);
    expect(repository.lastLatitude, 21.4);
  });

  for (final returnFalse in [false, true]) {
    test(
      'storage failure (false=$returnFalse) retains state and retries',
      () async {
        final preferences = FailingPreferences()..fail = false;
        final repository = FakePrayerTimesRepository();
        final provider = PrayerTimesProvider(
          repository: repository,
          preferences: preferences,
        );
        addTearDown(provider.dispose);
        await provider.selectLocation(30, 31, 'القاهرة', 5);
        final previous = provider.prayerTimes;
        preferences.fail = true;
        preferences.returnFalse = returnFalse;
        await provider.selectLocation(21.4, 39.8, 'مكة', 4);
        expect(provider.prayerTimes, same(previous));
        expect(provider.locationLabel, 'القاهرة');
        expect(preferences.values['prayer_latitude'], 30);
        expect(preferences.values['prayer_longitude'], 31);
        expect(preferences.values['prayer_location_label'], 'القاهرة');
        expect(provider.selectedMethod, 5);
        expect(provider.selectedCoordinates, (latitude: 30.0, longitude: 31.0));
        expect(provider.isLoading, isFalse);
        expect(provider.errorMessage, contains('تعذر حفظ موقع الصلاة'));
        expect(repository.lastLatitude, 30);
        preferences.fail = false;
        await provider.selectLocation(21.4, 39.8, 'مكة', 4);
        expect(provider.hasError, isFalse);
        expect(provider.locationLabel, 'مكة');
        expect(repository.lastLatitude, 21.4);
      },
    );
  }

  test('late cancellation failure cannot overwrite newer success', () async {
    final scheduler = PendingCancellationScheduler();
    final provider = PrayerTimesProvider(
      repository: FakePrayerTimesRepository(),
      notificationScheduler: scheduler,
    );
    addTearDown(provider.dispose);
    final older = provider.selectLocation(30, 31, 'القاهرة', 5);
    final newer = provider.selectLocation(21.4, 39.8, 'مكة', 4);
    scheduler.cancellations.last.complete();
    await newer;
    scheduler.cancellations.first.completeError(StateError('late failure'));
    await older;
    expect(provider.locationLabel, 'مكة');
    expect(provider.hasError, isFalse);
    expect(provider.hasData, isTrue);
    expect(provider.isLoading, isFalse);
  });
  test('late GPS result cannot override manual city selection', () async {
    final location = PendingPrayerLocationService();
    final provider = PrayerTimesProvider(
      repository: FakePrayerTimesRepository(),
      deviceLocationService: location,
    );
    addTearDown(provider.dispose);
    final gps = provider.useDeviceLocation();
    expect(provider.isLoading, isTrue);
    await provider.selectLocation(21.4, 39.8, 'Makkah', 4);
    location.result.complete((latitude: 30.0, longitude: 31.0));
    await gps;
    expect(provider.locationLabel, 'Makkah');
    expect(provider.isLoading, isFalse);
  });
  test(
    'GPS denial leaves manual fallback available and clears loading',
    () async {
      final location = PendingPrayerLocationService();
      final provider = PrayerTimesProvider(
        repository: FakePrayerTimesRepository(),
        deviceLocationService: location,
      );
      addTearDown(provider.dispose);
      final gps = provider.useDeviceLocation();
      location.result.completeError(
        const PrayerLocationException('Choose a city'),
      );
      await gps;
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, 'Choose a city');
      await provider.selectLocation(21.4, 39.8, 'Makkah', 4);
      expect(provider.hasData, isTrue);
      expect(provider.hasError, isFalse);
    },
  );
  test('late location lookup cannot replace a manual selection', () async {
    final location = PendingPrayerLocationService();
    final repository = FakePrayerTimesRepository();
    final provider = PrayerTimesProvider(
      repository: repository,
      locationService: location,
    );
    addTearDown(provider.dispose);

    final lookup = provider.fetchTodayForCurrentLocation();
    await provider.selectLocation(21.4, 39.8, 'Makkah', 4);
    location.result.complete((latitude: 30.0, longitude: 31.0));
    await lookup;

    expect(repository.lastLatitude, 21.4);
    expect(provider.selectedCoordinates, (latitude: 21.4, longitude: 39.8));
    expect(provider.locationLabel, 'Makkah');
  });

  test('late lookup failure cannot replace successful state', () async {
    final location = PendingPrayerLocationService();
    final provider = PrayerTimesProvider(
      repository: FakePrayerTimesRepository(),
      locationService: location,
    );
    addTearDown(provider.dispose);

    final lookup = provider.fetchTodayForCurrentLocation();
    await provider.selectLocation(21.4, 39.8, 'Makkah', 4);
    location.result.completeError(StateError('Location unavailable'));
    await lookup;

    expect(provider.hasData, isTrue);
    expect(provider.hasError, isFalse);
  });

  test(
    'latest manual selection wins when cancellation finishes late',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final scheduler = PendingCancellationScheduler();
      final repository = FakePrayerTimesRepository();
      final provider = PrayerTimesProvider(
        repository: repository,
        preferences: prefs,
        notificationScheduler: scheduler,
      );
      addTearDown(provider.dispose);

      final older = provider.selectLocation(30, 31, 'Cairo', 5);
      final newer = provider.selectLocation(21.4, 39.8, 'Makkah', 4);
      scheduler.cancellations[1].complete();
      await newer;
      scheduler.cancellations[0].complete();
      await older;

      expect(repository.lastLatitude, 21.4);
      expect(provider.locationLabel, 'Makkah');
      expect(prefs.getDouble('prayer_latitude'), 21.4);
      expect(prefs.getInt('prayer_method'), 4);
    },
  );

  test(
    'lookup completion after disposal does not fetch prayer times',
    () async {
      final location = PendingPrayerLocationService();
      final repository = FakePrayerTimesRepository();
      final provider = PrayerTimesProvider(
        repository: repository,
        locationService: location,
      );
      final lookup = provider.fetchTodayForCurrentLocation();
      provider.dispose();
      location.result.complete((latitude: 30.0, longitude: 31.0));
      await lookup;

      expect(repository.lastLatitude, isNull);
    },
  );
  test('unconfigured location never silently requests Cairo', () async {
    final repository = FakePrayerTimesRepository();
    final provider = PrayerTimesProvider(repository: repository);
    await provider.fetchTodayForCurrentLocation();
    expect(repository.lastLatitude, isNull);
    expect(provider.hasError, isTrue);
  });
  test('manual coordinates and calculation method survive restart', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = FakePrayerTimesRepository();
    final first = PrayerTimesProvider(
      repository: repository,
      preferences: prefs,
    );
    await first.selectLocation(21.4, 39.8, 'مكة', 4);
    final restored = PrayerTimesProvider(
      repository: repository,
      preferences: prefs,
    );
    await restored.fetchTodayForCurrentLocation();
    expect(repository.lastLatitude, 21.4);
    expect(repository.lastLongitude, 39.8);
    expect(repository.lastCalculationMethod, 4);
    expect(restored.locationLabel, 'مكة');
    await expectLater(
      restored.selectLocation(double.nan, 0, '', 4),
      throwsArgumentError,
    );
    await expectLater(
      restored.selectLocation(91, 0, '', 4),
      throwsArgumentError,
    );
  });
  test('PrayerTimesProvider fetches and exposes main prayer times', () async {
    final repository = FakePrayerTimesRepository();
    final provider = PrayerTimesProvider(repository: repository);

    await provider.fetchPrayerTimes(DateTime(2026, 3, 23), 30.0444, 31.2357);

    expect(provider.hasData, isTrue);
    expect(provider.hasError, isFalse);
    expect(provider.getMainPrayerTimes()['Fajr'], isNot('N/A'));
    expect(provider.getMainPrayerTimes()['Maghrib'], isNot('N/A'));
    expect(repository.lastLatitude, 30.0444);
    expect(repository.lastLongitude, 31.2357);
  });

  test(
    'PrayerTimesProvider fetchTodayForCurrentLocation uses injected services',
    () async {
      final repository = FakePrayerTimesRepository();
      final clock = FakePrayerTimesClock(DateTime(2026, 3, 24));
      final location = FakePrayerLocationService(
        latitude: 21.3891,
        longitude: 39.8579,
      );

      final provider = PrayerTimesProvider(
        repository: repository,
        clock: clock,
        locationService: location,
      );

      await provider.fetchTodayForCurrentLocation(calculationMethod: 4);

      expect(repository.lastDate, DateTime(2026, 3, 24));
      expect(repository.lastLatitude, closeTo(21.3891, 0.0001));
      expect(repository.lastLongitude, closeTo(39.8579, 0.0001));
      expect(repository.lastCalculationMethod, 4);
    },
  );

  test('PrayerTimesProvider refresh uses injected clock date', () async {
    final repository = FakePrayerTimesRepository();
    final clock = FakePrayerTimesClock(DateTime(2026, 4, 1));
    final provider = PrayerTimesProvider(repository: repository, clock: clock);

    await provider.fetchPrayerTimes(DateTime(2026, 3, 20), 30.0, 31.0);
    await provider.refresh();

    expect(repository.lastDate, DateTime(2026, 4, 1));
  });
}
