import 'package:sakina_app/core/result/result.dart';

import '../models/khatma_model.dart';
import '../models/wird_reading_position.dart';

/// Persists the active khatma plan and the saved wird reading position.
abstract interface class KhatmaRepository {
  /// The saved plan, `Success(null)` when there is none, or a
  /// [StorageFailure] when stored data cannot be read.
  Result<KhatmaModel?> getActiveKhatma();
  Future<Result<void>> saveKhatma(KhatmaModel khatma);
  Future<Result<void>> deleteActiveKhatma();

  Result<WirdReadingPosition?> getSavedWirdPosition();
  Future<Result<void>> saveWirdPosition(WirdReadingPosition position);
  Future<Result<void>> clearWirdPosition();
}
