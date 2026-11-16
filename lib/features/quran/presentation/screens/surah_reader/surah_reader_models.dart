part of '../surah_details_screen.dart';

/// The verses of one mushaf page (within the surah or wird being read).
class _SurahPageData {
  final List<_SurahVerseData> verses;
  final int startVerseIndex;

  _SurahPageData(this.verses, this.startVerseIndex);

  /// The mushaf page these verses are on.
  int get pageNumber => verses.first.pageNumber;
}

class _SurahVerseData {
  final String text;
  final int surahNumber;
  final int verseNumber;
  final int pageNumber;
  final String surahName;
  final String revelationType;
  final int totalAyah;
  final bool showSurahHeader;
  final bool showBasmala;

  const _SurahVerseData({
    required this.text,
    required this.surahNumber,
    required this.verseNumber,
    required this.pageNumber,
    required this.surahName,
    required this.revelationType,
    required this.totalAyah,
    this.showSurahHeader = false,
    this.showBasmala = false,
  });
}
