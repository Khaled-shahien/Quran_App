import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina_app/features/quran/domain/entities/ayah_entity.dart';
import 'package:sakina_app/features/quran/domain/repositories/ayah_repository.dart';
import 'package:sakina_app/features/quran/presentation/screens/quran_search_screen.dart';

class SearchRepository implements AyahRepository {
  @override
  Future<Map<int, List<AyahEntity>>> getAllAyahs() async => {
    for (var surah = 1; surah <= 114; surah++)
      surah: [
        AyahEntity(
          number: surah,
          text: surah == 1 ? 'بِسْمِ اللَّهِ' : 'نص',
          numberInSurah: 1,
          juz: 1,
          manzil: 1,
          page: surah,
          ruku: 1,
          hizbQuarter: 1,
          sajda: false,
        ),
      ],
  };
  @override
  Future<List<AyahEntity>> getAyahsForSurah(int number) async =>
      (await getAllAyahs())[number]!;
  @override
  Future<AyahEntity> getAyah(int surah, int ayah) async =>
      (await getAyahsForSurah(surah)).first;
  @override
  Future<List<AyahEntity>> searchAyahs(String query) async => [];
}

Future<void> pumpSearch(WidgetTester tester, Widget app) async {
  // Mount and await the real asset work in the same async zone. Preloading
  // alone leaves the widget's continuation waiting outside fake test time.
  await tester.runAsync(() async {
    await tester.pumpWidget(app);
    await rootBundle.loadString('assets/quran_master.json');
  });
  await tester.pumpAndSettle();
}

void main() {
  for (final brightness in Brightness.values) {
    for (final query in ['الفاتحة', '١', '1']) {
      testWidgets('surah lookup supports $query offline in $brightness RTL', (
        tester,
      ) async {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) =>
                  QuranSearchScreen(repository: SearchRepository()),
            ),
            GoRoute(
              path: '/quran/surah/:number',
              builder: (_, state) => Scaffold(
                body: Text('reader ${state.pathParameters['number']}'),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);
        await pumpSearch(
          tester,
          MaterialApp.router(
            routerConfig: router,
            theme: ThemeData(brightness: brightness),
            builder: (_, child) =>
                Directionality(textDirection: TextDirection.rtl, child: child!),
          ),
        );
        expect(find.byType(ListTile), findsNothing);
        await tester.enterText(find.byType(TextField), query);
        await tester.pumpAndSettle();
        expect(find.byType(ListTile), findsOneWidget);
        expect(find.text('سورة 1'), findsOneWidget);
        expect(find.text('سُورَةُ ٱلْفَاتِحَةِ'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'no matching surah');
        await tester.pumpAndSettle();
        expect(find.byType(ListTile), findsNothing);
        expect(
          find.text('لا توجد نتائج. جرّب تعديل كلمات البحث'),
          findsOneWidget,
        );
        await tester.enterText(find.byType(TextField), query);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(ListTile));
        await tester.pumpAndSettle();
        expect(find.text('reader 1'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('offline result opens the exact ayah and page', (tester) async {
    Map<String, dynamic>? extra;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => QuranSearchScreen(repository: SearchRepository()),
        ),
        GoRoute(
          path: '/quran/surah/:number',
          builder: (_, state) {
            extra = state.extra as Map<String, dynamic>;
            return const Scaffold(body: Text('reader'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await pumpSearch(tester, MaterialApp.router(routerConfig: router));
    await tester.enterText(find.byType(TextField), 'بسم الله');
    await tester.pump();
    expect(find.byType(ListTile), findsOneWidget);
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(find.text('reader'), findsOneWidget);
    expect(extra, {
      'initialSurahNumber': 1,
      'initialAyahNumber': 1,
      'initialPageNumber': 1,
    });
  });
}
