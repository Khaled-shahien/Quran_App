import 'package:flutter_test/flutter_test.dart';

import 'package:sakina_app/features/prayers/domain/Entities/prayer_times_entity.dart';

void main() {
  test('PrayerTimesEntity returns main prayers and complete data flag', () {
    final entity = PrayerTimesEntity(
      fajr: '05:12',
      sunrise: '06:30',
      dhuhr: '12:10',
      asr: '15:20',
      maghrib: '18:05',
      isha: '19:25',
    );

    expect(entity.getMainPrayerTimes()['Fajr'], '05:12');
    expect(entity.getMainPrayerTimes()['Isha'], '19:25');
    expect(entity.hasCompleteData, isTrue);
  });

  test('PrayerTimesEntity formats times to Arabic 12-hour format', () {
    final entity = PrayerTimesEntity(
      fajr: '05:12 (EEST)',
      sunrise: '06:30',
      dhuhr: '12:10',
      asr: '15:20',
      maghrib: '18:05',
      isha: '00:15',
    );

    final formatted = entity.getFormattedPrayerTimes();

    expect(formatted['Fajr'], '05:12 ص');
    expect(formatted['Dhuhr'], '12:10 م');
    expect(formatted['Asr'], '03:20 م');
    expect(formatted['Isha'], '12:15 ص');
  });

  test('PrayerTimesEntity handles missing and invalid values safely', () {
    final entity = PrayerTimesEntity(
      fajr: null,
      sunrise: '',
      dhuhr: 'bad-value',
      asr: null,
      maghrib: null,
      isha: null,
    );

    final formatted = entity.getFormattedPrayerTimes();

    expect(entity.hasCompleteData, isFalse);
    expect(formatted['Fajr'], 'N/A');
    expect(formatted['Sunrise'], 'N/A');
    expect(formatted['Dhuhr'], 'bad-value');
  });

  test('PrayerTimesEntity supports equality, hashCode and toString', () {
    final a = PrayerTimesEntity(
      fajr: '05:10',
      sunrise: '06:20',
      dhuhr: '12:05',
      asr: '15:15',
      maghrib: '18:00',
      isha: '19:10',
    );

    final b = PrayerTimesEntity(
      fajr: '05:10',
      sunrise: '06:20',
      dhuhr: '12:05',
      asr: '15:15',
      maghrib: '18:00',
      isha: '19:10',
    );

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
    expect(a.toString(), contains('PrayerTimesEntity(fajr: 05:10'));
  });

  test('PrayerTimesEntity keeps malformed time token unchanged', () {
    final entity = PrayerTimesEntity(
      fajr: 'bad',
      sunrise: '06',
      dhuhr: '12:01',
      asr: '15:30',
      maghrib: '18:10',
      isha: '19:20',
    );

    final formatted = entity.getFormattedPrayerTimes();

    expect(formatted['Fajr'], 'bad');
    expect(formatted['Sunrise'], '06');
  });
}
