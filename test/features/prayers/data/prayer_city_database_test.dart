import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/features/prayers/data/prayer_city_catalog.dart';
import 'package:sakina_app/features/prayers/domain/entities/prayer_times_entity.dart';
import 'package:sakina_app/features/prayers/domain/prayer_calculation_policy.dart';
import 'package:sakina_app/features/prayers/domain/prayer_city.dart';
import 'package:sakina_app/features/prayers/domain/prayer_time_adjustments.dart';
import 'package:sakina_app/features/prayers/domain/repositories/prayer_times_repository.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_times_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class _Repository implements PrayerTimesRepository {
  @override
  Future<Result<PrayerTimesEntity>> getPrayerTimes(
    DateTime date,
    double latitude,
    double longitude, {
    int calculationMethod = PrayerCalculationPolicy.defaultMethod,
    AsrMadhab madhab = AsrMadhab.standard,
    String? timeZone,
    PrayerTimeAdjustments adjustments = PrayerTimeAdjustments.none,
  }) async => Success(
    PrayerTimesEntity(
      fajr: '05:00',
      sunrise: '06:20',
      dhuhr: '12:00',
      asr: '15:00',
      maghrib: '18:00',
      isha: '19:30',
      timezone: timeZone ?? 'Asia/Riyadh',
    ),
  );
}

void main() {
  late List<PrayerCity> bundled;
  late PrayerCityCatalog catalog;

  setUpAll(() {
    tzdata.initializeTimeZones();
    final String raw = File('assets/prayer_cities.json').readAsStringSync();
    bundled = PrayerCityCatalog.parse(raw);
    catalog = PrayerCityCatalog(load: () async => raw);
  });

  group('bundled database', () {
    test('every row is valid and has a known IANA zone', () {
      final Map<String, dynamic> decoded =
          jsonDecode(File('assets/prayer_cities.json').readAsStringSync())
              as Map<String, dynamic>;
      expect(bundled.length, (decoded['cities'] as List).length);
      expect(bundled.length, greaterThan(7000));
      for (final PrayerCity city in bundled) {
        expect(() => tz.getLocation(city.timeZone!), returnsNormally);
        expect(city.countryCode, isNotNull);
      }
    });

    test('contested country codes are not bundled', () {
      expect(bundled.where((c) => c.countryCode == 'IL'), isEmpty);
      expect(bundled.where((c) => c.countryCode == 'EH'), isEmpty);
    });

    test('major cities carry their Arabic names and zones', () {
      PrayerCity byLatin(String name, String country) => bundled.firstWhere(
        (c) => c.englishName == name && c.countryCode == country,
      );
      expect(byLatin('Makkah', 'SA').name, 'مكة المكرمة');
      expect(byLatin('Madinah', 'SA').name, 'المدينة المنورة');
      expect(byLatin('Cairo', 'EG').name, 'القاهرة');
      expect(byLatin('Cairo', 'EG').timeZone, 'Africa/Cairo');
      expect(byLatin('Khartoum', 'SD').name, 'الخرطوم');
      expect(byLatin('Rabat', 'MA').name, 'الرباط');
      expect(byLatin('Casablanca', 'MA').timeZone, 'Africa/Casablanca');
      expect(byLatin('Berlin', 'DE').country, 'ألمانيا');
    });
  });

  group('search', () {
    test('Arabic, unaccented Arabic and Latin queries find the city', () async {
      expect((await catalog.search('القاهرة')).first.englishName, 'Cairo');
      expect(
        (await catalog.search('مكه')).map((c) => c.englishName),
        contains('Makkah'),
      );
      expect((await catalog.search('jeddah')).first.englishName, 'Jeddah');
    });

    test('names starting with the query come before other matches', () async {
      final results = await catalog.search('الرياض');
      expect(results.first.englishName, 'Riyadh');
    });

    test('an empty query lists nothing and results are capped', () async {
      expect(await catalog.search('  '), isEmpty);
      expect(await catalog.search('a', limit: 10), hasLength(10));
    });
  });

  test('schema 1 lists from earlier versions still parse', () {
    final cities = PrayerCityCatalog.parse(
      jsonEncode([
        {
          'name': 'القاهرة',
          'country': 'مصر',
          'englishName': 'Cairo',
          'latitude': 30.06,
          'longitude': 31.25,
          'timezone': 'Africa/Cairo',
        },
      ]),
    );
    expect(cities.single.timeZone, 'Africa/Cairo');
  });

  group('method suggestion', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    PrayerTimesProvider provider() => PrayerTimesProvider(
      repository: _Repository(),
      preferences: prefs,
      nearestCity: catalog.nearest,
    );

    test('suggests the usual method of the country, accepted on tap', () async {
      final p = provider();
      await p.selectLocation(
        21.4225,
        39.8262,
        'مكة',
        PrayerCalculationPolicy.egyptian,
        timeZone: 'Asia/Riyadh',
      );
      await p.updateLocationCountry();
      expect(p.locationCountryCode, 'SA');
      expect(p.suggestedMethod, PrayerCalculationPolicy.ummAlQura);
      expect(
        p.selectedMethod,
        PrayerCalculationPolicy.egyptian,
        reason: 'nothing changes without the user',
      );

      await p.acceptMethodSuggestion();
      expect(p.selectedMethod, PrayerCalculationPolicy.ummAlQura);
      expect(p.suggestedMethod, isNull);
    });

    test('declining hides it for that country, also after restart', () async {
      final p = provider();
      await p.selectLocation(
        21.4225,
        39.8262,
        'مكة',
        PrayerCalculationPolicy.egyptian,
        timeZone: 'Asia/Riyadh',
      );
      await p.updateLocationCountry();
      await p.dismissMethodSuggestion();
      expect(p.suggestedMethod, isNull);

      final restarted = provider();
      await restarted.fetchTodayForCurrentLocation();
      await restarted.updateLocationCountry();
      expect(restarted.locationCountryCode, 'SA');
      expect(restarted.suggestedMethod, isNull);
    });

    test(
      'no suggestion where the method already matches or far from cities',
      () async {
        final p = provider();
        await p.selectLocation(30.0444, 31.2357, 'القاهرة', 5);
        await p.updateLocationCountry();
        expect(p.locationCountryCode, 'EG');
        expect(p.suggestedMethod, isNull);

        await p.selectLocation(0, -30, 'المحيط', 5);
        await p.updateLocationCountry();
        expect(p.locationCountryCode, isNull);
        expect(p.suggestedMethod, isNull);
      },
    );
  });
}
