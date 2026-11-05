import 'package:sakina_app/core/result/result.dart';

import '../entities/ayah_entity.dart';

abstract class AyahRepository {
  /// The ayahs of [surahNumber] (1-114), text exactly as bundled.
  Future<Result<List<AyahEntity>>> getAyahsForSurah(int surahNumber);

  /// Every surah's ayahs keyed by surah number (used by search).
  Future<Result<Map<int, List<AyahEntity>>>> getAllAyahs();
}
