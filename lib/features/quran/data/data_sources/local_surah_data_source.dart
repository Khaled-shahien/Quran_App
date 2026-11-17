import '../models/surah_model.dart';
import 'quran_master_asset.dart';

/// Local Surah Data Source
///
/// Reads surah metadata (and ayahs) from the bundled Quran.
class LocalSurahDataSource {
  /// All 114 surahs, in order.
  ///
  /// A missing or damaged asset is an error, never replaced by built-in
  /// data: the caller shows its error state, and the content integrity gate
  /// keeps the asset itself correct.
  Future<List<SurahModel>> loadAllSurahs() async => [
    for (final Map<String, dynamic> surah in await QuranMasterAsset.load())
      SurahModel.fromJson(surah),
  ];
}
