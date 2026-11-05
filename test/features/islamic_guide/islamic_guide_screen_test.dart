import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/features/islamic_guide/domain/entities/guide_entities.dart';
import 'package:sakina_app/features/islamic_guide/domain/repositories/islamic_guide_repository.dart';
import 'package:sakina_app/features/islamic_guide/presentation/providers/islamic_guide_provider.dart';
import 'package:sakina_app/features/islamic_guide/presentation/screens/islamic_guide_screen.dart';

const List<GuideBlock> _filler = <GuideBlock>[
  GuideBlock(label: 'قومه', text: 'نص تجريبي'),
];

class _FakeRepository implements IslamicGuideRepository {
  _FakeRepository({this.fail = false});

  bool fail;
  int quranCalls = 0;

  @override
  Future<List<GuideSection>> getSections() async {
    if (fail) throw StateError('boom');
    return const <GuideSection>[
      GuideSection(
        id: GuideSectionId.prophets,
        title: 'الأنبياء والرسل',
        items: <GuideItem>[
          GuideItem(
            title: 'يونس عليه السلام',
            subtitle: 'ذو النون',
            blocks: <GuideBlock>[
              GuideBlock(
                label: 'دعوته المستجابة',
                quran: <QuranRef>[QuranRef(surah: 21, from: 87, to: 87)],
              ),
            ],
          ),
          // Long sections (like the real 25 prophets) start collapsed.
          GuideItem(title: 'نوح', blocks: _filler),
          GuideItem(title: 'هود', blocks: _filler),
          GuideItem(title: 'صالح', blocks: _filler),
        ],
      ),
      GuideSection(
        id: GuideSectionId.pillars,
        title: 'أركان الإسلام والإيمان',
        items: <GuideItem>[
          GuideItem(
            title: 'أركان الإسلام',
            blocks: <GuideBlock>[
              GuideBlock(
                label: 'الأركان',
                steps: <String>['الشهادتان', 'إقامة الصلاة'],
              ),
              GuideBlock(label: 'الحديث', dua: 'بني الإسلام على خمس'),
            ],
          ),
        ],
      ),
    ];
  }

  @override
  Future<List<GuideVerse>> resolveQuran(QuranRef ref) async {
    quranCalls++;
    return const <GuideVerse>[
      GuideVerse(surah: 21, surahName: 'سورة الأنبياء', ayah: 87, text: 'نص'),
    ];
  }
}

Widget _app(IslamicGuideRepository repository, {String? section}) {
  return MaterialApp(
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: ChangeNotifierProvider<IslamicGuideProvider>(
        create: (_) => IslamicGuideProvider(repository: repository)..load(),
        child: IslamicGuideScreen(initialSectionId: section),
      ),
    ),
  );
}

void main() {
  testWidgets('opens on the requested section and shows its content', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_FakeRepository(), section: 'pillars'));
    await tester.pumpAndSettle();

    expect(find.text('أركان الإسلام والإيمان'), findsOneWidget);
    // Short sections open their first card automatically.
    expect(find.text('الشهادتان'), findsOneWidget);
    expect(find.text('بني الإسلام على خمس'), findsOneWidget);
  });

  testWidgets('resolves Quran references when a prophet card expands', (
    tester,
  ) async {
    final _FakeRepository repository = _FakeRepository();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('يونس عليه السلام'));
    await tester.pumpAndSettle();

    expect(find.text('[سورة الأنبياء: ٨٧]'), findsOneWidget);
    final Text verse = tester.widget(
      find.descendant(
        of: find.byType(SelectionArea),
        matching: find.byType(Text),
      ),
    );
    expect(verse.data, startsWith('نص '));
    expect(verse.data, endsWith('٨٧${String.fromCharCode(0xFD3E)}'));
    expect(repository.quranCalls, 1);
  });

  testWidgets('shows a retry action when loading fails', (tester) async {
    final _FakeRepository repository = _FakeRepository(fail: true);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.byType(FilledButton), findsOneWidget);

    repository.fail = false;
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('يونس عليه السلام'), findsOneWidget);
  });
}
