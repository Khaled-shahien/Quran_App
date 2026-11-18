import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/prayer_times_entity.dart';
import '../../domain/prayer_calculation_policy.dart';
import '../../domain/prayer_time_adjustments.dart';
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
    PrayerTimeAdjustments adjustments = PrayerTimeAdjustments.none,
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
          adjustments: adjustments,
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
    PrayerTimeAdjustments adjustments = PrayerTimeAdjustments.none,
    DateTime? fetchedAt,
  }) {
    final coordinates = adhan.Coordinates(latitude, longitude);
    final params = parametersFor(
      calculationMethod,
      date: date,
      madhab: madhab,
      coordinates: coordinates,
      adjustments: adjustments,
    );

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

  /// The full calculation settings for [method] on [date], exposed so the
  /// "how are my times calculated" sheet shows exactly what is used.
  static adhan.CalculationParameters parametersFor(
    int method, {
    required DateTime date,
    AsrMadhab madhab = AsrMadhab.standard,
    adhan.Coordinates? coordinates,
    PrayerTimeAdjustments adjustments = PrayerTimeAdjustments.none,
  }) {
    final adhan.CalculationParameters params = _base(method);
    // Umm al-Qura: Isha is 120 minutes after Maghrib in Ramadan instead of
    // 90, as in the official Umm al-Qura timetable.
    if (method == PrayerCalculationPolicy.ummAlQura && isRamadan(date)) {
      params.ishaInterval = 120;
    }
    params.madhab = madhab == AsrMadhab.hanafi
        ? adhan.Madhab.hanafi
        : adhan.Madhab.shafi;
    if (coordinates != null) {
      params.highLatitudeRule = adhan.HighLatitudeRule.recommended(coordinates);
    }
    params.polarCircleResolution = adhan.PolarCircleResolution.aqrabYaum;
    params.adjustments = {
      adhan.Prayer.fajr: adjustments.of(PrayerTimeKind.fajr),
      adhan.Prayer.sunrise: adjustments.of(PrayerTimeKind.sunrise),
      adhan.Prayer.dhuhr: adjustments.of(PrayerTimeKind.dhuhr),
      adhan.Prayer.asr: adjustments.of(PrayerTimeKind.asr),
      adhan.Prayer.maghrib: adjustments.of(PrayerTimeKind.maghrib),
      adhan.Prayer.isha: adjustments.of(PrayerTimeKind.isha),
    };
    return params;
  }

  /// Whether the calendar [date] falls in Ramadan by the Umm al-Qura
  /// calendar of the hijri package.
  static bool isRamadan(DateTime date) =>
      HijriCalendar.fromDate(
        DateTime(date.year, date.month, date.day),
      ).hMonth ==
      9;

  static adhan.CalculationParameters _base(int method) => switch (method) {
    PrayerCalculationPolicy.karachi =>
      adhan.CalculationMethodParameters.karachi(),
    PrayerCalculationPolicy.northAmerica =>
      adhan.CalculationMethodParameters.northAmerica(),
    PrayerCalculationPolicy.muslimWorldLeague =>
      adhan.CalculationMethodParameters.muslimWorldLeague(),
    PrayerCalculationPolicy.ummAlQura =>
      adhan.CalculationMethodParameters.ummAlQura(),
    PrayerCalculationPolicy.gulfRegion =>
      adhan.CalculationMethodParameters.gulfRegion(),
    PrayerCalculationPolicy.kuwait =>
      adhan.CalculationMethodParameters.kuwait(),
    PrayerCalculationPolicy.qatar => adhan.CalculationMethodParameters.qatar(),
    PrayerCalculationPolicy.singapore =>
      adhan.CalculationMethodParameters.singapore(),
    PrayerCalculationPolicy.france =>
      adhan.CalculationMethodParameters.france(),
    PrayerCalculationPolicy.turkiye =>
      adhan.CalculationMethodParameters.turkiye(),
    PrayerCalculationPolicy.russia =>
      adhan.CalculationMethodParameters.russia(),
    PrayerCalculationPolicy.moonsightingCommittee =>
      adhan.CalculationMethodParameters.moonsightingCommittee(),
    PrayerCalculationPolicy.dubai => adhan.CalculationMethodParameters.dubai(),
    PrayerCalculationPolicy.tunisia =>
      adhan.CalculationMethodParameters.tunisia(),
    PrayerCalculationPolicy.algeria =>
      adhan.CalculationMethodParameters.algerian(),
    PrayerCalculationPolicy.indonesia =>
      adhan.CalculationMethodParameters.indonesian(),
    PrayerCalculationPolicy.morocco =>
      adhan.CalculationMethodParameters.morocco(),
    PrayerCalculationPolicy.portugal =>
      adhan.CalculationMethodParameters.portugal(),
    PrayerCalculationPolicy.jordan =>
      adhan.CalculationMethodParameters.jordan(),
    _ => adhan.CalculationMethodParameters.egyptian(),
  };
}
