import 'package:sakina_app/features/prayers/domain/prayer_time_adjustments.dart';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/core/services/scheduling_generation.dart';
import 'package:sakina_app/features/prayers/data/services/local_prayer_notification_scheduler.dart';
import 'package:sakina_app/features/prayers/data/services/prayer_replenishment_service.dart';
import 'package:sakina_app/features/prayers/domain/entities/adhan_settings.dart';
import 'package:sakina_app/features/prayers/domain/entities/prayer_times_entity.dart';
import 'package:sakina_app/features/prayers/domain/prayer_calculation_policy.dart';
import 'package:sakina_app/features/prayers/domain/repositories/prayer_times_repository.dart';
import 'package:sakina_app/features/prayers/domain/services/prayer_notification_scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The UI isolate and the WorkManager isolate must never rewrite the same
/// notifications at the same time (audit finding NOTIF-01, task P0-05).

class _Gateway implements PrayerNotificationGateway {
  final days = <DateTime>[];
  var cancels = 0;
  Future<void> Function()? onSchedule;

  @override
  Future<void> cancelAllPrayerNotifications() async => cancels++;

  @override
  Future<void> scheduleAllPrayersForDate({
    required Map<DailyPrayer, DateTime> prayerTimes,
    required AdhanSettings settings,
  }) async {
    final first = prayerTimes.values.first;
    days.add(DateTime(first.year, first.month, first.day));
    await onSchedule?.call();
  }
}

class _Repository implements PrayerTimesRepository {
  final dates = <DateTime>[];
  Object? error;

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
    dates.add(date);
    if (error != null) return Err(UnexpectedFailure(cause: error!));
    return Success(
      PrayerTimesEntity(
        timezone: 'Asia/Riyadh',
        fajr: '05:00',
        dhuhr: '12:00',
        asr: '15:00',
        maghrib: '18:00',
        isha: '20:00',
      ),
    );
  }
}

class _Scheduler extends NoopPrayerNotificationScheduler {
  final dates = <DateTime>[];
  var cancels = 0;
  Future<void> Function()? onSchedule;

  @override
  Future<void> cancelPrayerNotifications() async => cancels++;

  @override
  Future<void> schedulePrayerNotifications({
    required PrayerTimesEntity prayerTimes,
    required DateTime date,
  }) async {
    dates.add(date);
    await onSchedule?.call();
  }
}

const _configured = <String, Object>{
  'prayer_latitude': 24.7,
  'prayer_longitude': 46.7,
  'prayer_method': 4,
  'prayer_timezone': 'Asia/Riyadh',
};

