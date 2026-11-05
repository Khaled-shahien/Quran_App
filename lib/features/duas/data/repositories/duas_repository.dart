import 'package:flutter/services.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/features/duas/data/models/azkar_model.dart';
import 'package:sakina_app/features/duas/data/repositories/azkar_repository.dart'
    show parseAzkarCategories;
import 'package:sakina_app/features/duas/domain/repositories/duas_repository.dart';

export 'package:sakina_app/features/duas/domain/repositories/duas_repository.dart';

/// Asset-backed implementation for [DuasRepository].
class DuasRepositoryImpl implements DuasRepository {
  DuasRepositoryImpl({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  /// Loads and parses `assets/quran_duas.json` without altering any text.
  @override
  Future<Result<List<AzkarCategoryModel>>> getAllDuas() => Result.guard(
    () async => parseAzkarCategories(
      await _bundle.loadString('assets/quran_duas.json'),
    ),
    onError: (error, _) => ContentFailure(cause: error),
  );
}
