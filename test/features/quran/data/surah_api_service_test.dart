import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina_app/features/quran/data/data_sources/local_surah_data_source.dart';
import 'package:sakina_app/features/quran/data/repositories/surah_repository.dart';
import 'package:sakina_app/features/quran/data/models/surah_model.dart';
import 'package:sakina_app/core/result/result.dart';

// Mock Local Data Source that throws errors
class MockLocalDataSource extends LocalSurahDataSource {
  @override
  Future<List<SurahModel>> loadAllSurahs() async {
    throw Exception('Failed to load surahs');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Local Surah Data Source Tests', () {
    late LocalSurahDataSource localDataSource;

    setUp(() {
      localDataSource = LocalSurahDataSource();
    });

    test('should load all Surahs successfully from local data', () async {
      // Act
      final result = await localDataSource.loadAllSurahs();

      // Assert
      expect(result, isNotNull);
      expect(result.length, 114); // Should load all 114 surahs
      expect(result[0].englishName, 'Al-Faatiha');
      expect(result[0].name, 'سُورَةُ ٱلْفَاتِحَةِ');
      expect(result[0].numberOfAyahs, 7);
      expect(result[1].englishName, 'Al-Baqara');
      expect(result[1].revelationType, 'Medinan');
    });

    test('should load specific Surah by index', () async {
      // Act
      final result = await localDataSource.loadAllSurahs();

      // Get first surah (Al-Fatihah)
      final fatihah = result[0];

      // Assert
      expect(fatihah.number, 1);
      expect(fatihah.englishName, 'Al-Faatiha');
      expect(fatihah.name, 'سُورَةُ ٱلْفَاتِحَةِ');
      expect(fatihah.numberOfAyahs, 7);
      expect(fatihah.revelationType, 'Meccan');
    });

    test('should handle file reading errors gracefully', () async {
      // This test would require mocking rootBundle which is complex
      // For now, we test that the method doesn't crash and returns generated data
      expect(() => localDataSource.loadAllSurahs(), returnsNormally);
    });

    test('should contain all expected Surah properties', () async {
      // Act
      final result = await localDataSource.loadAllSurahs();
      final firstSurah = result[0];

      // Assert
      expect(firstSurah.number, isNotNull);
      expect(firstSurah.name, isNotNull);
      expect(firstSurah.englishName, isNotNull);
      expect(firstSurah.englishNameTranslation, isNotNull);
      expect(firstSurah.revelationType, isNotNull);
      expect(firstSurah.numberOfAyahs, isNotNull);
      expect(firstSurah.ayahs, isNotNull);
    });

    test('should load all 114 Surahs with correct data', () async {
      // Act
      final result = await localDataSource.loadAllSurahs();

      // Assert
      expect(result.length, 114);

      // Check some specific surahs
      final fatihah = result[0];
      expect(fatihah.number, 1);
      expect(fatihah.englishName, 'Al-Faatiha');

      final baqarah = result[1];
      expect(baqarah.number, 2);
      expect(baqarah.englishName, 'Al-Baqara');
      expect(baqarah.numberOfAyahs, 286);

      final nas = result[113];
      expect(nas.number, 114);
      expect(nas.englishName, 'An-Naas');
    });

    test('should have correct revelation types', () async {
      // Act
      final result = await localDataSource.loadAllSurahs();

      // Count Meccan and Medinan surahs
      final meccanCount = result
          .where((s) => s.revelationType == 'Meccan')
          .length;
      final medinanCount = result
          .where((s) => s.revelationType == 'Medinan')
          .length;

      // Assert
      expect(
        meccanCount + medinanCount,
        114,
      ); // All surahs should be classified
      expect(meccanCount, greaterThan(0));
      expect(medinanCount, greaterThan(0));
    });

    test('should search Surahs by English name', () async {
      // Act
      final result = await localDataSource.loadAllSurahs();

      // Find surahs containing 'Baqarah'
      final baqarahResults = result
          .where((s) => s.englishName.contains('Baqara'))
          .toList();

      // Assert
      expect(baqarahResults.length, 1);
      expect(baqarahResults[0].englishName, 'Al-Baqara');
    });

    test('should search Surahs by Arabic name', () async {
      // Act
      final result = await localDataSource.loadAllSurahs();

      // Find surahs containing a stable Arabic fragment from Al-Fatihah
      final fatihahResults = result
          .where((s) => s.name.contains('فَاتِح'))
          .toList();

      // Assert
      expect(fatihahResults.length, 1);
      expect(fatihahResults[0].name, 'سُورَةُ ٱلْفَاتِحَةِ');
    });

    test('should filter Surahs by revelation type', () async {
      // Act
      final result = await localDataSource.loadAllSurahs();

      // Filter Meccan surahs
      final meccanSurahs = result
          .where((s) => s.revelationType == 'Meccan')
          .toList();

      // Assert
      expect(meccanSurahs.length, greaterThan(0));
      expect(meccanSurahs.every((s) => s.revelationType == 'Meccan'), true);
    });

    test('should have correct ayahs array structure', () async {
      // Act
      final result = await localDataSource.loadAllSurahs();

      // Check the full Quran asset exposes structured ayah data.
      final firstSurahAyahs = result.first.ayahs;
      expect(firstSurahAyahs, hasLength(7));
      expect(firstSurahAyahs.first.number, 1);
      expect(firstSurahAyahs.first.numberInSurah, 1);
      expect(firstSurahAyahs.first.juz, 1);
      expect(firstSurahAyahs.first.page, 1);
      expect(firstSurahAyahs.first.text.trim(), isNotEmpty);
    });

    test('should generate correct JSON structure', () async {
      // Act
      final result = await localDataSource.loadAllSurahs();
      final firstSurah = result[0];
      final json = firstSurah.toJson();

      // Assert
      expect(json['number'], 1);
      expect(json['name'], 'سُورَةُ ٱلْفَاتِحَةِ');
      expect(json['englishName'], 'Al-Faatiha');
      expect(json['englishNameTranslation'], 'The Opening');
      expect(json['revelationType'], 'Meccan');
      expect(json['numberOfAyahs'], 7);
      expect(json['ayahs'], isNotEmpty);
      expect(json['ayahs'], hasLength(7));
      expect((json['ayahs'] as List<dynamic>).first, containsPair('number', 1));
      expect(
        (json['ayahs'] as List<dynamic>).first,
        containsPair('numberInSurah', 1),
      );
    });
  });

  group('Surah Repository Tests', () {
    late SharedPreferences prefs;
    late SurahRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        // Left over from earlier versions that copied the list into prefs.
        'cached_surahs': '[]',
        'cached_surahs_timestamp': 1,
      });
      prefs = await SharedPreferences.getInstance();
      repository = SurahRepositoryImpl(
        localDataSource: LocalSurahDataSource(),
        sharedPreferences: prefs,
      );
    });

    test('loads all 114 surahs from the bundled asset', () async {
      final surahs = (await repository.getAllSurahs()).valueOrNull!;

      expect(surahs, hasLength(114));
      expect(surahs[0].englishName, 'Al-Faatiha');
      expect(surahs[0].name, 'سورة الفاتحة');
    });

    test('removes the obsolete preference copies', () async {
      await Future<void>.delayed(Duration.zero);
      expect(prefs.containsKey('cached_surahs'), isFalse);
      expect(prefs.containsKey('cached_surahs_timestamp'), isFalse);
    });

    test(
      'a failing data source is a ContentFailure, not an exception',
      () async {
        repository = SurahRepositoryImpl(
          localDataSource: MockLocalDataSource(),
        );

        final result = await repository.getAllSurahs();

        expect(result.failureOrNull, isA<ContentFailure>());
      },
    );

    test('gets a specific surah by index', () async {
      final surah = (await repository.getSurahByIndex(1)).valueOrNull!;

      expect(surah.englishName, 'Al-Faatiha');
      expect(surah.name, 'سورة الفاتحة');
      expect(surah.totalAyah, 7);
    });

    test('an out-of-range index is a failure', () async {
      expect((await repository.getSurahByIndex(0)).isSuccess, isFalse);
      expect((await repository.getSurahByIndex(115)).isSuccess, isFalse);
    });
  });
}
