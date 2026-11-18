import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/features/prayers/data/services/prayer_widget_data.dart';
import 'package:sakina_app/features/prayers/domain/entities/adhan_settings.dart';
import 'package:sakina_app/features/prayers/domain/entities/prayer_times_entity.dart';
import 'package:sakina_app/features/prayers/domain/prayer_calculation_policy.dart';
import 'package:sakina_app/features/prayers/domain/prayer_time_adjustments.dart';
import 'package:sakina_app/features/prayers/domain/repositories/prayer_times_repository.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_times_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      fajr: '04:50',
      sunrise: '06:15',
      dhuhr: '11:40',
      asr: '14:35',
      maghrib: '16:58',
      isha: '18:18',
      timezone: 'Africa/Cairo',
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('encode keeps order, instants and display labels', () {
    final data = PrayerWidgetData.encode(
      place: 'القاهرة، مصر',
      hijri: '٧ جمادى الآخرة ١٤٤٨هـ',
      prayers: [
        (
          prayer: DailyPrayer.fajr,
          name: 'الفجر',
          at: DateTime.utc(2026, 11, 18, 2, 50),
          label: '04:50',
        ),
      ],
    );
    final p = (data['prayers'] as List).single as Map;
    expect(p['id'], 'fajr');
    expect(p['at'], DateTime.utc(2026, 11, 18, 2, 50).millisecondsSinceEpoch);
    expect(data['hijri'], isNotNull);
  });

  test('a successful fetch writes today and tomorrow for the widget', () async {
    SharedPreferences.setMockInitialValues({'digit_style': 'arabic'});
    final prefs = await SharedPreferences.getInstance();
    final provider = PrayerTimesProvider(
      repository: _Repository(),
      preferences: prefs,
      nearestCity: (_, _) async => null,
    );
    addTearDown(provider.dispose);
    await provider.selectLocation(
      30.0444,
      31.2357,
      'القاهرة',
      5,
      timeZone: 'Africa/Cairo',
    );
    // Written without blocking the fetch.
    for (var i = 0; i < 20 && !prefs.containsKey(PrayerWidgetData.key); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    final decoded =
        jsonDecode(prefs.getString(PrayerWidgetData.key)!)
            as Map<String, dynamic>;
    final prayers = decoded['prayers'] as List;
    expect(prayers, hasLength(10));
    expect(decoded['place'], 'القاهرة');
    expect((prayers.first as Map)['label'], '٠٤:٥٠');
    final ats = [for (final p in prayers) (p as Map)['at'] as int];
    expect(ats, orderedEquals([...ats]..sort()));
  });
}
