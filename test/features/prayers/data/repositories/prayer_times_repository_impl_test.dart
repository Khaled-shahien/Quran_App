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

class CountingPrayerTimesApiService extends FakePrayerTimesApiService {
  CountingPrayerTimesApiService({required super.response});

  int calls = 0;

  @override
  Future<PrayerTimesResponse> getPrayerTimes(
    DateTime date,
    double latitude,
    double longitude, {
    int calculationMethod = 3,
  }) async {
    calls++;
    return super.getPrayerTimes(
      date,
      latitude,
      longitude,
      calculationMethod: calculationMethod,
    );
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
    test(
      'expired exact-key cache survives network failure and is labeled stale',
      () async {
        final online = PrayerTimesRepositoryImpl(
          apiService: FakePrayerTimesApiService(response: successResponse()),
          sharedPreferences: prefs,
        );
        final date = DateTime(2026, 9, 22);
        await online.getPrayerTimes(date, 30, 31);
        final timestampKey = prefs.getKeys().singleWhere(
          (key) => key.endsWith('_timestamp'),
        );
        await prefs.setInt(
          timestampKey,
          DateTime.now()
              .subtract(const Duration(hours: 3))
              .millisecondsSinceEpoch,
        );
        final offline = PrayerTimesRepositoryImpl(
          apiService: FakePrayerTimesApiService(
            networkException: const NetworkException.noInternet(),
          ),
          sharedPreferences: prefs,
        );
        final result = await offline.getPrayerTimes(date, 30, 31);
        expect(result.isStale, isTrue);
        expect(result.isCached, isTrue);
        expect(result.fetchedAt, isNotNull);
        expect(result.fajr, '05:00');
        await expectLater(
          offline.getPrayerTimes(date.add(const Duration(days: 1)), 30, 31),
          throwsA(isA<NetworkException>()),
        );
        await expectLater(
          offline.getPrayerTimes(date, 21, 39),
          throwsA(isA<NetworkException>()),
        );
      },
    );

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

    test(
      'writes successful responses and serves them from the keyed cache',
      () async {
        final apiService = CountingPrayerTimesApiService(
          response: successResponse(),
        );
        final repository = PrayerTimesRepositoryImpl(
          apiService: apiService,
          sharedPreferences: prefs,
        );
        final date = DateTime(2026, 3, 25);

        final first = await repository.getPrayerTimes(date, 30.0, 31.0);
        final second = await repository.getPrayerTimes(date, 30.0, 31.0);

        expect(first, second);
        expect(apiService.calls, 1);
        expect(
          prefs.getKeys().any((key) => key.startsWith('cached_prayer_times_')),
          isTrue,
        );
      },
    );
  });
}
