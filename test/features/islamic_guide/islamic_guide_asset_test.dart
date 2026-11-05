import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/islamic_guide/data/islamic_guide_repository_impl.dart';
import 'package:sakina_app/features/islamic_guide/domain/entities/guide_entities.dart';

void main() {
  late List<GuideSection> sections;
  late Map<int, Set<int>> ayahsBySurah;

  setUpAll(() {
    sections = parseGuide(File('assets/islamic_guide.json').readAsStringSync());
    final List<dynamic> quran =
        jsonDecode(File('assets/quran_master.json').readAsStringSync())
            as List<dynamic>;
    ayahsBySurah = <int, Set<int>>{
      for (final dynamic surah in quran)
        (surah as Map)['number'] as int: <int>{
          for (final dynamic ayah in surah['ayahs'] as List<dynamic>)
            (ayah as Map)['numberInSurah'] as int,
        },
    };
  });

  test('asset contains the four expected sections', () {
    expect(sections.map((s) => s.id), <String>[
      GuideSectionId.prophets,
      GuideSectionId.prayer,
      GuideSectionId.specialPrayers,
      GuideSectionId.pillars,
    ]);
  });

  test('lists the 25 prophets named in the Quran', () {
    final GuideSection prophets = sections.firstWhere(
      (s) => s.id == GuideSectionId.prophets,
    );
    expect(prophets.items, hasLength(25));
    final int ululAzm = prophets.items
        .where((p) => p.badges.contains('أولو العزم'))
        .length;
    expect(ululAzm, 5);
  });

  test('special prayers cover istikhara, janazah and istisqa', () {
    final GuideSection special = sections.firstWhere(
      (s) => s.id == GuideSectionId.specialPrayers,
    );
    expect(special.items.map((i) => i.title), <String>[
      'صلاة الاستخارة',
      'صلاة الجنازة',
      'صلاة الاستسقاء',
    ]);
    for (final GuideItem item in special.items) {
      expect(
        item.blocks.any((b) => b.dua != null),
        isTrue,
        reason: '${item.title} needs its dua',
      );
    }
  });

  test('every Quran reference points at verses that exist', () {
    int refs = 0;
    for (final GuideSection section in sections) {
      for (final GuideItem item in section.items) {
        for (final GuideBlock block in item.blocks) {
          for (final QuranRef ref in block.quran) {
            refs++;
            final Set<int>? ayahs = ayahsBySurah[ref.surah];
            expect(ayahs, isNotNull, reason: '${item.title}: ${ref.surah}');
            for (int a = ref.from; a <= ref.to; a++) {
              expect(
                ayahs!.contains(a),
                isTrue,
                reason: '${item.title}: ${ref.surah}:$a',
              );
            }
          }
        }
      }
    }
    expect(refs, greaterThan(30));
  });

  test('Quranic text is never typed into the guide asset', () {
    // Uthmani-only marks would indicate verse text pasted from the mushaf.
    final String raw = File('assets/islamic_guide.json').readAsStringSync();
    expect(raw, isNot(matches(RegExp('[\u06D6-\u06ED\u0671]'))));
  });

  test('rejects structurally invalid content', () {
    expect(() => parseGuide('{"schemaVersion": 2}'), throwsFormatException);
    expect(
      () => parseGuide(
        '{"schemaVersion":1,"sections":[{"id":"x","title":"t","items":[{"title":"a","blocks":[{"label":"l"}]}]}]}',
      ),
      throwsFormatException,
    );
    expect(
      () => parseGuide(
        '{"schemaVersion":1,"sections":[{"id":"x","title":"t","items":[{"title":"a","blocks":[{"label":"l","quran":[{"surah":115,"from":1,"to":1}]}]}]}]}',
      ),
      throwsFormatException,
    );
  });
}
