import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina_app/features/prayers/data/services/prayer_replenishment_service.dart';
import 'package:sakina_app/features/prayers/domain/Entities/prayer_times_entity.dart';
import 'package:sakina_app/features/prayers/domain/prayer_notification_ids.dart';
import 'package:sakina_app/features/prayers/domain/prayer_time_zone.dart';
import 'package:sakina_app/features/prayers/domain/repositories/prayer_times_repository.dart';
import 'package:sakina_app/features/prayers/domain/services/prayer_notification_scheduler.dart';

class Repository implements PrayerTimesRepository {
  final dates = <DateTime>[];
  final methods = <int>[];
  String? zone = 'Asia/Riyadh';
  bool incomplete = false;
  Future<void> Function()? beforeResponse;

  @override
  Future<PrayerTimesEntity> getPrayerTimes(
    DateTime date,
    double latitude,
    double longitude, {
    int calculationMethod = 5,
  }) async {
    dates.add(date);
    methods.add(calculationMethod);
    expect(latitude, 24.7);
    expect(longitude, 46.7);
    await beforeResponse?.call();
    return PrayerTimesEntity(
      timezone: zone,
      fajr: '05:00',
      dhuhr: '12:00',
      asr: '15:00',
      maghrib: '18:00',
      isha: incomplete ? null : '20:00',
    );
  }
}

class Scheduler extends NoopPrayerNotificationScheduler {
  final dates = <DateTime>[];
  var cancels = 0;
  @override
  Future<void> cancelPrayerNotifications() async => cancels++;
  @override
  Future<void> schedulePrayerNotifications({
    required PrayerTimesEntity prayerTimes,
    required DateTime date,
  }) async => dates.add(date);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late Repository repository;
  late Scheduler scheduler;
  late PrayerReplenishmentService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'prayer_latitude': 24.7,
      'prayer_longitude': 46.7,
      'prayer_method': 4,
    });
    prefs = await SharedPreferences.getInstance();
    repository = Repository();
    scheduler = Scheduler();
    service = PrayerReplenishmentService(
      preferences: prefs,
      repository: repository,
      scheduler: scheduler,
      now: () => DateTime.utc(2026, 12, 31, 22),
    );
  });

  test(
    'corrects location date and replenishes three actual calendar days',
    () async {
      await service.replenish();
      expect(repository.dates, [
        DateTime(2026, 12, 31),
        DateTime(2027, 1, 1),
        DateTime(2027, 1, 2),
        DateTime(2027, 1, 3),
      ]);
      expect(scheduler.dates, repository.dates.skip(1).toList());
      expect(repository.methods, everyElement(4));
      expect(scheduler.cancels, 0);
    },
  );

  test('disabled reminders cancel without any network request', () async {
    await prefs.setBool('prayer_notifications_enabled', false);
    await service.replenish();
    expect(repository.dates, isEmpty);
    expect(scheduler.cancels, 1);
  });

  test(
    'missing or invalid location never falls back to a default city',
    () async {
      await prefs.remove('prayer_latitude');
      await service.replenish();
      await prefs.setDouble('prayer_latitude', 100);
      await service.replenish();
      expect(repository.dates, isEmpty);
      expect(scheduler.cancels, 2);
    },
  );

  test(
    'failed fetch preserves pending schedules and remains retryable',
    () async {
      repository.beforeResponse = () async => throw StateError('offline');
      await expectLater(service.replenish(), throwsStateError);
      expect(scheduler.cancels, 0);
      expect(scheduler.dates, isEmpty);
      repository.beforeResponse = null;
      await service.replenish();
      expect(scheduler.dates, hasLength(3));
    },
  );

  test(
    'rejects missing timezone instead of scheduling in device time',
    () async {
      repository.zone = null;
      await expectLater(service.replenish(), throwsStateError);
      expect(scheduler.dates, isEmpty);
    },
  );

  test('incomplete response cannot clear previously queued days', () async {
    repository.incomplete = true;
    await expectLater(service.replenish(), throwsStateError);
    expect(scheduler.cancels, 0);
    expect(scheduler.dates, isEmpty);
  });

  test(
    'settings changed during network request discard obsolete results',
    () async {
      final started = Completer<void>();
      final finish = Completer<void>();
      repository.beforeResponse = () async {
        if (!started.isCompleted) started.complete();
        await finish.future;
      };
      final run = service.replenish();
      await started.future;
      await prefs.setInt('prayer_method', 3);
      finish.complete();
      await run;
      expect(scheduler.dates, isEmpty);
    },
  );

  test(
    'day slots are distinct across week/year rollover and fully cancellable',
    () {
      final ids = <int>{};
      for (var day = 0; day < 7; day++) {
        for (var prayer = 2001; prayer <= 2005; prayer++) {
          ids.add(prayerNotificationId(prayer, DateTime(2026, 12, 31 + day)));
        }
      }
      expect(ids, hasLength(35));
      expect(allPrayerNotificationIds().toSet(), containsAll(ids));
      expect(
        allPrayerNotificationIds(),
        containsAll([2001, 2002, 2003, 2004, 2005]),
      );
    },
  );

  test('calendar dates retain local prayer hour across DST', () {
    final before = prayerInstant(DateTime(2026, 3, 28), 5, 0, 'Europe/London');
    final after = prayerInstant(DateTime(2026, 3, 29), 5, 0, 'Europe/London');
    expect(after.difference(before), const Duration(hours: 23));
    expect(
      prayerNotificationId(2001, before),
      isNot(prayerNotificationId(2001, after)),
    );
  });
}
