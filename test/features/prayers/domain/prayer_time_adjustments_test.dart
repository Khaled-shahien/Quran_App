import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/prayers/data/repositories/prayer_times_repository_impl.dart';
import 'package:sakina_app/features/prayers/domain/entities/prayer_times_entity.dart';
import 'package:sakina_app/features/prayers/domain/prayer_calculation_policy.dart';
import 'package:sakina_app/features/prayers/domain/prayer_time_adjustments.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

int _minutes(String? hhmm) {
  final parts = hhmm!.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

PrayerTimesEntity _calc({
  required DateTime date,
  int method = PrayerCalculationPolicy.egyptian,
  PrayerTimeAdjustments adjustments = PrayerTimeAdjustments.none,
  double latitude = 30.0444,
  double longitude = 31.2357,
  String zone = 'Africa/Cairo',
}) => PrayerTimesRepositoryImpl.calculate(
  date: date,
  latitude: latitude,
  longitude: longitude,
  calculationMethod: method,
  madhab: AsrMadhab.standard,
  location: tz.getLocation(zone),
  adjustments: adjustments,
);

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('stored adjustments', () {
    test('round-trip as one value and clamp to the limit', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final value = PrayerTimeAdjustments.none
          .withMinutes(PrayerTimeKind.fajr, 2)
          .withMinutes(PrayerTimeKind.isha, -99);
      expect(value.of(PrayerTimeKind.isha), -PrayerTimeAdjustments.limit);
      await value.write(prefs);
      expect(PrayerTimeAdjustments.read(prefs), value);
      await PrayerTimeAdjustments.none.write(prefs);
      expect(prefs.containsKey(PrayerTimeAdjustments.preferenceKey), isFalse);
    });

    test('damaged or out-of-range values are ignored', () async {
      SharedPreferences.setMockInitialValues({
        PrayerTimeAdjustments.preferenceKey:
            '{"fajr": 99, "dhuhr": "x", "asr": 4, "unknown": 1}',
      });
      final prefs = await SharedPreferences.getInstance();
      final read = PrayerTimeAdjustments.read(prefs);
      expect(read.of(PrayerTimeKind.fajr), 0);
      expect(read.of(PrayerTimeKind.dhuhr), 0);
      expect(read.of(PrayerTimeKind.asr), 4);

      SharedPreferences.setMockInitialValues({
        PrayerTimeAdjustments.preferenceKey: 'not json',
      });
      expect(
        PrayerTimeAdjustments.read(await SharedPreferences.getInstance()),
        PrayerTimeAdjustments.none,
      );
    });
  });

  group('calculation', () {
    test('each time moves by exactly its adjustment', () {
      final date = DateTime(2026, 11, 18);
      final base = _calc(date: date);
      final shifted = _calc(
        date: date,
        adjustments: const PrayerTimeAdjustments({
          PrayerTimeKind.fajr: 2,
          PrayerTimeKind.sunrise: -1,
          PrayerTimeKind.dhuhr: 3,
          PrayerTimeKind.asr: -4,
          PrayerTimeKind.maghrib: 5,
          PrayerTimeKind.isha: -6,
        }),
      );
      expect(_minutes(shifted.fajr) - _minutes(base.fajr), 2);
      expect(_minutes(shifted.sunrise) - _minutes(base.sunrise), -1);
      expect(_minutes(shifted.dhuhr) - _minutes(base.dhuhr), 3);
      expect(_minutes(shifted.asr) - _minutes(base.asr), -4);
      expect(_minutes(shifted.maghrib) - _minutes(base.maghrib), 5);
      expect(_minutes(shifted.isha) - _minutes(base.isha), -6);
    });

    test('every offered method calculates a full day', () {
      for (final method in PrayerCalculationPolicy.methods.keys) {
        final e = _calc(date: DateTime(2026, 6, 21), method: method);
        expect(e.hasCompleteData, isTrue, reason: 'method $method');
      }
    });

    test('Umm al-Qura: Isha 120 minutes after Maghrib in Ramadan, '
        '90 otherwise', () {
      PrayerTimesEntity mecca(DateTime date) => _calc(
        date: date,
        method: PrayerCalculationPolicy.ummAlQura,
        latitude: 21.4225,
        longitude: 39.8262,
        zone: 'Asia/Riyadh',
      );
      final ramadan = DateTime(2026, 3, 1);
      final shawwal = DateTime(2026, 4, 15);
      expect(PrayerTimesRepositoryImpl.isRamadan(ramadan), isTrue);
      expect(PrayerTimesRepositoryImpl.isRamadan(shawwal), isFalse);
      final inRamadan = mecca(ramadan);
      final after = mecca(shawwal);
      expect(_minutes(inRamadan.isha) - _minutes(inRamadan.maghrib), 120);
      expect(_minutes(after.isha) - _minutes(after.maghrib), 90);
    });

    test('other methods ignore Ramadan', () {
      final ramadan = _calc(date: DateTime(2026, 3, 1));
      final params = PrayerTimesRepositoryImpl.parametersFor(
        PrayerCalculationPolicy.egyptian,
        date: DateTime(2026, 3, 1),
      );
      expect(params.ishaInterval ?? 0, 0);
      expect(ramadan.hasCompleteData, isTrue);
    });
  });

  test('country suggestions point only at offered methods', () {
    for (final entry in PrayerCalculationPolicy.recommendedByCountry.entries) {
      expect(
        PrayerCalculationPolicy.methods.containsKey(entry.value),
        isTrue,
        reason: entry.key,
      );
    }
    expect(PrayerCalculationPolicy.recommendedFor('EG'), 5);
    expect(PrayerCalculationPolicy.recommendedFor('SA'), 4);
    expect(PrayerCalculationPolicy.recommendedFor('XX'), isNull);
    expect(PrayerCalculationPolicy.recommendedFor(null), isNull);
  });
}
