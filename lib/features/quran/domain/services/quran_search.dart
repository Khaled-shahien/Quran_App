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

/// Searches with a one-off index; screens keep a [QuranSearchIndex].
List<QuranSearchResult> searchQuran(
  Map<int, List<AyahEntity>> source,
  String query,
) => QuranSearchIndex(source).search(query);

/// How well an ayah matches: the whole word, the start of a word, or
/// inside a word. Better matches are listed first.
enum QuranMatchRank { word, wordStart, inside }

/// Normalised text of every ayah, built once, with the position in the
/// original text of each normalised character (for highlighting).
class QuranSearchIndex {
  QuranSearchIndex(Map<int, List<AyahEntity>> source)
    : _entries = [
        for (final surah in source.entries)
          for (final ayah in surah.value) _IndexedAyah.of(surah.key, ayah),
      ];

  final List<_IndexedAyah> _entries;

  int get length => _entries.length;

  /// Ayahs containing [query] (marks, hamza forms and tatweel ignored),
  /// whole-word matches first, then in mushaf order.
  List<QuranSearchResult> search(String query) {
    final needle = normalizeArabicSearch(query).trim();
    if (needle.isEmpty) return [];
    final ranked = <(QuranMatchRank, QuranSearchResult)>[];
    for (final entry in _entries) {
      final match = entry.bestMatch(needle);
      if (match == null) continue;
      final (rank, at) = match;
      final end = at + needle.length;
      ranked.add((
        rank,
        QuranSearchResult(
          entry.surah,
          entry.ayah,
          entry.offsets[at],
          end < entry.offsets.length
              ? entry.offsets[end]
              : entry.ayah.text.length,
        ),
      ));
    }
    ranked.sort((a, b) {
      final rank = a.$1.index.compareTo(b.$1.index);
      if (rank != 0) return rank;
      final surah = a.$2.surahNumber.compareTo(b.$2.surahNumber);
      return surah != 0
          ? surah
          : a.$2.ayah.numberInSurah.compareTo(b.$2.ayah.numberInSurah);
    });
    return [for (final r in ranked) r.$2];
  }

  /// The normalised text of each ayah, for tests.
  Iterable<String> get normalizedTexts => _entries.map((e) => e.normalized);
}

/// Same rules as [normalizeArabicSearch], one character at a time.
int? _normalizeUnit(int c) {
  if ((c >= 0x0610 && c <= 0x061A) ||
      (c >= 0x064B && c <= 0x065F) ||
      c == 0x0670 ||
      (c >= 0x06D6 && c <= 0x06ED) ||
      c == 0x0640) {
    return null;
  }
  if (c == 0x0623 || c == 0x0625 || c == 0x0622 || c == 0x0671) return 0x0627;
  if (c == 0x0649) return 0x064A;
  if (c >= 0x41 && c <= 0x5A) return c + 32;
  return c;
}

/// A text normalised for search, keeping where each normalised character
/// came from so a match can be shown in the original text.
class NormalizedText {
  NormalizedText._(this.original, this.normalized, this.offsets);

  factory NormalizedText(String text) {
    final buffer = StringBuffer();
    final offsets = <int>[];
    for (var i = 0; i < text.length; i++) {
      final mapped = _normalizeUnit(text.codeUnitAt(i));
      if (mapped == null) continue;
      buffer.writeCharCode(mapped);
      offsets.add(i);
    }
    return NormalizedText._(text, buffer.toString(), offsets);
  }

  final String original;
  final String normalized;
  final List<int> offsets;

  static bool _isSpace(String text, int i) =>
      i < 0 ||
      i >= text.length ||
      text.codeUnitAt(i) == 0x20 ||
      text.codeUnitAt(i) == 0x0A;

  /// The best occurrence of an already normalised [needle]: a whole word
  /// if there is one, else a word start, else the first.
  (QuranMatchRank, int)? bestMatch(String needle) {
    (QuranMatchRank, int)? best;
    var from = 0;
    while (true) {
      final at = normalized.indexOf(needle, from);
      if (at < 0) return best;
      final startsWord = _isSpace(normalized, at - 1);
      final endsWord = _isSpace(normalized, at + needle.length);
      final rank = startsWord && endsWord
          ? QuranMatchRank.word
          : startsWord
          ? QuranMatchRank.wordStart
          : QuranMatchRank.inside;
      if (best == null || rank.index < best.$1.index) best = (rank, at);
      if (rank == QuranMatchRank.word) return best;
      from = at + 1;
    }
  }

  /// The match of [query] in [original] and its rank, or null.
  ({int start, int end, QuranMatchRank rank})? find(String query) {
    final needle = normalizeArabicSearch(query).trim();
    if (needle.isEmpty) return null;
    final match = bestMatch(needle);
    if (match == null) return null;
    final (rank, at) = match;
    final end = at + needle.length;
    return (
      start: offsets[at],
      end: end < offsets.length ? offsets[end] : original.length,
      rank: rank,
    );
  }
}

class _IndexedAyah {
  _IndexedAyah(this.surah, this.ayah) : text = NormalizedText(ayah.text);

  factory _IndexedAyah.of(int surah, AyahEntity ayah) =>
      _IndexedAyah(surah, ayah);

  final int surah;
  final AyahEntity ayah;
  final NormalizedText text;

  String get normalized => text.normalized;
  List<int> get offsets => text.offsets;

  (QuranMatchRank, int)? bestMatch(String needle) => text.bestMatch(needle);
}
