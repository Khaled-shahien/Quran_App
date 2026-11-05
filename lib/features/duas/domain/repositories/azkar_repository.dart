import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/features/duas/data/models/azkar_model.dart';

/// Contract for loading adhkar categories.
abstract class AzkarRepository {
  /// All adhkar categories with their items, or a [ContentFailure].
  Future<Result<List<AzkarCategoryModel>>> getAllAzkar();
}
