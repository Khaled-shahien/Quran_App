import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/prayer_city.dart';

/// The bundled city list, read once and kept for the app's lifetime.
class PrayerCityCatalog {
  PrayerCityCatalog({Future<String> Function()? load})
    : _load =
          load ?? (() => rootBundle.loadString('assets/prayer_cities.json'));

  static final PrayerCityCatalog bundled = PrayerCityCatalog();

  final Future<String> Function() _load;
  List<PrayerCity>? _cities;

  /// Empty when the asset cannot be read (retried on the next call);
  /// manual coordinates stay usable.
  Future<List<PrayerCity>> cities() async {
    final cached = _cities;
    if (cached != null) return cached;
    try {
      final decoded = jsonDecode(await _load());
      if (decoded is! List) return const [];
      return _cities = List.unmodifiable(
        decoded
            .whereType<Map<String, dynamic>>()
            .map(PrayerCity.fromJson)
            .whereType<PrayerCity>(),
      );
    } catch (_) {
      return const [];
    }
  }

  Future<CityMatch?> nearest(double latitude, double longitude) async =>
      NearestCity.find(latitude, longitude, await cities());
}
