import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/quran/domain/services/basmala.dart';
import 'package:sakina_app/features/quran/domain/services/reader_layout.dart';

/// The Quran data and everything the reader derives from it, for all 114
/// surahs: verse counts and order, page associations, the basmala split and
/// the grouping into mushaf pages. Nothing here changes the text; these
/// tests prove the reader shows it unchanged.

final List<Map<String, dynamic>> _quran =
    (jsonDecode(File('assets/quran_master.json').readAsStringSync())
            as List<dynamic>)
        .cast<Map<String, dynamic>>();

List<Map<String, dynamic>> _ayahs(Map<String, dynamic> surah) =>
    (surah['ayahs'] as List<dynamic>).cast<Map<String, dynamic>>();

void main() {
  test('114 surahs, 6236 verses, numbered and ordered', () {
    expect(_quran.length, 114);
    var global = 0;
    for (var s = 0; s < 114; s++) {
      final surah = _quran[s];
      expect(surah['number'], s + 1);
      final ayahs = _ayahs(surah);
      expect(ayahs.length, surah['numberOfAyahs'], reason: 'surah ${s + 1}');
      for (var a = 0; a < ayahs.length; a++) {
        global++;
        expect(ayahs[a]['numberInSurah'], a + 1, reason: 'surah ${s + 1}');
        expect(ayahs[a]['number'], global, reason: 'surah ${s + 1}');
        expect(
          (ayahs[a]['text'] as String).trim(),
          isNotEmpty,
          reason: '${s + 1}:${a + 1}',
        );
      }
    }
    expect(global, 6236);
  });

  test('page numbers run 1 to 604 and never go backwards', () {
    final pages = [
      for (final surah in _quran)
        for (final ayah in _ayahs(surah)) ayah['page'] as int,
    ];
    expect(pages.first, 1);
    expect(pages.last, 604);
    for (var i = 1; i < pages.length; i++) {
      expect(pages[i], greaterThanOrEqualTo(pages[i - 1]), reason: 'verse $i');
    }
    expect(pages.toSet().length, 604, reason: 'no page is missing');
  });

  test('the basmala split only ever removes a known basmala from ayah 1, '
      'and leaves every other verse untouched', () {
    for (final surah in _quran) {
      final number = surah['number'] as int;
      for (final ayah in _ayahs(surah)) {
        final ayahNumber = ayah['numberInSurah'] as int;
        final source = (ayah['text'] as String).trim();
        final split = splitLeadingBasmala(
          surahNumber: number,
          ayahNumber: ayahNumber,
          text: source,
        );
        final where = '$number:$ayahNumber';
        if (!split.hasBasmala) {
          expect(split.ayahText, source, reason: where);
          continue;
        }
        expect(ayahNumber, 1, reason: where);
        expect(number, isNot(anyOf(1, 9)), reason: where);
        expect(source.endsWith(' ${split.ayahText}'), isTrue, reason: where);
        final prefix = source.substring(
          0,
          source.length - split.ayahText.length - 1,
        );
        // The two forms the source uses; the first is the header shown.
        expect(prefix.runes.first, 0x0628, reason: where);
        expect(
          prefix == uthmaniBasmala ||
              prefix.replaceFirst('ّ', '') == uthmaniBasmala,
          isTrue,
          reason: where,
        );
      }
      // Every surah except Al-Fatiha and At-Tawbah gets the header.
      final first = splitLeadingBasmala(
        surahNumber: number,
        ayahNumber: 1,
        text: (_ayahs(surah).first['text'] as String).trim(),
      );
      expect(first.hasBasmala, number != 1 && number != 9, reason: '$number');
    }
  });

  test('grouping by mushaf page keeps every verse once, in order, each '
      'group on one page', () {
    void check(List<int> pages, String where) {
      final groups = groupByMushafPage(pages);
      expect(
        [for (final g in groups) ...g],
        List<int>.generate(pages.length, (i) => i),
        reason: '$where: every verse once, in order',
      );
      for (var g = 0; g < groups.length; g++) {
        final page = pages[groups[g].first];
        expect(
          groups[g].every((i) => pages[i] == page),
          isTrue,
          reason: '$where: one page per group',
        );
        if (g > 0) {
          expect(
            page,
            greaterThan(pages[groups[g - 1].first]),
            reason: '$where: pages in order, none repeated',
          );
        }
      }
    }

    final all = [
      for (final surah in _quran)
        for (final ayah in _ayahs(surah)) ayah['page'] as int,
    ];
    check(all, 'whole mushaf');
    expect(groupByMushafPage(all).length, 604);

    for (final surah in _quran) {
      check([
        for (final ayah in _ayahs(surah)) ayah['page'] as int,
      ], 'surah ${surah['number']}');
    }
  });
}
