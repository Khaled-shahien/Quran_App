import 'dart:math' as math;

import 'package:sakina_app/core/services/location_fix.dart';

/// A place from the bundled city list (city-centre coordinates).
class PrayerCity {
  const PrayerCity({
    required this.name,
    required this.country,
    required this.englishName,
    required this.latitude,
    required this.longitude,
    this.timeZone,
    this.countryCode,
    this.population = 0,
  });

  final String name;
  final String country;
  final String englishName;
  final double latitude;
  final double longitude;

  /// IANA zone, e.g. Africa/Cairo.
  final String? timeZone;

  /// ISO 3166-1 alpha-2 code (EG, SA, ...), when the list provides one.
  final String? countryCode;

  /// For ordering search results; 0 when unknown.
  final int population;

  /// One row of the compact list (schema 2): name, Latin name, country
  /// code, latitude, longitude, zone index, population. Null for a row
  /// that does not validate.
  static PrayerCity? fromRow(
    List<dynamic> row,
    Map<String, dynamic> countries,
    List<dynamic> zones,
  ) {
    if (row.length < 7) return null;
    final [
      Object? name,
      Object? latin,
      Object? code,
      Object? latitude,
      Object? longitude,
      Object? zone,
      Object? population,
      ...,
    ] = row;
    if (name is! String ||
        name.trim().isEmpty ||
        code is! String ||
        countries[code] is! String ||
        latitude is! num ||
        longitude is! num ||
        zone is! int ||
        zone < 0 ||
        zone >= zones.length ||
        zones[zone] is! String ||
        !isValidCoordinate(latitude.toDouble(), longitude.toDouble())) {
      return null;
    }
    return PrayerCity(
      name: name.trim(),
      country: countries[code] as String,
      englishName: latin is String && latin.isNotEmpty ? latin : name.trim(),
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      timeZone: zones[zone] as String,
      countryCode: code,
      population: population is int && population > 0 ? population : 0,
    );
  }

  /// Null for an entry that is missing a field or has invalid coordinates,
  /// so one bad row cannot break the list.
  static PrayerCity? fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final country = json['country'];
    final latitude = json['latitude'];
    final longitude = json['longitude'];
    final zone = json['timezone'];
    if (name is! String ||
        name.trim().isEmpty ||
        country is! String ||
        latitude is! num ||
        longitude is! num ||
        !isValidCoordinate(latitude.toDouble(), longitude.toDouble())) {
      return null;
    }
    final english = json['englishName'];
    return PrayerCity(
      name: name.trim(),
      country: country.trim(),
      englishName: english is String ? english.trim() : '',
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      timeZone: zone is String && zone.isNotEmpty ? zone : null,
    );
  }
}

/// How a device position relates to the nearest listed city.
enum CityProximity {
  /// Within the city itself.
  inCity,

  /// Outside it, but close enough to say "near".
  nearCity,
}

class CityMatch {
  const CityMatch({
    required this.city,
    required this.distanceMeters,
    required this.proximity,
  });

  final PrayerCity city;
  final double distanceMeters;
  final CityProximity proximity;
}

/// Offline reverse lookup over the bundled list: no coordinates leave the
/// device (the privacy policy promises this), and no network is needed.
///
/// The thresholds keep a position from being named after a neighbouring
/// city: beyond [nearCityMeters] no city is named at all, and the label
/// stays a neutral "device location".
abstract final class NearestCity {
  /// Wide enough for large metropolitan areas such as Greater Cairo.
  static const double inCityMeters = 25000;
  static const double nearCityMeters = 60000;

  static CityMatch? find(
    double latitude,
    double longitude,
    Iterable<PrayerCity> cities,
  ) {
    if (!isValidCoordinate(latitude, longitude)) return null;
    PrayerCity? best;
    var bestDistance = double.infinity;
    for (final city in cities) {
      final distance = distanceMeters(
        latitude,
        longitude,
        city.latitude,
        city.longitude,
      );
      if (distance < bestDistance) {
        best = city;
        bestDistance = distance;
      }
    }
    if (best == null || bestDistance > nearCityMeters) return null;
    return CityMatch(
      city: best,
      distanceMeters: bestDistance,
      proximity: bestDistance <= inCityMeters
          ? CityProximity.inCity
          : CityProximity.nearCity,
    );
  }

  /// Great-circle (haversine) distance on a mean-radius Earth.
  static double distanceMeters(
    double latitude1,
    double longitude1,
    double latitude2,
    double longitude2,
  ) {
    const earthRadius = 6371008.8;
    double radians(double degrees) => degrees * math.pi / 180;
    final dLat = radians(latitude2 - latitude1);
    final dLon = radians(longitude2 - longitude1);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(radians(latitude1)) *
            math.cos(radians(latitude2)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * earthRadius * math.asin(math.min(1, math.sqrt(a)));
  }
}
