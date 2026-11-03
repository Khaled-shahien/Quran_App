import 'package:sakina_app/features/prayers/domain/prayer_calculation_policy.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/errors/network_exception.dart';
import '../../../../../core/api/api_error_handler.dart';
import '../data_sources/prayer_times_api_service.dart';
import '../models/prayer_times_response.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import '../../domain/entities/prayer_times_entity.dart';

/// Prayer Times Repository Implementation
///
/// Repository pattern implementation for Prayer Times data access.
/// Handles data fetching from API and error management.
class PrayerTimesRepositoryImpl implements PrayerTimesRepository {
  final PrayerTimesApiService _apiService;
  final ApiErrorHandler _errorHandler;
  final SharedPreferences _prefs;

  // Cache keys
  static const String _prayerTimesCacheKey = 'cached_prayer_times';
  static const String _prayerTimesCacheTimestampKey =
      'cached_prayer_times_timestamp';
  static const String _prayerTimesCachePrefix = 'cached_prayer_times_';
  static const int _cacheDurationHours = 2; // Cache for 2 hours

  PrayerTimesRepositoryImpl({
    required PrayerTimesApiService apiService,
    required SharedPreferences sharedPreferences,
    ApiErrorHandler? errorHandler,
  }) : _apiService = apiService,
       _prefs = sharedPreferences,
       _errorHandler = errorHandler ?? ApiErrorHandler();

  /// Convert PrayerTimesResponse to PrayerTimesEntity
  PrayerTimesEntity _responseToEntity(PrayerTimesResponse response) {
    final data = response.data;
    final timings = data?.timings;
    final meta = data?.meta;
    final gregorianDate = data?.date?.gregorian;

    return PrayerTimesEntity(
      fetchedAt: DateTime.now(),
      fajr: timings?.fajr,
      sunrise: timings?.sunrise,
      dhuhr: timings?.dhuhr,
      asr: timings?.asr,
      maghrib: timings?.maghrib,
      isha: timings?.isha,
      imsak: timings?.imsak,
      midnight: timings?.midnight,
      latitude: meta?.latitude,
      longitude: meta?.longitude,
      timezone: meta?.timezone,
      calculationMethod: meta?.method?.id,
      lunarSighting: gregorianDate?.lunarSighting,
    );
  }

  /// Get prayer times for a specific date and location
  ///
  /// Parameters:
  /// - [date]: The date to get prayer times for
  /// - [latitude]: User's latitude
  /// - [longitude]: User's longitude
  /// - [calculationMethod]: Calculation method
  ///   (default Egyptian General Authority of Survey)
  ///
  /// Returns: Future<PrayerTimesEntity>
  /// Throws: NetworkException, ApiException
  @override
  Future<PrayerTimesEntity> getPrayerTimes(
    DateTime date,
    double latitude,
    double longitude, {
    int calculationMethod = PrayerCalculationPolicy.defaultMethod,
  }) async {
    final cacheKey = _cacheKey(date, latitude, longitude, calculationMethod);
    final cached = _readCachedPrayerTimes(cacheKey);
    if (cached != null) {
      return cached;
    }

    try {
      // Fetch from API
      final response = await _apiService.getPrayerTimes(
        date,
        latitude,
        longitude,
        calculationMethod: calculationMethod,
      );

      final timings = response.data?.timings;
      // An incomplete day must not replace usable timings in the cache.
      if (response.status == 'OK' &&
          timings != null &&
          timings.fajr != null &&
          timings.dhuhr != null &&
          timings.asr != null &&
          timings.maghrib != null &&
          timings.isha != null) {
        final entity = _responseToEntity(response);
        try {
          await _writeCachedPrayerTimes(cacheKey, entity);
        } catch (_) {
          // Storage failure must not discard successfully fetched timings.
        }
        return entity;
      } else {
        throw ApiException(
          message: 'Failed to fetch prayer times: ${response.status}',
          code: response.code,
        );
      }
    } on NetworkException {
      final stale = _readCachedPrayerTimes(cacheKey, allowStale: true);
      if (stale != null) return stale;
      rethrow;
    } on ApiException {
      final stale = _readCachedPrayerTimes(cacheKey, allowStale: true);
      if (stale != null) return stale;
      rethrow;
    } catch (e) {
      // Malformed payloads are as recoverable as network failures.
      final stale = _readCachedPrayerTimes(cacheKey, allowStale: true);
      if (stale != null) return stale;
      throw ApiException(message: _errorHandler.handleError(e), code: 0);
    }
  }

