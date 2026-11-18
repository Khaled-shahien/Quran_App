import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/duas/data/hisn_almuslim.dart';
import 'package:sakina_app/features/hadeath/domain/entities/hadeath_entity.dart';
import 'package:sakina_app/features/islamic_guide/domain/entities/guide_entities.dart';
import 'package:sakina_app/features/quran/domain/entities/ayah_entity.dart';
import 'package:sakina_app/features/search/unified_search.dart';
import 'package:sakina_app/features/search/unified_search_screen.dart';
import 'package:sakina_app/l10n/app_localizations.dart';

AyahEntity _ayah(int n, String text) => AyahEntity(
  number: n,
  text: text,
  numberInSurah: n,
  juz: 1,
  manzil: 1,
  page: 3,
  ruku: 1,
  hizbQuarter: 1,
  sajda: false,
);

UnifiedSearch _search() => UnifiedSearch.build(
  quran: {
    2: [
      _ayah(153, 'يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُواْ ٱسْتَعِينُواْ بِٱلصَّبْرِ'),
    ],
  },
  surahName: (n) => 'البقرة',
  hisn: const [
    HisnChapter(
      id: 34,
      title: 'دعاء الهم والحزن',
      entries: [
        HisnEntry(id: 1, text: 'اللهم إني أعوذ بك من الهم والحزن', repeat: 1),
      ],
    ),
  ],
  hadith: const [
    HadeathEntity(title: 'الحديث الأول', content: ['إنما الأعمال بالنيات']),
    HadeathEntity(
      title: 'الحديث الثاني',
      content: ['نص'],
      study: HadeathStudy(
        sourceId: '1',
        grade: 'صحيح',
        attribution: 'رواه',
        explanation: 'فيه الحث على الصبر',
        reference: 'مرجع',
      ),
    ),
  ],
  guide: const [
    GuideSection(
      id: 'prayer',
      title: 'الصلاة',
      items: [
        GuideItem(
          title: 'سجود السهو',
          blocks: [
            GuideBlock(label: 'متى', text: 'عند الزيادة أو النقص في الصلاة'),
          ],
        ),
      ],
    ),
  ],
);

void main() {
  test('one query reaches every source, each with its reference', () {
    final hits = _search().search('الصبر');
    expect(hits.keys, [SearchSource.quran, SearchSource.hadith]);
    final quran = hits[SearchSource.quran]!.single;
    expect(quran.title, 'البقرة 153');
    expect(quran.target, isA<QuranVerseTarget>());
    final hadith = hits[SearchSource.hadith]!.single;
    expect(hadith.title, 'الحديث الثاني');
    expect(
      hadith.snippet.substring(hadith.matchStart, hadith.matchEnd),
      'الصبر',
    );
    expect((hadith.target as HadithTarget).index, 1);

    expect(
      (_search().search('الحزن')[SearchSource.hisn]!.single.target
              as HisnChapterTarget)
          .chapterId,
      34,
    );
    expect(
      (_search().search('السهو')[SearchSource.guide]!.single.target
              as GuideTarget)
          .sectionId,
      'prayer',
    );
  });

  test('matches inside a word are left out of the longer texts', () {
    // "الهم" appears inside nothing else here, but "هم" only inside words.
    expect(_search().search('هم')[SearchSource.hisn], isNull);
    expect(_search().search('  '), isEmpty);
  });

  test('snippets keep context around the match and mark cuts', () {
    final long = 'كلمة ' * 40;
    final s = UnifiedSearch.build(
      quran: const {},
      surahName: (_) => '',
      hadith: [
        HadeathEntity(title: 't', content: ['$long الهدف $long']),
      ],
    );
    final hit = s.search('الهدف')[SearchSource.hadith]!.single;
    expect(hit.snippet.startsWith('… '), isTrue);
    expect(hit.snippet.endsWith(' …'), isTrue);
    expect(hit.snippet.substring(hit.matchStart, hit.matchEnd), 'الهدف');
  });

  testWidgets('results are grouped by source', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: UnifiedSearchScreen(load: () async => _search()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('unified-search')), 'الصبر');
    await tester.pumpAndSettle();
    expect(find.text('القرآن الكريم (1)'), findsOneWidget);
    expect(find.text('الأحاديث (1)'), findsOneWidget);
    expect(find.text('حصن المسلم (1)'), findsNothing);
  });
}
