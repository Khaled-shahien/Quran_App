import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/utils/arabic_text.dart';
import 'package:sakina_app/features/quran/data/daily_verse_source.dart';
import 'package:sakina_app/features/quran/domain/daily_verses.dart';

/// Letters only. The home card is in common spelling and the Quran asset in
/// Uthmani spelling, which differ in alefs, hamza seats and dotless final ya;
/// those are dropped or unified so the rest of the letters can be compared.
String _letters(String s) => plainArabic(
  s,
).replaceAll('ى', 'ي').replaceAll(RegExp('[ء-ا]'), '').replaceAll(' ', '');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<dynamic> quran;
  setUpAll(() async {
    quran =
        jsonDecode(await rootBundle.loadString('assets/quran_master.json'))
            as List<dynamic>;
  });

  String ayahText(int surah, int ayah) {
    final s = quran.firstWhere((e) => e['number'] == surah) as Map;
    final a = (s['ayahs'] as List).firstWhere(
      (e) => e['numberInSurah'] == ayah,
    );
    return a['text'] as String;
  }

  test('every verse has a reference', () {
    expect(dailyVerseReferences.length, dailyVerses.length);
  });

  for (var i = 0; i < dailyVerses.length; i++) {
    test('home verse ${i + 1} is part of the ayah it points to', () {
      final ref = dailyVerseReferences[i];
      expect(
        _letters(ayahText(ref.surah, ref.ayah)),
        contains(_letters(dailyVerses[i]['arabic']!)),
      );
    });
  }

  test('the notification quotes the whole ayah, unchanged', () async {
    final date = DateTime(2026, 11, 16);
    final verse = await DailyVerseSource().verseFor(date);
    final ref = dailyVerseReferences[dailyVerseIndex(date)];
    expect((verse.surah, verse.ayah), (ref.surah, ref.ayah));
    expect(verse.text, ayahText(ref.surah, ref.ayah));
    expect(verse.surahName, dailyVerses[dailyVerseIndex(date)]['surah']);
  });

  test('one verse per day, the same all day, cycling through the list', () {
    final morning = DateTime(2026, 5, 3, 6);
    final night = DateTime(2026, 5, 3, 23, 59);
    expect(dailyVerseIndex(morning), dailyVerseIndex(night));
    final week = {
      for (var d = 0; d < dailyVerses.length; d++)
        dailyVerseIndex(DateTime(2026, 5, 3 + d)),
    };
    expect(week.length, dailyVerses.length);
  });
}
