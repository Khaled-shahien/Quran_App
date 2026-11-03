import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/errors/api_exception.dart';
import 'package:sakina_app/features/prayers/data/data_sources/prayer_times_api_service.dart';
import 'package:sakina_app/features/prayers/data/models/prayer_times_response.dart';
import 'package:sakina_app/features/prayers/data/repositories/prayer_times_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ScriptedApi extends PrayerTimesApiService {
  Object? next;

  @override
  Future<PrayerTimesResponse> getPrayerTimes(
    DateTime date,
    double latitude,
    double longitude, {
    int calculationMethod = 3,
  }) async {
    final value = next;
    if (value is PrayerTimesResponse) return value;
    throw value!;
  }
}

PrayerTimesResponse _response({String? isha = '19:00'}) => PrayerTimesResponse(
  code: 200,
  status: 'OK',
  data: Data(
    timings: Timings(
      fajr: '05:00',
      dhuhr: '12:00',
      asr: '15:00',
      maghrib: '18:00',
      isha: isha,
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final date = DateTime(2026, 6, 1);
  late _ScriptedApi api;
  late SharedPreferences prefs;
  late PrayerTimesRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    api = _ScriptedApi();
    repository = PrayerTimesRepositoryImpl(
      apiService: api,
      sharedPreferences: prefs,
    );
  });

  Future<void> seedExpiredCache() async {
    api.next = _response();
    await repository.getPrayerTimes(date, 30, 31);
    final expired = DateTime.now().subtract(const Duration(hours: 3));
    for (final key in prefs.getKeys().where((k) => k.endsWith('_timestamp'))) {
      await prefs.setInt(key, expired.millisecondsSinceEpoch);
    }
  }

  for (final (name, failure) in <(String, Object)>[
    ('malformed payload', const FormatException('bad')),
    ('wrong payload shape', TypeError()),
    ('incomplete day', _response(isha: null)),
  ]) {
    test('$name falls back to the stale timings', () async {
      await seedExpiredCache();
      api.next = failure;

      final result = await repository.getPrayerTimes(date, 30, 31);

      expect(result.isStale, isTrue);
      expect(result.isha, '19:00');
    });
  }

  test('an incomplete day without a cache fails and is not cached', () async {
    api.next = _response(isha: null);

    await expectLater(
      repository.getPrayerTimes(date, 30, 31),
      throwsA(isA<ApiException>()),
    );
    expect(prefs.getKeys(), isEmpty);
  });
}
