import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina_app/features/duas/data/hisn_almuslim.dart';
import 'package:sakina_app/features/duas/presentation/screens/hisn_screens.dart';

void main() {
  late String raw;
  late List<HisnChapter> chapters;

  setUpAll(() {
    raw = File(HisnAlMuslim.path).readAsStringSync();
    chapters = HisnAlMuslim.parse(raw);
  });

  test('all 132 chapters and 267 entries are bundled', () {
    expect(chapters, hasLength(132));
    expect(chapters.fold<int>(0, (n, c) => n + c.entries.length), 267);
    expect(chapters.map((c) => c.id).toSet(), hasLength(132));
    for (final c in chapters) {
      expect(c.title.trim(), isNotEmpty);
      expect(c.entries, isNotEmpty, reason: c.title);
      for (final e in c.entries) {
        expect(e.text.trim(), isNotEmpty);
        expect(e.repeat, greaterThanOrEqualTo(1));
      }
    }
  });

  test('the text is the API text, unchanged', () {
    // Built by tool/build_hisn_almuslim.py; the sleep chapter (28) of the
    // API has 13 entries, the first beginning with the joined palms.
    final sleep = chapters.firstWhere((c) => c.id == 28);
    expect(sleep.entries, hasLength(13));
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    expect(decoded['source'], contains('hisnmuslim.com'));
  });

  test('a damaged file is rejected', () {
    expect(() => HisnAlMuslim.parse('{}'), throwsFormatException);
    expect(
      () => HisnAlMuslim.parse(
        jsonEncode({
          'schemaVersion': 1,
          'chapters': [
            {
              'id': 1,
              'title': 'x',
              'items': [
                {'id': 1},
              ],
            },
          ],
        }),
      ),
      throwsFormatException,
    );
  });

  testWidgets('search narrows chapters; a chapter counts each entry', (
    tester,
  ) async {
    final source = HisnAlMuslim(load: () async => raw);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => HisnChaptersScreen(source: source),
        ),
        GoRoute(
          path: '/duas/hisn/:id',
          builder: (_, state) => HisnChapterScreen(
            chapterId: int.parse(state.pathParameters['id']!),
            source: source,
          ),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final sleep = chapters.firstWhere((c) => c.id == 28);
    await tester.enterText(find.byType(TextField), 'النوم');
    await tester.pumpAndSettle();
    expect(find.text(sleep.title), findsOneWidget);
    expect(find.text('أذكار الصباح والمساء'), findsNothing);

    await tester.tap(find.text(sleep.title));
    await tester.pumpAndSettle();
    final first = sleep.entries.first;
    expect(find.text('0 من ${first.repeat}'), findsWidgets);
    await tester.tap(find.text(first.text.trim()));
    await tester.pumpAndSettle();
    expect(
      find.text(first.repeat == 1 ? 'تم' : '1 من ${first.repeat}'),
      findsOneWidget,
    );
  });
}
