import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/errors/api_exception.dart';
import 'package:sakina_app/core/errors/network_exception.dart';
import 'package:sakina_app/features/prayers/data/data_sources/prayer_times_api_service.dart';
import 'package:sakina_app/features/prayers/data/models/prayer_times_response.dart';
import 'package:sakina_app/features/prayers/data/repositories/prayer_times_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePrayerTimesApiService extends PrayerTimesApiService {
  FakePrayerTimesApiService({
    this.response,
    this.networkException,
    this.throwable,
  });

  final PrayerTimesResponse? response;
  final NetworkException? networkException;
  final Object? throwable;

  @override
  Future<PrayerTimesResponse> getPrayerTimes(
    DateTime date,
    double latitude,
    double longitude, {
    int calculationMethod = 3,
  }) async {
    if (networkException != null) {
      throw networkException!;
    }
    if (throwable != null) {
      throw throwable!;
    }
    return response!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  PrayerTimesResponse successResponse() {
    return PrayerTimesResponse(
      code: 200,
      status: 'OK',
      data: Data(
        timings: Timings(
          fajr: '05:00',
          sunrise: '06:20',
          dhuhr: '12:10',
          asr: '15:30',
          maghrib: '18:05',
          isha: '19:20',
        ),
        meta: Meta(
          latitude: 30.0,
          longitude: 31.0,
          timezone: 'Africa/Cairo',
          method: Method(id: 5, name: 'MWL'),
        ),
      ),
    );
  }

  group('PrayerTimesRepositoryImpl', () {
    test('returns mapped entity on API success', () async {
      final repository = PrayerTimesRepositoryImpl(
        apiService: FakePrayerTimesApiService(response: successResponse()),
        sharedPreferences: prefs,
      );

      final result = await repository.getPrayerTimes(
        DateTime(2026, 3, 25),
        30.0,
        31.0,
      );

      expect(result.fajr, '05:00');
      expect(result.isha, '19:20');
      expect(result.latitude, 30.0);
      expect(result.calculationMethod, 5);
    });

    test('throws ApiException when API status is not OK', () async {
      final repository = PrayerTimesRepositoryImpl(
        apiService: FakePrayerTimesApiService(
          response: PrayerTimesResponse(code: 400, status: 'BAD_REQUEST'),
        ),
        sharedPreferences: prefs,
      );

      expect(
        () => repository.getPrayerTimes(DateTime(2026, 3, 25), 30.0, 31.0),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 400)
              .having((e) => e.message, 'message', contains('Failed to fetch')),
        ),
      );
    });

    test('rethrows NetworkException from API service', () async {
      final repository = PrayerTimesRepositoryImpl(
        apiService: FakePrayerTimesApiService(
          networkException: const NetworkException.timeout(),
        ),
        sharedPreferences: prefs,
      );

      expect(
        () => repository.getPrayerTimes(DateTime(2026, 3, 25), 30.0, 31.0),
        throwsA(isA<NetworkException>()),
      );
    });

    test('wraps unexpected errors as ApiException with code 0', () async {
      final repository = PrayerTimesRepositoryImpl(
        apiService: FakePrayerTimesApiService(throwable: StateError('boom')),
        sharedPreferences: prefs,
      );

      expect(
        () => repository.getPrayerTimes(DateTime(2026, 3, 25), 30.0, 31.0),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 0)
              .having(
                (e) => e.message,
                'message',
                contains('unexpected error'),
              ),
        ),
      );
    });

    test('cache validity and clear cache work as expected', () async {
      final repository = PrayerTimesRepositoryImpl(
        apiService: FakePrayerTimesApiService(response: successResponse()),
        sharedPreferences: prefs,
      );

      await prefs.setInt(
        'cached_prayer_times_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
      expect(await repository.isCacheValid(), isTrue);

      await repository.clearCache();
      expect(prefs.containsKey('cached_prayer_times'), isFalse);
      expect(prefs.containsKey('cached_prayer_times_timestamp'), isFalse);
    });
  });
}
