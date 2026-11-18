import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/hadeath/data/data_sources/local_hadeath_data_source.dart';
import 'package:sakina_app/features/hadeath/domain/entities/hadeath_entity.dart';
import 'package:sakina_app/features/hadeath/domain/repositories/hadeath_repository.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/features/hadeath/presentation/providers/hadeath_provider.dart';
import 'package:sakina_app/features/hadeath/presentation/screens/hadeath_details_screen.dart';
import 'package:sakina_app/l10n/app_localizations.dart';

class _Repo implements HadeathRepository {
  _Repo(this.items);
  final List<HadeathEntity> items;
  @override
  Future<Result<List<HadeathEntity>>> getAllAhadeth() async => Success(items);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all fifty hadith carry their text and study from HadeethEnc', () async {
    final list = await LocalHadeathDataSource().loadAhadeth();
    expect(list, hasLength(50));
    expect(list.every((h) => h.study != null), isTrue);
    final first = list.first;
    expect(first.title.replaceAll(' ', ''), contains('الحديث'));
    expect(first.study!.sourceId, '66511');
    expect(first.study!.grade, isNotEmpty);
    expect(first.study!.sourceUrl, endsWith('/66511'));

    // The text shown is the source's text, character for character.
    final raw =
        jsonDecode(
              await rootBundle.loadString(LocalHadeathDataSource.studyPath),
            )
            as Map<String, dynamic>;
    final items = (raw['items'] as List).cast<Map<String, dynamic>>();
    for (final (i, h) in list.indexed) {
      expect(h.content.single, items[i]['hadeeth']);
      expect(h.study!.explanation, items[i]['explanation']);
    }
  });

  test('search looks in titles, text and explanations', () async {
    final provider = HadeathProvider(
      repository: _Repo(const [
        HadeathEntity(title: 'الأول', content: ['إنما الأعمال بالنيات']),
        HadeathEntity(
          title: 'الثاني',
          content: ['نص'],
          study: HadeathStudy(
            sourceId: '1',
            grade: 'صحيح',
            attribution: 'رواه',
            explanation: 'فضل الإحسان',
            reference: 'مرجع',
          ),
        ),
      ]),
    );
    await provider.loadAhadeth();
    provider.search('النيات');
    expect(provider.visible.map((v) => v.number), [1]);
    provider.search('الاحسان');
    expect(provider.visible.map((v) => v.number), [2]);
    provider.search('');
    expect(provider.visible, hasLength(2));
  });

  testWidgets('details show grade, explanation, lessons and the source', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HadeathDetailsScreen(
          hadeath: HadeathEntity(
            title: 'الحديث الأول',
            content: ['النص'],
            study: HadeathStudy(
              sourceId: '66511',
              grade: 'صحيح',
              attribution: 'رواه البخاري ومسلم',
              explanation: 'شرح الحديث',
              reference: 'صحيح البخاري',
              hints: ['فائدة أولى'],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final text in ['صحيح', 'رواه البخاري ومسلم', 'شرح الحديث']) {
      expect(find.text(text), findsOneWidget);
    }
    await tester.scrollUntilVisible(find.text('فائدة أولى'), 200);
    expect(find.text('فائدة أولى'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('hadeethenc'), 200);
    expect(find.textContaining('hadeethenc'), findsOneWidget);
  });
}
