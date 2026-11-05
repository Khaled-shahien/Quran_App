import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/features/quran/domain/entities/tasbih_phrase.dart';

/// Persists tasbih phrases and counts across app restarts and updates.
abstract class TasbihRepository {
  /// The saved state, `Success(null)` on first run, or a [StorageFailure]
  /// when stored data cannot be read.
  Result<TasbihSnapshot?> load();

  Future<Result<void>> save(TasbihSnapshot snapshot);
}
