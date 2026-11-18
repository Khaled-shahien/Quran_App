import 'dart:convert';

import 'package:flutter/services.dart';

import '../../quran/domain/services/quran_search.dart';
import '../domain/prayer_city.dart';

/// The bundled city list, read once and kept for the app's lifetime.
///
/// `assets/prayer_cities.json` (schema 2) is built from GeoNames
/// (CC BY 4.0) by `tool/build_prayer_cities.py`: every city of 15,000+
/// people in the Arab world and every city of 100,000+ elsewhere, with
/// its IANA zone. A plain list of city objects (schema 1) is still read.
class PrayerCityCatalog {
  PrayerCityCatalog({Future<String> Function()? load})
    : _load =
          load ?? (() => rootBundle.loadString('assets/prayer_cities.json'));

  static final PrayerCityCatalog bundled = PrayerCityCatalog();

  final Future<String> Function() _load;
  List<PrayerCity>? _cities;
  List<String>? _searchKeys;

  /// Empty when the asset cannot be read (retried on the next call);
  /// manual coordinates stay usable.
  Future<List<PrayerCity>> cities() async {
    final cached = _cities;
    if (cached != null) return cached;
    try {
      final List<PrayerCity> parsed = parse(await _load());
      _searchKeys = null;
      return _cities = parsed;
    } catch (_) {
      return const [];
    }
  }

  /// Decodes either schema; rows that fail validation are skipped.
  static List<PrayerCity> parse(String raw) {
    final Object? decoded = jsonDecode(raw);
    if (decoded is List) {
      return List.unmodifiable(
        decoded
            .whereType<Map<String, dynamic>>()
            .map(PrayerCity.fromJson)
            .whereType<PrayerCity>(),
      );
    }
    if (decoded is! Map<String, dynamic>) return const [];
    final Map<String, dynamic> countries =
        (decoded['countries'] as Map<String, dynamic>?) ?? const {};
    final List<dynamic> zones =
        (decoded['zones'] as List<dynamic>?) ?? const [];
    final List<dynamic> rows =
        (decoded['cities'] as List<dynamic>?) ?? const [];
    return List.unmodifiable(
      rows
          .whereType<List<dynamic>>()
          .map((row) => PrayerCity.fromRow(row, countries, zones))
          .whereType<PrayerCity>(),
    );
  }

  /// Cities whose Arabic name, Latin name or country contains [query]
  /// (Arabic-normalised, case-insensitive), largest first, at most [limit].
  Future<List<PrayerCity>> search(String query, {int limit = 40}) async {
    final List<PrayerCity> all = await cities();
    final String needle = _normalize(query.trim());
    if (needle.isEmpty) return const [];
    final List<String> keys = _searchKeys ??= [
      for (final PrayerCity c in all)
        _normalize('${c.name} ${c.englishName} ${c.country}'),
    ];
    final List<({PrayerCity city, bool prefix})> hits = [];
    for (int i = 0; i < all.length; i++) {
      final int at = keys[i].indexOf(needle);
      if (at < 0) continue;
      hits.add((city: all[i], prefix: at == 0));
    }
    // Names that start with the query first, then by population.
    hits.sort((a, b) {
      if (a.prefix != b.prefix) return a.prefix ? -1 : 1;
      return b.city.population.compareTo(a.city.population);
    });
    return [for (final hit in hits.take(limit)) hit.city];
  }

  /// Like the Quran search, plus taa marbuta read as haa, since city
  /// names are often typed either way (مكة / مكه).
  static String _normalize(String text) =>
      normalizeArabicSearch(text).replaceAll('ة', 'ه');

  Future<CityMatch?> nearest(double latitude, double longitude) async =>
      NearestCity.find(latitude, longitude, await cities());
}
