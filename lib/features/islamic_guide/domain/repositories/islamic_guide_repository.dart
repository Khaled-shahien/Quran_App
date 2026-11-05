import '../../../../core/result/result.dart';
import '../entities/guide_entities.dart';

abstract class IslamicGuideRepository {
  /// Loads all guide sections from the bundled asset.
  Future<Result<List<GuideSection>>> getSections();

  /// Resolves a Quran reference to the verses' text from the Quran asset.
  Future<Result<List<GuideVerse>>> resolveQuran(QuranRef ref);
}
