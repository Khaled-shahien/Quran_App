import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/core/utils/arabic_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/surah_entity.dart';
import '../../domain/repositories/surah_repository.dart';
import '../data_sources/local_surah_data_source.dart';
import '../models/surah_model.dart';

/// Surah metadata from the bundled Quran asset, kept in memory once loaded.
class SurahRepositoryImpl implements SurahRepository {
  SurahRepositoryImpl({
    required LocalSurahDataSource localDataSource,
    SharedPreferences? sharedPreferences,
  }) : _localDataSource = localDataSource {
    // Earlier versions copied the bundled list into preferences, which only
    // slowed startup. Drop those copies.
    for (final key in const ['cached_surahs', 'cached_surahs_timestamp']) {
      sharedPreferences?.remove(key);
    }
  }

  final LocalSurahDataSource _localDataSource;
  List<SurahEntity>? _surahs;

  static SurahEntity _toEntity(SurahModel model) => SurahEntity(
    number: model.number,
    name: displaySurahName(model.name),
    englishName: model.englishName,
    englishNameTranslation: model.englishNameTranslation,
    revelationType: model.revelationType,
    totalAyah: model.numberOfAyahs,
  );

  @override
  Future<Result<List<SurahEntity>>> getAllSurahs() async {
    final cached = _surahs;
    if (cached != null) return Success(cached);
    return Result.guard(() async {
      final surahs = List<SurahEntity>.unmodifiable(
        (await _localDataSource.loadAllSurahs()).map(_toEntity),
      );
      if (surahs.isEmpty) throw StateError('No surahs in the bundled asset');
      return _surahs = surahs;
    }, onError: (error, _) => ContentFailure(cause: error));
  }

  @override
  Future<Result<SurahEntity>> getSurahByIndex(int index) async {
    final result = await getAllSurahs();
    return switch (result) {
      Success(:final value) when index >= 1 && index <= value.length => Success(
        value[index - 1],
      ),
      Success() => Err(
        ContentFailure(cause: RangeError.range(index, 1, 114, 'surah')),
      ),
      Err(:final failure) => Err(failure),
    };
  }
}
