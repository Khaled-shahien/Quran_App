import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/quran/data/data_sources/quran_master_asset.dart';
import 'package:sakina_app/features/quran/domain/services/quran_divisions.dart';

void main() {
  late QuranDivisions divisions;
  late List<Map<String, dynamic>> surahs;

  setUpAll(() {
    surahs = QuranMasterAsset.parse(
      File(QuranMasterAsset.path).readAsStringSync(),
    );
    divisions = QuranDivisions.fromSurahs(surahs);
  });

  int ayahCount(int surah) =>
      (surahs[surah - 1]['ayahs'] as List<dynamic>).length;

  test('the bundled mushaf has 30 juz, 60 hizb and 604 pages', () {
    expect(divisions.juz, hasLength(30));
    expect(divisions.hizb, hasLength(60));
    expect(divisions.pages, hasLength(604));
  });

  test('well-known division starts match the Madinah mushaf', () {
    // Juz 2 begins at al-Baqarah 142, Juz 30 at an-Naba 1.
    expect((divisions.juz[1].surah, divisions.juz[1].ayah), (2, 142));
    expect((divisions.juz[29].surah, divisions.juz[29].ayah), (78, 1));
    expect(divisions.juz[29].page, 582);
    // Hizb 2 begins at al-Baqarah 75.
    expect((divisions.hizb[1].surah, divisions.hizb[1].ayah), (2, 75));
    // Page 1 is al-Fatihah, page 2 begins al-Baqarah.
    expect((divisions.pages[0].surah, divisions.pages[0].ayah), (1, 1));
    expect((divisions.pages[1].surah, divisions.pages[1].ayah), (2, 1));
    expect(divisions.pageStart(605), isNull);
  });

  test('a damaged asset is rejected instead of half-indexed', () {
    final List<Map<String, dynamic>> truncated = surahs.sublist(0, 100);
    expect(() => QuranDivisions.fromSurahs(truncated), throwsFormatException);
  });

  group('go to', () {
    test('verse references in Western and Arabic-Indic digits', () {
      final a = parseQuranGoTo('2:255', ayahCount);
      final b = parseQuranGoTo('٢:٢٥٥', ayahCount);
      final c = parseQuranGoTo(' 18 10 ', ayahCount);
      for (final g in [a, b]) {
        expect(g, isA<QuranGoToVerse>());
        expect((g! as QuranGoToVerse).surah, 2);
        expect((g as QuranGoToVerse).ayah, 255);
      }
      expect((c! as QuranGoToVerse).surah, 18);
    });

    test('a lone number is a page', () {
      expect((parseQuranGoTo('٦٠٤', ayahCount)! as QuranGoToPage).page, 604);
    });

    test('impossible targets are rejected', () {
      expect(parseQuranGoTo('1:8', ayahCount), isNull);
      expect(parseQuranGoTo('115:1', ayahCount), isNull);
      expect(parseQuranGoTo('0', ayahCount), isNull);
      expect(parseQuranGoTo('605', ayahCount), isNull);
      expect(parseQuranGoTo('abc', ayahCount), isNull);
      expect(parseQuranGoTo('', ayahCount), isNull);
    });
  });
}