final _today = PrayerTimesEntity(timezone: 'Asia/Riyadh', fajr: '05:00');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 09:00 UTC on 10 Jan 2026 is 12:00 the same day in Riyadh.
  DateTime now() => DateTime.utc(2026, 1, 10, 9);

  group('SchedulingGeneration', () {
    test('starts at 0, ignores a malformed value and increases', () async {
      SharedPreferences.setMockInitialValues({
        SchedulingGeneration.preferenceKey: 'x',
      });
      final prefs = await SharedPreferences.getInstance();
      expect(SchedulingGeneration.read(prefs), 0);
      await SchedulingGeneration.bump(prefs);
      await SchedulingGeneration.bump(prefs);
      expect(SchedulingGeneration.read(prefs), 2);
    });
  });

  group('UI-isolate prayer scheduler', () {
    test('claims the schedule before scheduling and cancelling', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final gateway = _Gateway();
      final generations = <int>[];
      gateway.onSchedule = () async =>
          generations.add(SchedulingGeneration.read(prefs));
      final scheduler = LocalPrayerNotificationScheduler(
        prefs: prefs,
        notificationGateway: gateway,
        claimsSchedule: true,
      );

      await scheduler.schedulePrayerNotifications(
        prayerTimes: _today,
        date: DateTime(2026, 1, 10),
      );
      expect(generations, [1], reason: 'claimed before it wrote');
      await scheduler.cancelPrayerNotifications();
      expect(SchedulingGeneration.read(prefs), 2);
    });

    test('the background scheduler never claims the schedule', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final scheduler = LocalPrayerNotificationScheduler(
        prefs: prefs,
        notificationGateway: _Gateway(),
      );
      await scheduler.schedulePrayerNotifications(
        prayerTimes: _today,
        date: DateTime(2026, 1, 10),
      );
      await scheduler.cancelPrayerNotifications();
      expect(SchedulingGeneration.read(prefs), 0);
    });

    test(
      'fills the rest of the window itself via the follow-up hook',
      () async {
        SharedPreferences.setMockInitialValues(_configured);
        final prefs = await SharedPreferences.getInstance();
        final gateway = _Gateway();
        final repository = _Repository();
        final scheduler = LocalPrayerNotificationScheduler(
          prefs: prefs,
          notificationGateway: gateway,
          claimsSchedule: true,
          onScheduled: () => scheduleRestOfPrayerWindow(
            preferences: prefs,
            repository: repository,
            gateway: gateway,
          ),
        );

        await scheduler.schedulePrayerNotifications(
          prayerTimes: _today,
          date: DateTime(2026, 1, 10),
        );

        // Today by the provider, then the two following days, all here.
        expect(gateway.days, hasLength(3));
        expect(repository.dates, hasLength(2));
        expect(
          repository.dates.first.isAfter(gateway.days.first),
          isTrue,
          reason: 'the follow-up starts at tomorrow, not today',
        );
      },
    );

    test('reports the last scheduled day for the iOS notice', () async {
      SharedPreferences.setMockInitialValues(_configured);
      final prefs = await SharedPreferences.getInstance();
      final gateway = _Gateway();
      DateTime? lastDay;
      await scheduleRestOfPrayerWindow(
        preferences: prefs,
        repository: _Repository(),
        gateway: gateway,
        onWindowScheduled: (day) async => lastDay = day,
      );
      expect(lastDay, isNotNull);
      expect(lastDay, gateway.days.last);
    });

    test('a failing follow-up keeps today and does not throw', () async {
      SharedPreferences.setMockInitialValues(_configured);
      final prefs = await SharedPreferences.getInstance();
      final gateway = _Gateway();
      final repository = _Repository()..error = StateError('broken');
      final scheduler = LocalPrayerNotificationScheduler(
        prefs: prefs,
        notificationGateway: gateway,
        claimsSchedule: true,
        onScheduled: () => scheduleRestOfPrayerWindow(
          preferences: prefs,
          repository: repository,
          gateway: gateway,
        ),
      );

      await scheduler.schedulePrayerNotifications(
        prayerTimes: _today,
        date: DateTime(2026, 1, 10),
      );
      expect(gateway.days, hasLength(1));
      expect(gateway.cancels, 0);
    });
  });

  group('PrayerReplenishmentService ownership options', () {
    test('firstDay 1 schedules tomorrow and the day after only', () async {
      SharedPreferences.setMockInitialValues(_configured);
      final scheduler = _Scheduler();
      await PrayerReplenishmentService(
        preferences: await SharedPreferences.getInstance(),
        repository: _Repository(),
        scheduler: scheduler,
        now: now,
        firstDay: 1,
      ).replenish();
      expect(scheduler.dates, [DateTime(2026, 1, 11), DateTime(2026, 1, 12)]);
    });

    test('the follow-up never cancels when settings are missing', () async {
      SharedPreferences.setMockInitialValues({});
      final scheduler = _Scheduler();
      await PrayerReplenishmentService(
        preferences: await SharedPreferences.getInstance(),
        repository: _Repository(),
        scheduler: scheduler,
        now: now,
        firstDay: 1,
        cancelWhenUnconfigured: false,
      ).replenish();
      expect(scheduler.cancels, 0);
      expect(scheduler.dates, isEmpty);
    });

    test('a superseded background run writes nothing', () async {
      SharedPreferences.setMockInitialValues({
        ..._configured,
        SchedulingGeneration.preferenceKey: 5,
      });
      final scheduler = _Scheduler();
      await PrayerReplenishmentService(
        preferences: await SharedPreferences.getInstance(),
        repository: _Repository(),
        scheduler: scheduler,
        now: now,
        expectedGeneration: 4,
      ).replenish();
      expect(scheduler.dates, isEmpty);
      expect(scheduler.cancels, 0);
    });

    test('a background run stops once the app claims the schedule', () async {
      SharedPreferences.setMockInitialValues(_configured);
      final prefs = await SharedPreferences.getInstance();
      final scheduler = _Scheduler();
      // The app reschedules while the first background day is written.
      scheduler.onSchedule = () => SchedulingGeneration.bump(prefs);
      await PrayerReplenishmentService(
        preferences: prefs,
        repository: _Repository(),
        scheduler: scheduler,
        now: now,
        expectedGeneration: 0,
      ).replenish();
      expect(scheduler.dates, [DateTime(2026, 1, 10)]);
    });
  });

  group('no second scheduling path from the UI isolate', () {
    // Production wiring is static, so guard it at the source level: the UI
    // isolate must not enqueue an immediate background reschedule.
    for (final path in [
      'lib/core/di/service_locator.dart',
      'lib/core/providers/settings_provider.dart',
      'lib/features/prayers/data/services/local_prayer_notification_scheduler.dart',
      'lib/features/prayers/presentation/providers/prayer_times_provider.dart',
    ]) {
      test(path, () {
        final source = File(path).readAsStringSync();
        expect(source, isNot(contains('registerImmediateRescheduleTask(')));
        expect(source, isNot(contains('requestReschedule(')));
      });
    }
  });
}
