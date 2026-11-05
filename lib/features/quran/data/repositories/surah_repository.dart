import 'package:sakina_app/core/utils/arabic_text.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/api/api_error_handler.dart';
import '../data_sources/local_surah_data_source.dart';
import '../models/surah_model.dart';
import '../../domain/repositories/surah_repository.dart';
import '../../domain/entities/surah_entity.dart';

/// Surah Repository
///
/// Repository pattern implementation for Surah data access.
/// Handles data fetching from local storage.
class SurahRepositoryImpl implements SurahRepository {
  final LocalSurahDataSource _localDataSource;
  final ApiErrorHandler _errorHandler;
  final SharedPreferences _prefs;

  // Cache keys
  static const String _surahsCacheKey = 'cached_surahs';
  static const String _surahsCacheTimestampKey = 'cached_surahs_timestamp';
  static const int _cacheDurationHours = 24; // Cache for 24 hours

  SurahRepositoryImpl({
    required LocalSurahDataSource localDataSource,
    required SharedPreferences sharedPreferences,
    ApiErrorHandler? errorHandler,
  }) : _localDataSource = localDataSource,
       _prefs = sharedPreferences,
       _errorHandler = errorHandler ?? ApiErrorHandler();

  /// Convert SurahModel to SurahEntity
  SurahEntity _modelToEntity(SurahModel model) {
    return SurahEntity(
      number: model.number,
      name: displaySurahName(model.name),
      englishName: model.englishName,
      englishNameTranslation: model.englishNameTranslation,
      revelationType: model.revelationType,
      totalAyah: model.numberOfAyahs,
    );
  }

  /// Get all Surahs from local storage
  ///
  /// First checks local cache,
  /// then loads from local assets if cache is not available.
  ///
  /// Returns: Future<List<SurahEntity>>
  /// Throws: ApiException
  @override
  Future<List<SurahEntity>> getAllSurahs() async {
    try {
      // Try to get from cache first
      final cachedSurahsModels = await _getCachedSurahs();
      if (cachedSurahsModels != null && cachedSurahsModels.isNotEmpty) {
        return cachedSurahsModels.map(_modelToEntity).toList();
      }

      // Load from local assets
      final surahs = await _localDataSource.loadAllSurahs();

      // Cache the results
      await _cacheSurahs(surahs);

      return surahs.map(_modelToEntity).toList();
    } catch (e) {
      throw ApiException(message: _errorHandler.handleError(e), code: 0);
    }
  }

  /// Get a specific Surah by index
  ///
  /// Parameters:
  /// - [index]: Surah number (1-114)
  ///
  /// Returns: Future<SurahEntity>
  /// Throws: ApiException
  @override
  Future<SurahEntity> getSurahByIndex(int index) async {
    try {
      final surahs = await getAllSurahs();

      if (index < 1 || index > surahs.length) {
        throw ApiException(
          message: 'Surah index $index is out of range (1-${surahs.length})',
          code: 404,
        );
      }

      return surahs[index - 1]; // Convert to 0-based index
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: _errorHandler.handleError(e), code: 0);
    }
  }

  /// Search Surahs by name
  ///
  /// Parameters:
  /// - [query]: Search term
  ///
  /// Returns: Future<List<SurahEntity>>
  /// Throws: ApiException
  @override
  Future<List<SurahEntity>> searchSurahs(String query) async {
    try {
      final allSurahs = await getAllSurahs();
      final lowerQuery = query.toLowerCase();

      final filteredSurahs = allSurahs.where((surah) {
        return surah.name.toLowerCase().contains(lowerQuery) ||
            surah.englishName.toLowerCase().contains(lowerQuery) ||
            surah.englishNameTranslation.toLowerCase().contains(lowerQuery);
      }).toList();

      return filteredSurahs;
    } catch (e) {
      throw ApiException(message: _errorHandler.handleError(e), code: 0);
    }
  }

  /// Get Surahs by revelation place
  ///
  /// Parameters:
  /// - [place]: 'Mecca' or 'Madina'
  ///
  /// Returns: Future<List<SurahEntity>>
  /// Throws: ApiException
  @override
  Future<List<SurahEntity>> getSurahsByRevelationPlace(String place) async {
    try {
      final allSurahs = await getAllSurahs();
      final normalizedPlace = place.toLowerCase();

      final filteredSurahs = allSurahs.where((surah) {
        final surahPlace = surah.revelationType.toLowerCase();
        // Match both the old format (mecca/madina)
        // and new format (meccan/medinan).
        if (normalizedPlace == 'mecca' || normalizedPlace == 'meccan') {
          return surahPlace == 'mecca' ||
              surahPlace == 'meccan' ||
              surahPlace == 'mc';
        } else {
          // madina
          return surahPlace == 'madina' ||
              surahPlace == 'medinan' ||
              surahPlace == 'md';
        }
      }).toList();

      return filteredSurahs;
    } catch (e) {
      throw ApiException(message: _errorHandler.handleError(e), code: 0);
    }
  }

  /// Get Surah statistics
  ///
  /// Returns: Future<Map<String, dynamic>>
  /// Throws: ApiException
  @override
  Future<Map<String, dynamic>> getSurahStatistics() async {
    try {
      final allSurahs = await getAllSurahs();

      final meccanCount = allSurahs.where((surah) {
        final place = surah.revelationType.toLowerCase();
        return place == 'mecca' || place == 'meccan' || place == 'mc';
      }).length;
      final medinanCount = allSurahs.where((surah) {
        final place = surah.revelationType.toLowerCase();
        return place == 'madina' || place == 'medinan' || place == 'md';
      }).length;
      final totalVerses = allSurahs.fold<int>(
        0,
        (sum, surah) => sum + surah.totalAyah,
      );

      return {
        'totalSurahs': allSurahs.length,
        'meccanSurahs': meccanCount,
        'medinanSurahs': medinanCount,
        'totalVerses': totalVerses,
        'averageVersesPerSurah': totalVerses / allSurahs.length,
      };
    } catch (e) {
      throw ApiException(message: _errorHandler.handleError(e), code: 0);
    }
  }

  /// Clear cached Surah data
  @override
  Future<void> clearCache() async {
    await _prefs.remove(_surahsCacheKey);
    await _prefs.remove(_surahsCacheTimestampKey);
  }

  /// Check if cache is valid (within 24 hours)
  Future<bool> isCacheValid() async {
    final timestamp = _prefs.getInt(_surahsCacheTimestampKey);
    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(cacheTime);

    return difference.inHours < _cacheDurationHours;
  }

  /// Cache Surahs data
  Future<void> _cacheSurahs(List<SurahModel> surahs) async {
    try {
      final surahsJson = surahs.map((surah) => surah.toJson()).toList();
      final jsonString = jsonEncode(surahsJson);

      await _prefs.setString(_surahsCacheKey, jsonString);
      await _prefs.setInt(
        _surahsCacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // Silently fail cache operations
      // Don't throw exceptions for cache failures
    }
  }

  /// Get cached Surahs (only if cache is valid)
  Future<List<SurahModel>?> _getCachedSurahs() async {
    try {
      if (!await isCacheValid()) return null;

      final jsonString = _prefs.getString(_surahsCacheKey);
      if (jsonString == null) return null;

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final surahs = jsonList
          .map((json) => SurahModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return surahs;
    } catch (e) {
      // Return null if cache reading fails
      return null;
    }
  }
}
