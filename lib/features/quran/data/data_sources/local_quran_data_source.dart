import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import '../../../../core/errors/api_exception.dart';
import '../models/ayah_model.dart';

/// Local Quran Data Source
///
/// Handles reading and parsing Quran verses from local assets
class LocalQuranDataSource {
  static const String _assetPath = 'assets/quran_master.json';

  List<Map<String, dynamic>>? _cachedSurahData;

  Future<List<Map<String, dynamic>>> _loadMasterData() async {
    if (_cachedSurahData != null) {
      return _cachedSurahData!;
    }

    final String jsonString = await rootBundle.loadString(_assetPath);
    final List<dynamic> jsonData = jsonDecode(jsonString) as List<dynamic>;

    _cachedSurahData = jsonData
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    return _cachedSurahData!;
  }

  /// Reads the Quran verses for a specific Surah from the assets folder
  ///
  /// Parameters:
  /// - [surahNumber]: The Surah number (1-114)
  ///
  /// Returns: Future<List<AyahModel>>
  /// Throws: ApiException if the file cannot be read or parsed
  Future<List<AyahModel>> getAyahsForSurah(int surahNumber) async {
    try {
      if (surahNumber < 1 || surahNumber > 114) {
        throw ApiException(
          message: 'Invalid Surah number: $surahNumber',
          code: 400,
        );
      }

      final List<Map<String, dynamic>> allSurahs = await _loadMasterData();
      final Map<String, dynamic> surahData = allSurahs.firstWhere(
        (surah) => surah['number'] == surahNumber,
        orElse: () => <String, dynamic>{},
      );

      if (surahData.isEmpty) {
        throw ApiException(
          message: 'Could not find Surah $surahNumber in $_assetPath',
          code: 404,
        );
      }

      final List<dynamic> ayahsJson =
          (surahData['ayahs'] as List<dynamic>? ?? <dynamic>[]);
      final List<AyahModel> ayahs = ayahsJson
          .map(
            (item) =>
                AyahModel.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();

      return ayahs;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Error reading verses for Surah $surahNumber: ${e.toString()}',
        code: 500,
      );
    }
  }

  /// Reads all Surahs' verses from the assets folder
  ///
  /// Returns: Future<Map<int, List<AyahModel>>>
  /// Where the key is the Surah number and the value is the list of Ayahs
  Future<Map<int, List<AyahModel>>> getAllAyahs() async {
    try {
      final allAyahs = <int, List<AyahModel>>{};
      final List<Map<String, dynamic>> allSurahs = await _loadMasterData();

      for (final surah in allSurahs) {
        final int? surahNumber = surah['number'] as int?;
        if (surahNumber == null) {
          continue;
        }

        try {
          final List<dynamic> ayahsJson =
              (surah['ayahs'] as List<dynamic>? ?? <dynamic>[]);
          final List<AyahModel> ayahs = ayahsJson
              .map(
                (item) =>
                    AyahModel.fromJson(Map<String, dynamic>.from(item as Map)),
              )
              .toList();
          allAyahs[surahNumber] = ayahs;
        } catch (e) {
          developer.log(
            'Could not load verses for Surah $surahNumber',
            name: 'sakina_app.quran_data',
            level: 900,
            error: e,
          );
        }
      }

      return allAyahs;
    } catch (e) {
      throw ApiException(
        message: 'Error reading all Quran verses: ${e.toString()}',
        code: 500,
      );
    }
  }
}
