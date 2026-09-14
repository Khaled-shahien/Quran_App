import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina_app/features/quran/domain/entities/surah_entity.dart';
import 'package:sakina_app/features/quran/domain/repositories/surah_repository.dart';
import 'package:sakina_app/features/quran/presentation/providers/bookmark_provider.dart';
import 'package:sakina_app/features/quran/presentation/screens/quran_screen.dart';
import 'package:sakina_app/features/quran/presentation/screens/surah_details_screen.dart';

class FakeSurahRepository implements SurahRepository {
  FakeSurahRepository(this._surahs);

  final List<SurahEntity> _surahs;

  @override
  Future<void> clearCache() async {}

  @override
  Future<List<SurahEntity>> getAllSurahs() async => _surahs;

  @override
  Future<SurahEntity> getSurahByIndex(int index) async =>
      _surahs.firstWhere((surah) => surah.number == index);

  @override
  Future<Map<String, dynamic>> getSurahStatistics() async =>
      <String, dynamic>{};

  @override
  Future<List<SurahEntity>> getSurahsByRevelationPlace(String place) async {
    return _surahs.where((surah) => surah.revelationType == place).toList();
  }

  @override
  Future<List<SurahEntity>> searchSurahs(String query) async {
    return _surahs.where((surah) => surah.name.contains(query)).toList();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = true;
  });

  testWidgets('Quran E2E flow: list -> navigate -> reading details', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final bookmarkProvider = BookmarkProvider(prefs: prefs);

    final surahs = <SurahEntity>[
      SurahEntity(
        number: 1,
        name: 'سورة الفاتحة',
        englishName: 'Al-Fatihah',
        englishNameTranslation: 'The Opening',
        revelationType: 'mecca',
        totalAyah: 7,
      ),
      SurahEntity(
        number: 2,
        name: 'سورة البقرة',
        englishName: 'Al-Baqarah',
        englishNameTranslation: 'The Cow',
        revelationType: 'medinan',
        totalAyah: 286,
      ),
    ];
    final repository = FakeSurahRepository(surahs);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SurahRepository>.value(value: repository),
          ChangeNotifierProvider<BookmarkProvider>.value(
            value: bookmarkProvider,
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const QuranScreen(),
              ),
              GoRoute(
                path: '/quran/surah/:number',
                builder: (context, state) {
                  final number = int.parse(state.pathParameters['number']!);
                  final extra = state.extra as Map<String, dynamic>?;
                  final surah =
                      extra?['surah'] as SurahEntity? ??
                      surahs.firstWhere((item) => item.number == number);
                  return SurahDetailsScreen(surah: surah, surahNumber: number);
                },
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('القرآن الكريم'), findsOneWidget);
    expect(find.text('سورة الفاتحة'), findsOneWidget);

    await tester.tap(find.text('سورة الفاتحة').first);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byType(SurahDetailsScreen), findsOneWidget);
    expect(find.text('سورة الفاتحة'), findsOneWidget);
    expect(find.textContaining('بِسْمِ اللَّهِ'), findsOneWidget);
    expect(find.byType(SelectableText), findsWidgets);
  });
}
