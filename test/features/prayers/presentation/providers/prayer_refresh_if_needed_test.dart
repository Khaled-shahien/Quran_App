import 'package:sakina_app/features/prayers/domain/prayer_calculation_policy.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/prayers/domain/entities/prayer_times_entity.dart';
import 'package:sakina_app/features/prayers/domain/repositories/prayer_times_repository.dart';
import 'package:sakina_app/features/prayers/domain/services/prayer_notification_scheduler.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_times_provider.dart';

class _CountingRepository implements PrayerTimesRepository {
  int calls = 0;
  bool stale = false;

  @override
  Future<Result<PrayerTimesEntity>> getPrayerTimes(
    DateTime date,
    double latitude,
    double longitude, {
    int calculationMethod = 3,
    AsrMadhab madhab = AsrMadhab.standard,
    String? timeZone,
  }) => Result.guard(
    () => _legacyGetPrayerTimes(
      date,
      latitude,
      longitude,
      calculationMethod: calculationMethod,
    ),
    onError: (error, _) => UnexpectedFailure(cause: error),
  );

  Future<PrayerTimesEntity> _legacyGetPrayerTimes(
    DateTime date,
    double latitude,
    double longitude, {
    int calculationMethod = 3,
  }) async {
    calls++;
    return PrayerTimesEntity(
      fajr: '05:00',
      dhuhr: '12:00',
      asr: '15:00',
      maghrib: '18:00',
      isha: '19:30',
      timezone: 'Africa/Cairo',
      isStale: stale,
    );
  }
}

class _CountingScheduler extends NoopPrayerNotificationScheduler {
  int schedules = 0;

  @override
  Future<void> schedulePrayerNotifications({
    required PrayerTimesEntity prayerTimes,
    required DateTime date,
  }) async {
    schedules++;
  }
}

void main() {
  late _CountingRepository repository;
  late _CountingScheduler scheduler;
  late PrayerTimesProvider provider;

  setUp(() {
    repository = _CountingRepository();
    scheduler = _CountingScheduler();
    provider = PrayerTimesProvider(
      repository: repository,
      notificationScheduler: scheduler,
      locationService: const FixedPrayerLocationService(
        latitude: 30,
        longitude: 31,
      ),
    );
  });
  tearDown(() => provider.dispose());

  test(
    'fresh timings for today cause no fetch or rescheduling on resume',
    () async {
      await provider.fetchTodayForCurrentLocation();
      final fetches = repository.calls;
      final schedules = scheduler.schedules;

      await provider.refreshIfNeeded();

      expect(repository.calls, fetches);
      expect(scheduler.schedules, schedules);
      expect(provider.isLoading, isFalse);
      expect(provider.hasData, isTrue);
    },
  );

  test('missing timings are fetched on resume', () async {
    await provider.refreshIfNeeded();
    expect(repository.calls, 1);
    expect(provider.hasData, isTrue);
  });

  test('stale timings are fetched again on resume', () async {
    repository.stale = true;
    await provider.fetchTodayForCurrentLocation();
    final fetches = repository.calls;
    await provider.refreshIfNeeded();
    expect(repository.calls, greaterThan(fetches));
  });

  test('explicit refresh still reschedules', () async {
    await provider.fetchTodayForCurrentLocation();
    final schedules = scheduler.schedules;
    await provider.refresh();
    expect(scheduler.schedules, greaterThan(schedules));
  });
}
