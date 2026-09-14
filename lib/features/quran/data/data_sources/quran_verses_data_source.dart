import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

/// Quran Verses Data Source
///
/// Handles reading and parsing Quran verses from local assets
class QuranVersesDataSource {
  /// Reads the verses for a specific Surah from the assets folder
  ///
  /// Parameters:
  /// - [surahNumber]: The Surah number (1-114)
  ///
  /// Returns: Future<List<String>> - List of verses for the specified Surah
  /// Throws: Exception if the file cannot be read or parsed
  Future<List<String>> getVersesForSurah(int surahNumber) async {
    try {
      if (surahNumber < 1 || surahNumber > 114) {
        throw Exception('Invalid Surah number: $surahNumber');
      }

      // Build the file path
      final fileName = '$surahNumber.txt';
      final filePath = path.join('assets', 'ayaat', fileName);

      // Read the file content
      String content;
      try {
        content = await rootBundle.loadString(filePath);
      } catch (e) {
        throw Exception(
          'Could not find verses file for Surah $surahNumber at $filePath',
        );
      }

      // Split the content into verses based on new lines
      List<String> lines = LineSplitter.split(content).toList();

      // Filter out empty lines and trim whitespace
      final verses = lines
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.trim())
          .toList();

      return verses;
    } catch (e) {
      throw Exception(
        'Error reading verses for Surah $surahNumber: ${e.toString()}',
      );
    }
  }

  /// Reads all verses for all Surahs from the assets folder
  ///
  /// Returns: Future<Map<int, List<String>>>
  /// Where the key is the Surah number and the value is the list of verses
  Future<Map<int, List<String>>> getAllVerses() async {
    try {
      final allVerses = <int, List<String>>{};

      // Process all 114 Surahs
      for (int surahNumber = 1; surahNumber <= 114; surahNumber++) {
        try {
          final verses = await getVersesForSurah(surahNumber);
          allVerses[surahNumber] = verses;
        } catch (e) {
          // Continue processing other Surahs even if one fails
          developer.log(
            'Could not load verses for Surah $surahNumber',
            name: 'sakina_app.quran_data',
            level: 900,
            error: e,
          );
        }
      }

      return allVerses;
    } catch (e) {
      throw Exception('Error reading all Quran verses: ${e.toString()}');
    }
  }

  /// Gets the total number of verses in a specific Surah
  ///
  /// Parameters:
  /// - [surahNumber]: The Surah number (1-114)
  ///
  /// Returns: Future<int> - Number of verses in the specified Surah
  Future<int> getVerseCountForSurah(int surahNumber) async {
    final verses = await getVersesForSurah(surahNumber);
    return verses.length;
  }
}
