import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sakina_app/features/duas/data/models/azkar_model.dart';

/// Contract for loading Quran duas categories from a data source.
abstract class DuasRepository {
  /// Returns all duas categories with their items.
  Future<List<AzkarCategoryModel>> getAllDuas();
}

/// Asset-backed implementation for [DuasRepository].
class DuasRepositoryImpl implements DuasRepository {
  @override
  /// Loads and parses `assets/quran_duas.json`.
  ///
  /// Throws an [Exception] when the asset cannot be read or parsed.
  Future<List<AzkarCategoryModel>> getAllDuas() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/quran_duas.json',
      );
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => AzkarCategoryModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load duas data: $e');
    }
  }
}
