import 'package:sakina_app/core/result/result.dart';

import '../entities/surah_entity.dart';

abstract class SurahRepository {
  /// All 114 surahs in order, or a [ContentFailure].
  Future<Result<List<SurahEntity>>> getAllSurahs();

  /// Surah [index] (1-114), or a failure when it is out of range.
  Future<Result<SurahEntity>> getSurahByIndex(int index);
}
