import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/prayer_times_entity.dart';
import '../../domain/prayer_calculation_policy.dart';
import '../../domain/repositories/prayer_times_repository.dart';

/// Device timezone lookup, injectable for tests and background isolates.
typedef DeviceTimeZoneProvider = Future<String> Function();

Future<String> _platformTimeZone() => FlutterTimezone.getLocalTimezone();

/// Calculates prayer times on the device with `adhan_dart`. No network.
class PrayerTimesRepositoryImpl implements PrayerTimesRepository {
  PrayerTimesRepositoryImpl({
    DeviceTimeZoneProvider? deviceTimeZone,
    DateTime Function()? clock,
  }) : _deviceTimeZone = deviceTimeZone ?? _platformTimeZone,
       _clock = clock ?? DateTime.now;

  final DeviceTimeZoneProvider _deviceTimeZone;
  final DateTime Function() _clock;

  @override
  Future<Result<PrayerTimesEntity>> getPrayerTimes(
    DateTime date,
    double latitude,
    double longitude, {
    int calculationMethod = PrayerCalculationPolicy.defaultMethod,
    AsrMadhab madhab = AsrMadhab.standard,
    String? timeZone,
  }) async {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180 ||
        !PrayerCalculationPolicy.methods.containsKey(calculationMethod)) {
      return Err(
        UnexpectedFailure(cause: ArgumentError('Invalid prayer configuration')),
      );
    }
    try {
      if (!tz.timeZoneDatabase.isInitialized) tzdata.initializeTimeZones();
      final String zoneName = timeZone ?? await _deviceTimeZone();
      final tz.Location location = tz.getLocation(zoneName);
      return Success(
        calculate(
          date: date,
          latitude: latitude,
          longitude: longitude,
          calculationMethod: calculationMethod,
          madhab: madhab,
          location: location,
          fetchedAt: _clock(),
        ),
      );
    } catch (error) {
      return Err(UnexpectedFailure(cause: error));
    }
  }

  /// Pure calculation, exposed for reference-time tests.
  static PrayerTimesEntity calculate({
    required DateTime date,
    required double latitude,
    required double longitude,
    required int calculationMethod,
    required AsrMadhab madhab,
    required tz.Location location,
    DateTime? fetchedAt,
  }) {
    final coordinates = adhan.Coordinates(latitude, longitude);
    final params = _parameters(calculationMethod)
      ..madhab = madhab == AsrMadhab.hanafi
          ? adhan.Madhab.hanafi
          : adhan.Madhab.shafi
      ..highLatitudeRule = adhan.HighLatitudeRule.recommended(coordinates)
      ..polarCircleResolution = adhan.PolarCircleResolution.aqrabYaum;

    final times = adhan.PrayerTimes(
      // adhan_dart only reads the calendar day; times come back in UTC.
      date: DateTime.utc(date.year, date.month, date.day),
      coordinates: coordinates,
      calculationParameters: params,
    );

    String wall(DateTime utc) {
      final local = tz.TZDateTime.from(utc, location);
      return '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}';
    }

    return PrayerTimesEntity(
      fetchedAt: fetchedAt,
      fajr: wall(times.fajr),
      sunrise: wall(times.sunrise),
      dhuhr: wall(times.dhuhr),
      asr: wall(times.asr),
      maghrib: wall(times.maghrib),
      isha: wall(times.isha),
      latitude: latitude,
      longitude: longitude,
      timezone: location.name,
      calculationMethod: calculationMethod,
    );
  }

  static adhan.CalculationParameters _parameters(int method) =>
      switch (method) {
        PrayerCalculationPolicy.muslimWorldLeague =>
          adhan.CalculationMethodParameters.muslimWorldLeague(),
        PrayerCalculationPolicy.ummAlQura =>
          adhan.CalculationMethodParameters.ummAlQura(),
        _ => adhan.CalculationMethodParameters.egyptian(),
      };
}
