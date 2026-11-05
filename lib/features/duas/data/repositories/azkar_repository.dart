import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/features/duas/domain/repositories/azkar_repository.dart';
import '../models/azkar_model.dart';

export 'package:sakina_app/features/duas/domain/repositories/azkar_repository.dart';

/// Asset-backed implementation for [AzkarRepository].
class AzkarRepositoryImpl implements AzkarRepository {
  AzkarRepositoryImpl({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  /// Loads and parses `assets/prayers_data.json`. The text is returned exactly
  /// as stored; nothing is trimmed or normalized.
  @override
  Future<Result<List<AzkarCategoryModel>>> getAllAzkar() => Result.guard(
    () async => parseAzkarCategories(
      await _bundle.loadString('assets/prayers_data.json'),
    ),
    onError: (error, _) => ContentFailure(cause: error),
  );
}

/// Shared by the adhkar and duas assets, which use the same schema.
List<AzkarCategoryModel> parseAzkarCategories(String jsonString) {
  final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
  return jsonList
      .map((json) => AzkarCategoryModel.fromJson(json as Map<String, dynamic>))
      .toList();
}
