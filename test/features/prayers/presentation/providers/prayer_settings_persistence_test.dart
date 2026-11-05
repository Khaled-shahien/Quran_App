import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/features/prayers/domain/entities/prayer_times_entity.dart';
import 'package:sakina_app/features/prayers/domain/prayer_calculation_policy.dart';
import 'package:sakina_app/features/prayers/domain/repositories/prayer_times_repository.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_times_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CapturingRepository implements PrayerTimesRepository {
  final zones = <String?>[];
  final madhabs = <AsrMadhab>[];

  @override
  Future<Result<PrayerTimesEntity>> getPrayerTimes(
    DateTime date,
    double latitude,
    double longitude, {
    int calculationMethod = PrayerCalculationPolicy.defaultMethod,
    AsrMadhab madhab = AsrMadhab.standard,
    String? timeZone,
  }) async {
    zones.add(timeZone);
    madhabs.add(madhab);
    return Success(
      PrayerTimesEntity(
        fajr: '05:00',
        sunrise: '06:20',
        dhuhr: '12:00',
        asr: '15:00',
        maghrib: '18:00',
        isha: '19:30',
        timezone: timeZone ?? 'Africa/Cairo',
      ),
    );
  }
}

void main() {
  late SharedPreferences prefs;
  late _CapturingRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repository = _CapturingRepository();
  });

  PrayerTimesProvider provider() =>
      PrayerTimesProvider(repository: repository, preferences: prefs);

  test('a catalog city timezone is used and survives restart', () async {
    await provider().selectLocation(
      24.68773,
      46.72185,
      'الرياض',
      PrayerCalculationPolicy.ummAlQura,
      timeZone: 'Asia/Riyadh',
    );
    expect(repository.zones.last, 'Asia/Riyadh');
    expect(prefs.getString(prayerTimeZonePreferenceKey), 'Asia/Riyadh');

    final restarted = provider();
    expect(restarted.selectedTimeZone, 'Asia/Riyadh');
    await restarted.fetchTodayForCurrentLocation();
    expect(repository.zones.last, 'Asia/Riyadh');
  });

  test('typed coordinates clear a previous city timezone', () async {
    final p = provider();
    await p.selectLocation(24.7, 46.7, 'الرياض', 4, timeZone: 'Asia/Riyadh');
    await p.selectLocation(30.0, 31.0, 'موقع', 5);

    expect(p.selectedTimeZone, isNull);
    expect(prefs.containsKey(prayerTimeZonePreferenceKey), isFalse);
    expect(repository.zones.last, isNull, reason: 'device zone is used');
  });

  test('Asr madhab defaults to the majority view', () {
    expect(provider().asrMadhab, AsrMadhab.standard);
  });

  test('changing the Asr madhab persists and recalculates', () async {
    final p = provider();
    await p.selectLocation(30.0444, 31.2357, 'القاهرة', 5);
    final callsBefore = repository.madhabs.length;

    await p.setAsrMadhab(AsrMadhab.hanafi);

    expect(repository.madhabs.length, greaterThan(callsBefore));
    expect(repository.madhabs.last, AsrMadhab.hanafi);
    expect(provider().asrMadhab, AsrMadhab.hanafi);
  });
}
