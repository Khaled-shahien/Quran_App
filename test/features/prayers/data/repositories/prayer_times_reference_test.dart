import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/features/prayers/data/repositories/prayer_times_repository_impl.dart';
import 'package:sakina_app/features/prayers/domain/entities/prayer_times_entity.dart';
import 'package:sakina_app/features/prayers/domain/prayer_calculation_policy.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Reference times from api.aladhan.com (retrieved 2026-11-05) with the same
/// method, Asr school and IANA timezone. Each prayer must match within one
/// minute: the engines round to the minute independently.
class _Reference {
  const _Reference(
    this.place,
    this.date,
    this.latitude,
    this.longitude,
    this.zone,
    this.method,
    this.madhab,
    this.times,
  );
  final String place;
  final DateTime date;
  final double latitude;
  final double longitude;
  final String zone;
  final int method;
  final AsrMadhab madhab;

  /// fajr, sunrise, dhuhr, asr, maghrib, isha
  final List<String> times;
}

const _cairo = (30.0444, 31.2357, 'Africa/Cairo');

final List<_Reference> _references = [
  _Reference(
    'Cairo winter',
    DateTime(2026, 1, 15),
    _cairo.$1,
    _cairo.$2,
    _cairo.$3,
    5,
    AsrMadhab.standard,
    ['05:21', '06:52', '12:04', '14:57', '17:17', '18:39'],
  ),
  _Reference(
    'Cairo equinox',
    DateTime(2026, 3, 20),
    _cairo.$1,
    _cairo.$2,
    _cairo.$3,
    5,
    AsrMadhab.standard,
    ['04:32', '05:59', '12:03', '15:29', '18:06', '19:24'],
  ),
  _Reference(
    'Cairo first day of summer time',
    DateTime(2026, 4, 24),
    _cairo.$1,
    _cairo.$2,
    _cairo.$3,
    5,
    AsrMadhab.standard,
    ['04:46', '06:19', '12:53', '16:29', '19:28', '20:51'],
  ),
  _Reference(
    'Cairo solstice',
    DateTime(2026, 6, 21),
    _cairo.$1,
    _cairo.$2,
    _cairo.$3,
    5,
    AsrMadhab.standard,
    ['04:08', '05:54', '12:57', '16:32', '19:59', '21:33'],
  ),
  _Reference(
    'Cairo after summer time ends',
    DateTime(2026, 10, 30),
    _cairo.$1,
    _cairo.$2,
    _cairo.$3,
    5,
    AsrMadhab.standard,
    ['04:40', '06:07', '11:39', '14:47', '17:10', '18:28'],
  ),
  _Reference(
    'Cairo November',
    DateTime(2026, 11, 5),
    _cairo.$1,
    _cairo.$2,
    _cairo.$3,
    5,
    AsrMadhab.standard,
    ['04:43', '06:12', '11:39', '14:43', '17:05', '18:24'],
  ),
  _Reference(
    'Cairo Hanafi Asr',
    DateTime(2026, 6, 21),
    _cairo.$1,
    _cairo.$2,
    _cairo.$3,
    5,
    AsrMadhab.hanafi,
    ['04:08', '05:54', '12:57', '17:50', '19:59', '21:33'],
  ),
  _Reference(
    'Makkah Umm al-Qura',
    DateTime(2026, 1, 15),
    21.4225,
    39.8262,
    'Asia/Riyadh',
    4,
    AsrMadhab.standard,
    ['05:41', '07:01', '12:30', '15:37', '17:59', '19:29'],
  ),
  _Reference(
    'Istanbul Muslim World League',
    DateTime(2026, 6, 21),
    41.0082,
    28.9784,
    'Europe/Istanbul',
    3,
    AsrMadhab.standard,
    ['03:24', '05:32', '13:06', '17:07', '20:40', '22:38'],
  ),
];

int _minutes(String hhmm) {
  final parts = hhmm.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

List<String?> _times(PrayerTimesEntity e) => [
  e.fajr,
  e.sunrise,
  e.dhuhr,
  e.asr,
  e.maghrib,
  e.isha,
];

void main() {
  setUpAll(tzdata.initializeTimeZones);

  const names = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  for (final ref in _references) {
    test('${ref.place} matches the reference within one minute', () {
      final entity = PrayerTimesRepositoryImpl.calculate(
        date: ref.date,
        latitude: ref.latitude,
        longitude: ref.longitude,
        calculationMethod: ref.method,
        madhab: ref.madhab,
        location: tz.getLocation(ref.zone),
      );

      final actual = _times(entity);
      for (var i = 0; i < names.length; i++) {
        final diff = (_minutes(actual[i]!) - _minutes(ref.times[i])).abs();
        expect(
          diff,
          lessThanOrEqualTo(1),
          reason: '${names[i]}: got ${actual[i]}, reference ${ref.times[i]}',
        );
      }
      expect(entity.timezone, ref.zone);
    });
  }

  group('PrayerTimesRepositoryImpl', () {
    test('works without network and uses the given timezone', () async {
      final repo = PrayerTimesRepositoryImpl(
        deviceTimeZone: () async => fail('device zone must not be used'),
      );
      final result = await repo.getPrayerTimes(
        DateTime(2026, 11, 5),
        _cairo.$1,
        _cairo.$2,
        timeZone: 'Africa/Cairo',
      );
      expect(result.valueOrNull!.dhuhr, isNotNull);
      expect(result.valueOrNull!.hasCompleteData, isTrue);
    });

    test('falls back to the device timezone', () async {
      final repo = PrayerTimesRepositoryImpl(
        deviceTimeZone: () async => 'Asia/Riyadh',
      );
      final result = await repo.getPrayerTimes(
        DateTime(2026, 1, 15),
        21.4225,
        39.8262,
        calculationMethod: PrayerCalculationPolicy.ummAlQura,
      );
      expect(result.valueOrNull!.timezone, 'Asia/Riyadh');
    });

    test('invalid input is a failure, not an exception', () async {
      final repo = PrayerTimesRepositoryImpl(deviceTimeZone: () async => 'UTC');
      final bad = await repo.getPrayerTimes(DateTime(2026), 91, 0);
      final unknownZone = await repo.getPrayerTimes(
        DateTime(2026),
        30,
        31,
        timeZone: 'Mars/Olympus',
      );
      final unknownMethod = await repo.getPrayerTimes(
        DateTime(2026),
        30,
        31,
        calculationMethod: 99,
      );
      expect(bad, isA<Err<PrayerTimesEntity>>());
      expect(unknownZone, isA<Err<PrayerTimesEntity>>());
      expect(unknownMethod, isA<Err<PrayerTimesEntity>>());
    });

    test('high latitude in midsummer still yields all five prayers', () {
      // Tromsø: the sun never sets around the June solstice.
      final entity = PrayerTimesRepositoryImpl.calculate(
        date: DateTime(2026, 6, 21),
        latitude: 69.6496,
        longitude: 18.9560,
        calculationMethod: PrayerCalculationPolicy.muslimWorldLeague,
        madhab: AsrMadhab.standard,
        location: tz.getLocation('Europe/Oslo'),
      );
      expect(entity.hasCompleteData, isTrue);
      for (final t in _times(entity)) {
        expect(t, matches(RegExp(r'^\d\d:\d\d$')));
      }
    });
  });
}
