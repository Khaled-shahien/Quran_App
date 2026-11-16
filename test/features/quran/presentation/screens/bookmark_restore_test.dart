import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/features/quran/domain/entities/surah_entity.dart';
import 'package:sakina_app/features/quran/domain/services/basmala.dart';
import 'package:sakina_app/features/quran/domain/services/reader_layout.dart';
import 'package:sakina_app/features/quran/presentation/providers/bookmark_provider.dart';
import 'package:sakina_app/features/quran/presentation/screens/surah_details_screen.dart';
import 'package:sakina_app/features/settings/presentation/widgets/reading_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opening the saved bookmark lands on the bookmarked verse's page, even
/// when reading last stopped somewhere else in the same surah.

final _baqarah =
    ((jsonDecode(File('assets/quran_master.json').readAsStringSync())
                as List<dynamic>)[1]
            as Map<String, dynamic>)['ayahs']
        as List<dynamic>;

/// The page index (within Al-Baqarah) of the mushaf page holding [ayah].
int _pageIndexOf(int ayah) {
  final pages = [for (final a in _baqarah) (a as Map)['page'] as int];
  final groups = groupByMushafPage(pages);
  return groups.indexWhere((g) => g.contains(ayah - 1));
}

Future<double> _openAt(
  WidgetTester tester,
  Map<String, Object> stored, {
  required bool openAtBookmark,
}) async {
  rootBundle.evict('assets/quran_master.json');
  SharedPreferences.setMockInitialValues({
    ReadingPreferences.layoutKey: 'pages',
    ...stored,
  });
  final prefs = await SharedPreferences.getInstance();
  final pages = find.byKey(const Key('reader-pages'));
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: prefs),
        ChangeNotifierProvider(create: (_) => BookmarkProvider(prefs: prefs)),
      ],
      child: MaterialApp(
        home: SurahDetailsScreen(
          surah: SurahEntity(
            number: 2,
            name: 'سورة البقرة',
            englishName: '',
            englishNameTranslation: '',
            revelationType: 'Medinan',
            totalAyah: 286,
          ),
          surahNumber: 2,
          openAtBookmark: openAtBookmark,
        ),
      ),
    ),
  );
  for (var i = 0; i < 50 && pages.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
  final page = tester.widget<PageView>(pages).controller!.page!;
  await tester.pumpWidget(const SizedBox.shrink());
  return page;
}

void main() {
  const bookmark = <String, Object>{
    'bookmark_surah_number': 2,
    'bookmark_surah_name': 'سورة البقرة',
    'bookmark_page_index': 0,
    'bookmark_ayah_number': 200,
  };

  testWidgets('the bookmark wins over the last-read position', (tester) async {
    final page = await _openAt(tester, {
      ...bookmark,
      ReadingPreferences.lastAyahKey(2): 100,
    }, openAtBookmark: true);
    expect(page, _pageIndexOf(200));
    expect(_pageIndexOf(200), isNot(_pageIndexOf(100)));
  });

  testWidgets('opened normally, reading resumes where it stopped', (
    tester,
  ) async {
    final page = await _openAt(tester, {
      ...bookmark,
      ReadingPreferences.lastAyahKey(2): 100,
    }, openAtBookmark: false);
    expect(page, _pageIndexOf(100));
  });

  testWidgets('an old bookmark with only a page index opens at the verse '
      'that page began with', (tester) async {
    final verses = <LegacyVerse>[
      for (final raw in _baqarah)
        () {
          final a = raw as Map<String, dynamic>;
          final split = splitLeadingBasmala(
            surahNumber: 2,
            ayahNumber: a['numberInSurah'] as int,
            text: (a['text'] as String).trim(),
          );
          return (
            ayah: a['numberInSurah'] as int,
            length: split.ayahText.length,
            basmala: split.hasBasmala,
          );
        }(),
    ];
    final lead = legacyPageLeadAyah(
      verses: verses,
      pageIndex: 7,
      basmalaLength: uthmaniBasmala.length,
    )!;
    final page = await _openAt(tester, {
      'bookmark_surah_number': 2,
      'bookmark_surah_name': 'سورة البقرة',
      'bookmark_page_index': 7,
      ReadingPreferences.lastAyahKey(2): 250,
    }, openAtBookmark: true);
    expect(page, _pageIndexOf(lead));
  });
}
