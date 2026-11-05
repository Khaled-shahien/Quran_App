import 'package:sakina_app/core/result/result.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/ayah_entity.dart';
import '../../domain/repositories/ayah_repository.dart';
import '../data_sources/local_quran_data_source.dart';
import '../models/ayah_model.dart';

/// Ayahs from the bundled Quran asset. The data source keeps the decoded
/// asset in memory, so no other cache is needed.
class AyahRepositoryImpl implements AyahRepository {
  AyahRepositoryImpl({
    required LocalQuranDataSource localDataSource,
    SharedPreferences? sharedPreferences,
  }) : _localDataSource = localDataSource {
    // Earlier versions copied whole surahs into preferences (up to the full
    // Quran over time), which slowed every startup. Drop those copies.
    final prefs = sharedPreferences;
    if (prefs == null) return;
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith('cached_ayahs_surah_') ||
          key.startsWith('cached_ayahs_timestamp_surah_')) {
        prefs.remove(key);
      }
    }
  }

  final LocalQuranDataSource _localDataSource;

  static AyahEntity _toEntity(AyahModel model) => AyahEntity(
    number: model.number,
    text: model.text,
    numberInSurah: model.numberInSurah,
    juz: model.juz,
    manzil: model.manzil,
    page: model.page,
    ruku: model.ruku,
    hizbQuarter: model.hizbQuarter,
    sajda: model.sajda,
  );

  @override
  Future<Result<List<AyahEntity>>> getAyahsForSurah(int surahNumber) {
    return Result.guard(() async {
      if (surahNumber < 1 || surahNumber > 114) {
        throw RangeError.range(surahNumber, 1, 114, 'surahNumber');
      }
      final ayahs = await _localDataSource.getAyahsForSurah(surahNumber);
      return List<AyahEntity>.unmodifiable(ayahs.map(_toEntity));
    }, onError: (error, _) => ContentFailure(cause: error));
  }

  @override
  Future<Result<Map<int, List<AyahEntity>>>> getAllAyahs() {
    return Result.guard(() async {
      final all = await _localDataSource.getAllAyahs();
      if (all.length != 114 || all.values.any((ayahs) => ayahs.isEmpty)) {
        throw StateError('Incomplete Quran asset');
      }
      return <int, List<AyahEntity>>{
        for (final entry in all.entries)
          entry.key: List<AyahEntity>.unmodifiable(entry.value.map(_toEntity)),
      };
    }, onError: (error, _) => ContentFailure(cause: error));
  }
}
