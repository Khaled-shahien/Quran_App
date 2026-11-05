import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/features/duas/data/models/azkar_model.dart';

/// The adhkar for hearing the adhan, including the dua after it
/// (Hisn al-Muslim, chapter on the adhan).
abstract class AdhanAdhkarRepository {
  Future<Result<List<AzkarItemModel>>> getAdhanAdhkar();
}
