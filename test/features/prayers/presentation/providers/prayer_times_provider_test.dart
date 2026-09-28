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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
