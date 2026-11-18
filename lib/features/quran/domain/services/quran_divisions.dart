/// Where a Juz, Hizb or mushaf page begins.
class QuranDivisionStart {
  const QuranDivisionStart({
    required this.number,
    required this.surah,
    required this.ayah,
    required this.page,
  });

  /// 1-based number of the division (Juz 1–30, Hizb 1–60, page 1–604).
  final int number;
  final int surah;
  final int ayah;

  /// The mushaf page the first ayah is on.
  final int page;
}

/// The Juz, Hizb and page starts of the mushaf, read from the per-ayah
/// `juz`, `hizbQuarter` and `page` fields of `assets/quran_master.json`.
class QuranDivisions {
  const QuranDivisions({
    required this.juz,
    required this.hizb,
    required this.pages,
  });

  static const int juzCount = 30;
  static const int hizbCount = 60;
  static const int pageCount = 604;

  final List<QuranDivisionStart> juz;
  final List<QuranDivisionStart> hizb;
  final List<QuranDivisionStart> pages;

  /// Builds the index from the decoded asset (surahs in order, each with
  /// `number` and `ayahs`). Throws [FormatException] if a division is
  /// missing, so a damaged asset is reported instead of half-shown.
  factory QuranDivisions.fromSurahs(List<Map<String, dynamic>> surahs) {
    final List<QuranDivisionStart> juz = [];
    final List<QuranDivisionStart> hizb = [];
    final List<QuranDivisionStart> pages = [];
    int? lastJuz;
    int? lastHizb;
    int? lastPage;
    for (final Map<String, dynamic> surah in surahs) {
      final int surahNumber = (surah['number'] as num).toInt();
      for (final Object? raw in surah['ayahs'] as List<dynamic>) {
        final Map<String, dynamic> ayah = raw! as Map<String, dynamic>;
        final int number = (ayah['numberInSurah'] as num).toInt();
        final int page = (ayah['page'] as num).toInt();
        final int juzNumber = (ayah['juz'] as num).toInt();
        final int hizbNumber =
            (((ayah['hizbQuarter'] as num).toInt() - 1) ~/ 4) + 1;
        QuranDivisionStart at(int n) => QuranDivisionStart(
          number: n,
          surah: surahNumber,
          ayah: number,
          page: page,
        );
        if (juzNumber != lastJuz) juz.add(at(juzNumber));
        if (hizbNumber != lastHizb) hizb.add(at(hizbNumber));
        if (page != lastPage) pages.add(at(page));
        lastJuz = juzNumber;
        lastHizb = hizbNumber;
        lastPage = page;
      }
    }
    _check(juz, juzCount, 'juz');
    _check(hizb, hizbCount, 'hizb');
    _check(pages, pageCount, 'page');
    return QuranDivisions(juz: juz, hizb: hizb, pages: pages);
  }

  static void _check(List<QuranDivisionStart> starts, int count, String kind) {
    if (starts.length != count) {
      throw FormatException('Expected $count $kind starts, ${starts.length}');
    }
    for (int i = 0; i < count; i++) {
      if (starts[i].number != i + 1) {
        throw FormatException('$kind ${i + 1} out of order');
      }
    }
  }

  /// The first ayah of mushaf page [page], or null when out of range.
  QuranDivisionStart? pageStart(int page) =>
      page >= 1 && page <= pageCount ? pages[page - 1] : null;
}

/// What the user typed in "go to": a page, or a surah with an ayah.
sealed class QuranGoTo {
  const QuranGoTo();
}

final class QuranGoToPage extends QuranGoTo {
  const QuranGoToPage(this.page);
  final int page;
}

final class QuranGoToVerse extends QuranGoTo {
  const QuranGoToVerse(this.surah, this.ayah);
  final int surah;
  final int ayah;
}

/// Western digits for Arabic-Indic (٠–٩) and Persian (۰–۹) digits.
String westernDigits(String input) => String.fromCharCodes(
  input.runes.map((r) {
    if (r >= 0x0660 && r <= 0x0669) return 0x30 + r - 0x0660;
    if (r >= 0x06F0 && r <= 0x06F9) return 0x30 + r - 0x06F0;
    return r;
  }),
);

/// Parses "2:255", "٢:٢٥٥", "2 255" or "2/255" as a verse, and a lone
/// number as a page. [ayahCount] gives the ayahs of a surah (1–114) and
/// rejects verses that do not exist. Returns null for anything else.
QuranGoTo? parseQuranGoTo(String input, int Function(int surah) ayahCount) {
  final String text = westernDigits(input).trim();
  final Match? verse = RegExp(r'^(\d{1,3})\s*[:：/\s]\s*(\d{1,3})$')
      .firstMatch(text);
  if (verse != null) {
    final int surah = int.parse(verse[1]!);
    final int ayah = int.parse(verse[2]!);
    if (surah < 1 || surah > 114) return null;
    if (ayah < 1 || ayah > ayahCount(surah)) return null;
    return QuranGoToVerse(surah, ayah);
  }
  final Match? page = RegExp(r'^(\d{1,3})$').firstMatch(text);
  if (page != null) {
    final int number = int.parse(page[1]!);
    if (number < 1 || number > QuranDivisions.pageCount) return null;
    return QuranGoToPage(number);
  }
  return null;
}
