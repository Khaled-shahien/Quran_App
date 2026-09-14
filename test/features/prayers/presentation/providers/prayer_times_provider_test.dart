import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/prayers/domain/Entities/prayer_times_entity.dart';
import 'package:sakina_app/features/prayers/domain/repositories/prayer_times_repository.dart';
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

void main() {
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
