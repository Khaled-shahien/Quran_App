import '../entities/ayah_entity.dart';

/// Normalizes only the search index. The displayed Quran text stays untouched.
String normalizeArabicSearch(String text) => text
    .replaceAll(
      RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]'),
      '',
    )
    .replaceAll(RegExp('[أإآٱ]'), 'ا')
    .replaceAll('ى', 'ي')
    .toLowerCase();

class QuranSearchResult {
  const QuranSearchResult(this.surahNumber, this.ayah, this.start, this.end);
  final int surahNumber;
  final AyahEntity ayah;
  final int start;
  final int end;
}

List<QuranSearchResult> searchQuran(
  Map<int, List<AyahEntity>> source,
  String query,
) {
  final needle = normalizeArabicSearch(query).trim();
  if (needle.isEmpty) return [];
  final results = <QuranSearchResult>[];
  for (final surah in source.entries) {
    for (final ayah in surah.value) {
      final normalized = normalizeArabicSearch(ayah.text);
      final match = normalized.indexOf(needle);
      if (match < 0) continue;
      final offsets = <int>[];
      for (var i = 0; i < ayah.text.length; i++) {
        if (normalizeArabicSearch(ayah.text[i]).isNotEmpty) offsets.add(i);
      }
      final endIndex = match + needle.length;
      results.add(
        QuranSearchResult(
          surah.key,
          ayah,
          offsets[match],
          endIndex < offsets.length ? offsets[endIndex] : ayah.text.length,
        ),
      );
    }
  }
  results.sort((a, b) {
    final order = a.surahNumber.compareTo(b.surahNumber);
    return order == 0
        ? a.ayah.numberInSurah.compareTo(b.ayah.numberInSurah)
        : order;
  });
  return results;
}
