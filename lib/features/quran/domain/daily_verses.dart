/// The verses of the day: shown on the home card and, when the user turns it
/// on, as the daily verse notification. Both pick the same verse for a date.
library;

/// The home card's verses, unchanged. Favourites store these maps, so their
/// keys and text must stay exactly as they are.
const List<Map<String, String>> dailyVerses = [
  {
    'surah': 'سورة الفاتحة',
    'arabic':
        'الْحَمْدُ لِلَّهِ '
        'رَبِّ الْعَالَمِينَ',
    'english': 'All praise and thanks be to the Lord of the worlds.',
  },
  {
    'surah': 'سورة البقرة',
    'arabic':
        'لَا يُكَلِّفُ اللَّهُ '
        'نَفْسًا إِلَّا وُسْعَهَا',
    'english': 'Allah does not burden a soul beyond that it can bear.',
  },
  {
    'surah': 'سورة غافر',
    'arabic':
        'وَقَالَ رَبُّكُمُ '
        'ادْعُونِي أَسْتَجِبْ لَكُمْ',
    'english': 'And your Lord says, "Call upon Me; I will respond to you."',
  },
  {
    'surah': 'سورة الشرح',
    'arabic': 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا',
    'english': 'For indeed, with hardship [will be] ease.',
  },
  {
    'surah': 'سورة الرعد',
    'arabic':
        'أَلَا بِذِكْرِ اللَّهِ '
        'تَطْمَئِنِّ الْقُلُوبُ',
    'english':
        'Unquestionably, by the remembrance of Allah hearts are assured.',
  },
  {
    'surah': 'سورة طه',
    'arabic':
        'قَالَ لَا تَخَافَا ۖ '
        'إِنَّنِي مَعَكُمَا '
        'أَسْمَعُ وَأَرَىٰ',
    'english':
        'He said, "Fear not. Indeed, I am with you both; I hear and I see."',
  },
];

/// Where each of [dailyVerses] is in the Quran, in the same order. The
/// notification reads the whole ayah from the Quran asset by this reference;
/// no Quranic text is typed for it.
const List<({int surah, int ayah})> dailyVerseReferences = [
  (surah: 1, ayah: 2),
  (surah: 2, ayah: 286),
  (surah: 40, ayah: 60),
  (surah: 94, ayah: 5),
  (surah: 13, ayah: 28),
  (surah: 20, ayah: 46),
];

/// Which of [dailyVerses] belongs to [date]: one per calendar day, cycling
/// through the list over the year.
int dailyVerseIndex(DateTime date) {
  final int day = DateTime(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime(date.year)).inDays;
  return day % dailyVerses.length;
}
