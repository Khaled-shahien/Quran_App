import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/api/api_error_handler.dart';
import '../data_sources/local_quran_data_source.dart';
import '../models/ayah_model.dart';
import '../../domain/repositories/ayah_repository.dart';
import '../../domain/entities/ayah_entity.dart';

/// Ayah Repository Implementation
///
/// Repository pattern implementation for Ayah data access.
/// Handles data fetching from local sources, caching, and error management.
class AyahRepositoryImpl implements AyahRepository {
  final LocalQuranDataSource _localDataSource;
  final ApiErrorHandler _errorHandler;
  final SharedPreferences _prefs;

  // Cache keys
  static const String _ayahsCachePrefix = 'cached_ayahs_surah_';
  static const String _ayahsCacheTimestampPrefix =
      'cached_ayahs_timestamp_surah_';
  static const int _cacheDurationHours = 24; // Cache for 24 hours

  AyahRepositoryImpl({
    required LocalQuranDataSource localDataSource,
    required SharedPreferences sharedPreferences,
    ApiErrorHandler? errorHandler,
  }) : _localDataSource = localDataSource,
       _prefs = sharedPreferences,
       _errorHandler = errorHandler ?? ApiErrorHandler();

  /// Convert AyahModel to AyahEntity
  AyahEntity _modelToEntity(AyahModel model) {
    return AyahEntity(
      number: model.number,
      text: model.text,
      numberInSurah: model.numberInSurah,
      juz: model.juz,
      manzil: model.manzil,
      page: model.page,
      ruku: model.ruku,
      hizbQuarter: model.hizbQuarter,
      sajda: model.sajda,
    );
  }

  /// Get all Ayahs for a specific Surah
  @override
  Future<List<AyahEntity>> getAyahsForSurah(int surahNumber) async {
    try {
      // Validate input
      if (surahNumber < 1 || surahNumber > 114) {
        throw ApiException(
          message: 'Invalid Surah number: $surahNumber',
          code: 400,
        );
      }

      // Try to get from cache first
      final cachedAyahs = await _getCachedAyahs(surahNumber);
      if (cachedAyahs != null && cachedAyahs.isNotEmpty) {
        return cachedAyahs.map(_modelToEntity).toList();
      }

      // Fetch from local data source
      final ayahModels = await _localDataSource.getAyahsForSurah(surahNumber);

      // Cache the results
      await _cacheAyahs(surahNumber, ayahModels);

      return ayahModels.map(_modelToEntity).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: _errorHandler.handleError(e), code: 0);
    }
  }

  /// Get a specific Ayah by Surah number and Ayah number
  @override
  Future<AyahEntity> getAyah(int surahNumber, int ayahNumber) async {
    try {
      final ayahs = await getAyahsForSurah(surahNumber);

      if (ayahNumber < 1 || ayahNumber > ayahs.length) {
        throw ApiException(
          message:
              'Ayah number $ayahNumber is out of range '
              'for Surah $surahNumber (1-${ayahs.length})',
          code: 404,
        );
      }

      return ayahs[ayahNumber - 1]; // Convert to 0-based index
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: _errorHandler.handleError(e), code: 0);
    }
  }

  /// Get all Ayahs for all Surahs
  @override
  Future<Map<int, List<AyahEntity>>> getAllAyahs() async {
    try {
      final allAyahs = <int, List<AyahEntity>>{};

      // Process all 114 Surahs
      for (int surahNumber = 1; surahNumber <= 114; surahNumber++) {
        try {
          final ayahs = await getAyahsForSurah(surahNumber);
          allAyahs[surahNumber] = ayahs;
        } catch (e) {
          // Continue processing other Surahs even if one fails
          developer.log(
            'Could not load ayahs for Surah $surahNumber',
            name: 'sakina_app.quran_data',
            level: 900,
            error: e,
          );
        }
      }

      return allAyahs;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: _errorHandler.handleError(e), code: 0);
    }
  }

  /// Search Ayahs containing the query text
  @override
  Future<List<AyahEntity>> searchAyahs(String query) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      final allAyahs = await getAllAyahs();
      final results = <AyahEntity>[];

      final lowerQuery = query.toLowerCase().trim();

      for (final entry in allAyahs.entries) {
        final ayahs = entry.value;

        for (final ayah in ayahs) {
          if (ayah.text.toLowerCase().contains(lowerQuery)) {
            results.add(ayah);
          }
        }
      }

      return results;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: _errorHandler.handleError(e), code: 0);
    }
  }

  /// Check if cache is valid for a specific Surah (within 24 hours)
  Future<bool> isCacheValid(int surahNumber) async {
    final timestamp = _prefs.getInt('$_ayahsCacheTimestampPrefix$surahNumber');
    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(cacheTime);

    return difference.inHours < _cacheDurationHours;
  }

  /// Cache Ayahs data for a specific Surah
  Future<void> _cacheAyahs(int surahNumber, List<AyahModel> ayahs) async {
    try {
      final ayahsJson = ayahs.map((ayah) => ayah.toJson()).toList();
      final jsonString = _encodeAyahsToJson(ayahsJson);

      await _prefs.setString('$_ayahsCachePrefix$surahNumber', jsonString);
      await _prefs.setInt(
        '$_ayahsCacheTimestampPrefix$surahNumber',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // Silently fail cache operations
      // Don't throw exceptions for cache failures
    }
  }

  /// Get cached Ayahs for a specific Surah (only if cache is valid)
  Future<List<AyahModel>?> _getCachedAyahs(int surahNumber) async {
    try {
      if (!await isCacheValid(surahNumber)) return null;

      final jsonString = _prefs.getString('$_ayahsCachePrefix$surahNumber');
      if (jsonString == null) return null;

      final ayahs = _decodeAyahsFromJson(jsonString);
      return ayahs;
    } catch (e) {
      // Return null if cache reading fails
      return null;
    }
  }

  /// Encode Ayahs list to JSON string
  String _encodeAyahsToJson(List<Map<String, dynamic>> ayahsJson) {
    return json.encode(ayahsJson);
  }

  /// Decode Ayahs list from JSON string
  List<AyahModel> _decodeAyahsFromJson(String jsonString) {
    final List<dynamic> parsedList = json.decode(jsonString);
    final ayahs = parsedList
        .map((json) => AyahModel.fromJson(json as Map<String, dynamic>))
        .toList();
    return ayahs;
  }
}
