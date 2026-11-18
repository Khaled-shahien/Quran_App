import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/quran/data/data_sources/quran_master_asset.dart';
import 'package:sakina_app/features/quran/domain/entities/ayah_entity.dart';
import 'package:sakina_app/features/quran/domain/services/quran_search.dart';

void main() {
  final ayah = AyahEntity(
    number: 1,
    text: 'بِسْمِ ٱللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
    numberInSurah: 1,
    juz: 1,
    manzil: 1,
    page: 1,
    ruku: 1,
    hizbQuarter: 1,
    sajda: false,
  );
  test(
    'matches undiacritized Arabic while preserving text and exact location',
    () {
      final result = searchQuran({
        1: [ayah],
      }, 'الله الرحمن').single;
      expect(result.surahNumber, 1);
      expect(result.ayah, same(ayah));
      expect(
        normalizeArabicSearch(
          ayah.text.substring(result.start, result.end),
        ).trim(),
        'الله الرحمن',
      );
    },
  );
  test('empty, marks-only, and absent queries have no matches', () {
    for (final query in ['', '  ', 'َُ', 'غير موجود']) {
      expect(
        searchQuran({
          1: [ayah],
        }, query),
        isEmpty,
      );
    }
  });
  test('normalizes hamza, alif maqsura, and tatweel', () {
    expect(normalizeArabicSearch('إلى آيـات'), 'الي ايات');
  });

  group('index', () {
    AyahEntity a(int n, String text) => AyahEntity(
      number: n,
      text: text,
      numberInSurah: n,
      juz: 1,
      manzil: 1,
      page: 1,
      ruku: 1,
      hizbQuarter: 1,
      sajda: false,
    );

    test('whole-word matches come first, then word starts, then inside', () {
      final index = QuranSearchIndex({
        1: [a(1, 'فصبر صبر'), a(2, 'واصبر وما صبرك'), a(3, 'اصبر')],
        2: [a(1, 'صبر جميل')],
      });
      final results = index.search('صبر');
      expect(
        [for (final r in results) (r.surahNumber, r.ayah.numberInSurah)],
        [(1, 1), (2, 1), (1, 2), (1, 3)],
      );
    });

    test('highlights the original text of the best occurrence', () {
      final ayah = a(1, 'وَٱصْبِرْ وَمَا صَبْرُكَ');
      final result = QuranSearchIndex({
        1: [ayah],
      }).search('صبرك').single;
      expect(ayah.text.substring(result.start, result.end), 'صَبْرُكَ');
    });
  });

  test(
    'the index normalises the whole Quran exactly like the search box',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final surahs = await QuranMasterAsset.load();
      final source = {
        for (final s in surahs)
          s['number'] as int: [
            for (final ayah
                in (s['ayahs'] as List).cast<Map<String, dynamic>>())
              a0(ayah),
          ],
      };
      final index = QuranSearchIndex(source);
      expect(index.length, 6236);
      final expected = [
        for (final list in source.values)
          for (final ayah in list) normalizeArabicSearch(ayah.text),
      ];
      expect(index.normalizedTexts.toList(), expected);
    },
  );
}

AyahEntity a0(Map<String, dynamic> json) => AyahEntity(
  number: json['number'] as int,
  text: json['text'] as String,
  numberInSurah: json['numberInSurah'] as int,
  juz: 1,
  manzil: 1,
  page: json['page'] as int,
  ruku: 1,
  hizbQuarter: 1,
  sajda: false,
);
