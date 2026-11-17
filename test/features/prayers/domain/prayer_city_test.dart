import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/prayers/data/prayer_city_catalog.dart';
import 'package:sakina_app/features/prayers/domain/prayer_city.dart';

const _cairo = PrayerCity(
  name: 'القاهرة',
  country: 'مصر',
  englishName: 'Cairo',
  latitude: 30.06263,
  longitude: 31.24967,
  timeZone: 'Africa/Cairo',
);
const _alexandria = PrayerCity(
  name: 'الإسكندرية',
  country: 'مصر',
  englishName: 'Alexandria',
  latitude: 31.20176,
  longitude: 29.91582,
  timeZone: 'Africa/Cairo',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NearestCity', () {
    const cities = [_cairo, _alexandria];

    test('distance matches the known Cairo–Alexandria distance', () {
      final km =
          NearestCity.distanceMeters(
            _cairo.latitude,
            _cairo.longitude,
            _alexandria.latitude,
            _alexandria.longitude,
          ) /
          1000;
      expect(km, closeTo(178, 4));
    });

    test('a position in central Cairo names Cairo', () {
      final match = NearestCity.find(30.0444, 31.2357, cities)!;
      expect(match.city.englishName, 'Cairo');
      expect(match.proximity, CityProximity.inCity);
    });

    test('a nearby town is "near" the city, not in it (Benha)', () {
      final match = NearestCity.find(30.4660, 31.1848, cities)!;
      expect(match.city.englishName, 'Cairo');
      expect(match.proximity, CityProximity.nearCity);
    });

    test('a city that is not listed is never named after a neighbour '
        '(Mansoura, Tanta)', () {
      expect(NearestCity.find(31.0409, 31.3785, cities), isNull);
      expect(NearestCity.find(30.7865, 31.0004, cities), isNull);
    });

    test('invalid coordinates and an empty list find nothing', () {
      expect(NearestCity.find(double.nan, 31, cities), isNull);
      expect(NearestCity.find(30, 200, cities), isNull);
      expect(NearestCity.find(30.0444, 31.2357, const []), isNull);
    });
  });

  group('PrayerCityCatalog', () {
    test('skips malformed rows instead of failing', () async {
      final catalog = PrayerCityCatalog(
        load: () async => jsonEncode([
          {
            'name': 'القاهرة',
            'country': 'مصر',
            'englishName': 'Cairo',
            'latitude': 30.06,
            'longitude': 31.25,
            'timezone': 'Africa/Cairo',
          },
          {'name': 'bad', 'country': 'x', 'latitude': 200, 'longitude': 0},
          {'country': 'missing name', 'latitude': 1, 'longitude': 1},
          'not a map',
        ]),
      );
      final cities = await catalog.cities();
      expect(cities, hasLength(1));
      expect(cities.single.timeZone, 'Africa/Cairo');
    });

    test('a failed read gives an empty list and is retried', () async {
      var calls = 0;
      final catalog = PrayerCityCatalog(
        load: () async {
          calls++;
          if (calls == 1) throw StateError('asset missing');
          return '[]';
        },
      );
      expect(await catalog.cities(), isEmpty);
      expect(await catalog.cities(), isEmpty);
      expect(calls, 2);
      expect(await catalog.cities(), isEmpty);
      expect(calls, 2, reason: 'a good read is kept');
    });

    test('the bundled list loads with valid coordinates and zones', () async {
      final cities = await PrayerCityCatalog().cities();
      expect(cities, isNotEmpty);
      expect(cities.map((c) => c.englishName), contains('Cairo'));
      for (final city in cities) {
        expect(city.timeZone, isNotNull, reason: city.englishName);
      }
    });
  });
}
