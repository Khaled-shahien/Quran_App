import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/theme/app_typography.dart';
import 'package:sakina_app/features/quran/domain/services/basmala.dart';
import 'package:sakina_app/features/quran/domain/services/reader_layout.dart';
import 'package:sakina_app/features/quran/presentation/widgets/quran_page_layout.dart';

import '../../../../helpers/quran_fonts.dart';

/// Every one of the 604 mushaf pages, laid out as the heaviest case the
/// reader can show (a wird across the whole mushaf, so every surah that
/// starts on a page brings its title and basmala), at the default reading
/// size, on real phone reading areas.

/// [titles]: a wird across surahs shows each new surah's title; reading a
/// single surah does not.
List<List<QuranPagePiece>> _allMushafPages({required bool titles}) {
  final quran =
      (jsonDecode(File('assets/quran_master.json').readAsStringSync())
              as List<dynamic>)
          .cast<Map<String, dynamic>>();
  final verses =
      <({int surah, int ayah, int page, String text, bool basmala})>[];
  for (final surah in quran) {
    for (final raw in (surah['ayahs'] as List<dynamic>)) {
      final ayah = raw as Map<String, dynamic>;
      final split = splitLeadingBasmala(
        surahNumber: surah['number'] as int,
        ayahNumber: ayah['numberInSurah'] as int,
        text: (ayah['text'] as String).trim(),
      );
      verses.add((
        surah: surah['number'] as int,
        ayah: ayah['numberInSurah'] as int,
        page: ayah['page'] as int,
        text: split.ayahText,
        basmala: split.hasBasmala,
      ));
    }
  }
  return [
    for (final group in groupByMushafPage([for (final v in verses) v.page]))
      () {
        final pieces = <QuranPagePiece>[];
        var run = <QuranVerseText>[];
        void flush() {
          if (run.isEmpty) return;
          pieces.add(QuranVersesPiece(run));
          run = <QuranVerseText>[];
        }

        for (final i in group) {
          final v = verses[i];
          if (v.ayah == 1 && (titles || v.basmala)) {
            flush();
            if (titles) {
              pieces.add(
                const QuranTitlePiece(
                  name: 'سورة الممتحنة',
                  subtitle: 'مدنية • ١٣ آية',
                ),
              );
            }
            if (v.basmala) pieces.add(const QuranBasmalaPiece());
          }
          run.add((text: v.text, number: v.ayah));
        }
        flush();
        return pieces;
      }(),
  ];
}

({double min, int below20, int compressed, List<int> compressedPages}) _report(
  Size area, {
  required bool titles,
}) {
  final pages = _allMushafPages(titles: titles);
  expect(pages.length, 604);
  var min = double.infinity;
  var below20 = 0;
  var compressed = 0;
  final compressedPages = <int>[];
  for (var p = 0; p < pages.length; p++) {
    final pieces = pages[p];
    final fit = fitQuranPage(
      pieces: pieces,
      area: area,
      quranStyle: const TextStyle(
        fontFamily: quranFontFamily,
        color: Color(0xFF000000),
      ),
      subtitleStyle: AppTypography.labelSmall,
      markerColor: const Color(0xFF000000),
      showMarkers: true,
      textScaler: TextScaler.noScaling,
      rootStyle: AppTypography.bodyMedium,
      preferredSize: 28,
      preferredLineHeight: 1.95,
    );
    if (fit.fontSize < min) min = fit.fontSize;
    if (fit.fontSize < 20) below20++;
    if (fit.compressed) {
      compressed++;
      compressedPages.add(p + 1);
    }
  }
  return (
    min: min,
    below20: below20,
    compressed: compressed,
    compressedPages: compressedPages,
  );
}

/// Reading areas on real phones: the area measured in a widget test, less
/// about 60 px for the status and navigation bars a device adds.
const _pixel7 = Size(387, 734); // 411 x 914
const _midPhone = Size(336, 600); // 360 x 780, a very common size
const _smallPhone = Size(336, 460); // 360 x 640, older and small phones

/// Measured results, for the record (default size 28, line height 1.95):
///
/// | Phone   | Reading        | Smallest | Below 20 px | Compressed |
/// |---------|----------------|----------|-------------|------------|
/// | Pixel 7 | a surah        | 22       | 0           | 0          |
/// | Pixel 7 | wird           | 19.5     | 1           | 0          |
/// | 360x780 | a surah        | 18.25    | 51          | 0          |
/// | 360x780 | wird           | 15.5     | 120         | 13         |
/// | 360x640 | a surah        | 15.5     | 564         | 180        |
/// | 360x640 | wird           | 12       | 566         | 236        |
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadQuranFonts);

  test('all 604 pages fit a Pixel 7 at a comfortable size, reading a surah '
      'or a wird across surahs', () {
    expect(_report(_pixel7, titles: false).compressed, 0);
    expect(_report(_pixel7, titles: true).compressed, 0);
  });

  test('a 360 x 780 phone fits every page of surah reading comfortably', () {
    expect(_report(_midPhone, titles: false).compressed, 0);
  });

  test('a 360 x 640 phone fits every page, never below 12 px', () {
    expect(_report(_smallPhone, titles: true).min, greaterThanOrEqualTo(12));
  });
}
