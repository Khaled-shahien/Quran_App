import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/features/prayers/domain/prayer_calculation_policy.dart';
import '../entities/prayer_times_entity.dart';

/// Prayer times for one calendar day at one place.
///
/// Times are calculated on the device, so this works fully offline.
abstract class PrayerTimesRepository {
  /// [date] is the calendar day at the location (only y/m/d are used).
  /// [timeZone] is the location's IANA zone; when null the device zone is
  /// used. Returned times are wall-clock "HH:mm" strings in that zone.
  Future<Result<PrayerTimesEntity>> getPrayerTimes(
    DateTime date,
    double latitude,
    double longitude, {
    int calculationMethod = PrayerCalculationPolicy.defaultMethod,
    AsrMadhab madhab = AsrMadhab.standard,
    String? timeZone,
  });
}
