/// Helpers for rendering Arabic labels (not Quranic text) in UI fonts.
///
/// The Quran asset stores surah names in Uthmani orthography, e.g.
/// `س\u064Fور\u064Eة\u064F آل\u0650 ع\u0650م\u06E1ر\u064Eان\u064E`. Characters such as the Uthmani sukun (U+06E1),
/// alef wasla (U+0671), small high marks (U+06D6–U+06ED) and tatweel (U+0640)
/// are not covered by UI fonts like Cairo. When a glyph is missing the engine
/// falls back to another font for that character, which breaks letter joining
/// and makes the word look "cut apart". Labels are therefore rendered as plain
/// Arabic letters without diacritics.
library;

final RegExp _arabicMarks = RegExp(
  '[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED\u0640\uFEFF]',
);

/// Strips harakat, Uthmani annotation marks and tatweel, and maps alef wasla
/// to a plain alef, so the label joins correctly in any Arabic UI font.
String plainArabic(String input) {
  return input
      .replaceAll('\u0671', 'ا')
      .replaceAll(_arabicMarks, '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Display-safe surah name: `س\u064Fور\u064Eة\u064F \u0671ل\u0652ف\u064Eات\u0650ح\u064Eة\u0650` → `سورة الفاتحة`.
String displaySurahName(String rawName) => plainArabic(rawName);