  String _cacheKey(
    DateTime date,
    double latitude,
    double longitude,
    int calculationMethod,
  ) {
    final dateKey = date.toIso8601String().split('T').first;
    return '$_prayerTimesCachePrefix${dateKey}_${latitude.toStringAsFixed(4)}_'
        '${longitude.toStringAsFixed(4)}_$calculationMethod';
  }

  PrayerTimesEntity? _readCachedPrayerTimes(
    String cacheKey, {
    bool allowStale = false,
  }) {
    final timestamp = _prefs.getInt('${cacheKey}_timestamp');
    final encoded = _prefs.getString(cacheKey);
    if (timestamp == null || encoded == null) return null;

    final age = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(timestamp),
    );
    if (age.isNegative || (!allowStale && age.inHours >= _cacheDurationHours)) {
      return null;
    }

    try {
      final json = jsonDecode(encoded) as Map<String, dynamic>;
      return PrayerTimesEntity(
        fetchedAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
        isCached: true,
        isStale: age.inHours >= _cacheDurationHours,
        fajr: json['fajr'] as String?,
        sunrise: json['sunrise'] as String?,
        dhuhr: json['dhuhr'] as String?,
        asr: json['asr'] as String?,
        maghrib: json['maghrib'] as String?,
        isha: json['isha'] as String?,
        imsak: json['imsak'] as String?,
        midnight: json['midnight'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        timezone: json['timezone'] as String?,
        calculationMethod: (json['calculationMethod'] as num?)?.toInt(),
        lunarSighting: json['lunarSighting'] as bool?,
      );
    } on Object {
      return null;
    }
  }

  Future<void> _writeCachedPrayerTimes(
    String cacheKey,
    PrayerTimesEntity entity,
  ) async {
    await _prefs.setString(
      cacheKey,
      jsonEncode({
        'fajr': entity.fajr,
        'sunrise': entity.sunrise,
        'dhuhr': entity.dhuhr,
        'asr': entity.asr,
        'maghrib': entity.maghrib,
        'isha': entity.isha,
        'imsak': entity.imsak,
        'midnight': entity.midnight,
        'latitude': entity.latitude,
        'longitude': entity.longitude,
        'timezone': entity.timezone,
        'calculationMethod': entity.calculationMethod,
        'lunarSighting': entity.lunarSighting,
      }),
    );
    await _prefs.setInt(
      '${cacheKey}_timestamp',
      DateTime.now().millisecondsSinceEpoch,
    );
    await _removeExpiredDays(keep: cacheKey);
  }

  /// Timings are only reused for their own date, so older days are dead weight.
  /// Two days of margin cover locations ahead of or behind the device date.
  Future<void> _removeExpiredDays({required String keep}) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 2));
    final datedKey = RegExp('^$_prayerTimesCachePrefix(\\d{4}-\\d{2}-\\d{2})_');
    for (final key in _prefs.getKeys().toList()) {
      if (key.startsWith(keep)) continue;
      final match = datedKey.firstMatch(key);
      final date = match == null ? null : DateTime.tryParse(match.group(1)!);
      if (date != null && date.isBefore(cutoff)) await _prefs.remove(key);
    }
  }

  /// Check if cache is valid (within 2 hours)
  Future<bool> isCacheValid() async {
    final timestamp = _prefs.getInt(_prayerTimesCacheTimestampKey);
    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(cacheTime);

    return difference.inHours < _cacheDurationHours;
  }

  /// Clear cached prayer times data
  Future<void> clearCache() async {
    final keysToRemove = _prefs.getKeys().where(
      (key) =>
          key == _prayerTimesCacheKey ||
          key == _prayerTimesCacheTimestampKey ||
          key.startsWith(_prayerTimesCachePrefix),
    );
    for (final key in keysToRemove) {
      await _prefs.remove(key);
    }
  }
}
