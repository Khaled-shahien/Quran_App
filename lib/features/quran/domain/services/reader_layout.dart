/// How the Quran reader lays out its text.
enum ReaderLayout {
  /// One vertical scroll of flowing text (the default).
  continuous,

  /// One mushaf page per swipe. Page boundaries follow the mushaf; line
  /// breaks follow the screen.
  pages,

  /// One verse per row.
  verses;

  /// The stored name, or [continuous] for anything unknown.
  static ReaderLayout parse(Object? value) => ReaderLayout.values.firstWhere(
    (layout) => layout.name == value,
    orElse: () => ReaderLayout.continuous,
  );
}

/// [number] written with Arabic-Indic digits (٠–٩), as verse numbers are
/// written in the mushaf.
String toArabicIndicDigits(int number) {
  const int zero = 0x0660;
  return String.fromCharCodes(
    number.toString().codeUnits.map((unit) => zero + (unit - 0x30)),
  );
}

/// The end-of-ayah sign for verse [number]: U+06DD followed by the number.
/// Quran fonts draw the ornament around the digits.
///
/// This is added when a verse is displayed. It is never part of the stored
/// verse text and is never copied with it.
String ayahEndMarker(int number) => '۝${toArabicIndicDigits(number)}';

/// One verse as the old reader measured it.
typedef LegacyVerse = ({int ayah, int length, bool basmala});

/// The first ayah of page [pageIndex] under the reader's old pagination,
/// which closed a page once it held 550 characters.
///
/// Bookmarks used to store that page index. This replays the same packing
/// so an old bookmark can be turned into the verse it pointed at. Returns
/// null when the index is out of range.
int? legacyPageLeadAyah({
  required List<LegacyVerse> verses,
  required int pageIndex,
  required int basmalaLength,
}) {
  const int maxCharsPerPage = 550;
  if (pageIndex < 0) return null;
  int page = 0;
  int length = 0;
  int? lead;
  for (final LegacyVerse verse in verses) {
    if (verse.length == 0) continue;
    lead ??= verse.ayah;
    length += verse.length;
    if (verse.basmala) length += basmalaLength;
    if (length >= maxCharsPerPage) {
      if (page == pageIndex) return lead;
      page++;
      length = 0;
      lead = null;
    }
  }
  return page == pageIndex ? lead : null;
}

/// Splits verses into mushaf pages: consecutive runs of the same page
/// number. Returns the indices of each run, in order.
///
/// Only the page number decides a break, so a page where one surah ends
/// and the next begins stays one page.
List<List<int>> groupByMushafPage(List<int> pageNumbers) {
  final List<List<int>> pages = <List<int>>[];
  for (int i = 0; i < pageNumbers.length; i++) {
    if (pages.isEmpty || pageNumbers[i] != pageNumbers[i - 1]) {
      pages.add(<int>[]);
    }
    pages.last.add(i);
  }
  return pages;
}
