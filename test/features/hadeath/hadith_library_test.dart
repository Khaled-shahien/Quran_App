import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/hadeath/data/hadith_library.dart';
import 'package:sakina_app/features/hadeath/presentation/screens/hadith_library_screen.dart';
import 'package:sakina_app/l10n/app_localizations.dart';

final String _sample = jsonEncode({
  'topics': [
    {'id': 1, 'title': 'العقيدة', 'parent': null},
    {'id': 2, 'title': 'الإيمان', 'parent': 1},
    {'id': 3, 'title': 'الفقه', 'parent': null},
    {'id': 4, 'title': 'باب فارغ', 'parent': 3},
  ],
  'items': [
    {
      'id': 10,
      'title': 'الإيمان بضع وسبعون شعبة',
      'hadeeth': 'نص أول',
      'grade': 'صحيح',
      'explanation': 'شرح',
      'reference': 'مرجع',
      'topics': [2],
    },
    {
      'id': 11,
      'title': 'حديث في العقيدة',
      'hadeeth': 'نص ثان عن الإخلاص',
      'grade': 'حسن',
      'topics': [1],
    },
  ],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('topics count the hadith below them; empty topics are hidden', () {
    final lib = HadithLibrary.parseNow(_sample);
    expect(lib.childrenOf(null).map((t) => t.id), [1]);
    expect(lib.countIn(1), 2);
    expect(lib.countIn(2), 1);
    expect(lib.childrenOf(3), isEmpty);
    expect(lib.itemsIn(1).map((i) => i.id), [10, 11]);
  });

  test('search covers titles and texts, marks ignored', () {
    final lib = HadithLibrary.parseNow(_sample);
    expect(lib.search('الاخلاص').map((i) => i.id), [11]);
    expect(lib.search('شعبة').map((i) => i.id), [10]);
    expect(lib.search(''), isEmpty);
  });

  test('an item opens with its grade and explanation', () {
    final entity = HadithLibrary.parseNow(_sample).items.first.toEntity();
    expect(entity.content.single, 'نص أول');
    expect(entity.study!.grade, 'صحيح');
    expect(entity.study!.sourceUrl, endsWith('/10'));
  });

  test(
    'the bundled encyclopedia: every hadith has text and a known topic',
    () async {
      final raw = await rootBundle.loadString(HadithLibrary.path);
      final lib = HadithLibrary.parseNow(raw);
      expect(lib.items.length, greaterThan(3500));
      final ids = {for (final t in lib.topics) t.id};
      for (final item in lib.items) {
        expect(item.hadeeth.trim(), isNotEmpty);
        expect(item.grade.trim(), isNotEmpty);
        expect(item.topics, isNotEmpty);
        expect(ids.containsAll(item.topics), isTrue);
      }
      expect(lib.childrenOf(null), hasLength(7));
    },
  );

  testWidgets('browse a topic down to a hadith', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HadithLibraryScreen(
          load: () async => HadithLibrary.parseNow(_sample),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('hadith-topic-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('hadith-topic-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('hadith-item-10')));
    await tester.pumpAndSettle();
    expect(find.text('نص أول'), findsOneWidget);
    expect(find.text('صحيح'), findsOneWidget);
  });
}
