import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/features/duas/data/models/azkar_model.dart';

/// Contract for loading dua categories.
abstract class DuasRepository {
  /// All dua categories with their items, or a [ContentFailure].
  Future<Result<List<AzkarCategoryModel>>> getAllDuas();
}
