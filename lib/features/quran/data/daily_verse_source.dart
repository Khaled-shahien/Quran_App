import '../domain/daily_verses.dart';
import 'data_sources/local_quran_data_source.dart';

/// The day's verse as the notification shows it.
typedef DailyVerse = ({int surah, int ayah, String text, String surahName});

/// Reads the verse of a day from the bundled Quran text by its reference,
/// so the notification quotes the whole ayah exactly as the reader shows it.
class DailyVerseSource {
  DailyVerseSource({LocalQuranDataSource? quran})
    : _quran = quran ?? LocalQuranDataSource();

  final LocalQuranDataSource _quran;

  Future<DailyVerse> verseFor(DateTime date) async {
    final int index = dailyVerseIndex(date);
    final reference = dailyVerseReferences[index];
    final ayahs = await _quran.getAyahsForSurah(reference.surah);
    final ayah = ayahs.firstWhere((a) => a.numberInSurah == reference.ayah);
    return (
      surah: reference.surah,
      ayah: reference.ayah,
      text: ayah.text,
      surahName: dailyVerses[index]['surah']!,
    );
  }
}
