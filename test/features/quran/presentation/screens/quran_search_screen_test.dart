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

void main() {
  for (final query in ['الفاتحة', '١', '1']) {
    testWidgets('surah lookup supports $query offline', (tester) async {
      // The binding clears asset caches between tests. Decode outside fake time.
      await tester.runAsync(() => rootBundle.loadString('assets/quran_master.json'));
      await tester.pumpWidget(
        MaterialApp(home: QuranSearchScreen(repository: SearchRepository())),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), query);
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('سورة 1'), findsOneWidget);
    });
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
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
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
