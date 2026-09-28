import 'package:flutter_test/flutter_test.dart';
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
}
