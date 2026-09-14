import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina_app/core/widgets/pulse_loader.dart';
import 'package:sakina_app/features/quran/domain/entities/surah_entity.dart';
import 'package:sakina_app/features/quran/domain/repositories/surah_repository.dart';
import 'package:sakina_app/features/quran/presentation/providers/bookmark_provider.dart';
import 'package:sakina_app/features/quran/presentation/screens/quran_screen.dart';

import '../../../../helpers/router_test_helper.dart';

class FakeSurahRepository implements SurahRepository {
  FakeSurahRepository({this.shouldThrow = false, List<SurahEntity>? surahs})
    : _surahs =
          surahs ??
          <SurahEntity>[
            SurahEntity(
              number: 1,
              name: 'الفاتحة',
              englishName: 'Al-Fatihah',
              englishNameTranslation: 'The Opening',
              revelationType: 'mecca',
              totalAyah: 7,
            ),
            SurahEntity(
              number: 2,
              name: 'البقرة',
              englishName: 'Al-Baqarah',
              englishNameTranslation: 'The Cow',
              revelationType: 'medinan',
              totalAyah: 286,
            ),
          ];

  final bool shouldThrow;
  final List<SurahEntity> _surahs;
  int getAllCalls = 0;

  @override
  Future<void> clearCache() async {}

  @override
  Future<List<SurahEntity>> getAllSurahs() async {
    getAllCalls++;
    if (shouldThrow) {
      throw Exception('failed to load surahs');
    }
    return _surahs;
  }

  @override
  Future<SurahEntity> getSurahByIndex(int index) async => _surahs[index - 1];

  @override
  Future<Map<String, dynamic>> getSurahStatistics() async =>
      <String, dynamic>{};

  @override
  Future<List<SurahEntity>> getSurahsByRevelationPlace(String place) async =>
      _surahs.where((s) => s.revelationType == place).toList();

  @override
  Future<List<SurahEntity>> searchSurahs(String query) async => _surahs;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget buildQuranTestApp({
    required SurahRepository repository,
    List<RouteBase> routes = const <RouteBase>[],
  }) {
    return Provider<SurahRepository>.value(
      value: repository,
      child: buildRouterTestApp(home: const QuranScreen(), routes: routes),
    );
  }

  testWidgets('shows surah list with localized revelation type', (
    tester,
  ) async {
    final repository = FakeSurahRepository();

    await tester.pumpWidget(buildQuranTestApp(repository: repository));

    await tester.pumpAndSettle();

    expect(find.text('القرآن الكريم'), findsOneWidget);
    expect(find.text('الفاتحة'), findsOneWidget);
    expect(find.text('البقرة'), findsOneWidget);
    expect(find.text('مكية'), findsOneWidget);
    expect(find.text('مدنية'), findsOneWidget);
    expect(find.text('7 آية'), findsOneWidget);
  });

  testWidgets('shows error state and retry button when load fails', (
    tester,
  ) async {
    final repository = FakeSurahRepository(shouldThrow: true);

    await tester.pumpWidget(buildQuranTestApp(repository: repository));

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    expect(repository.getAllCalls, greaterThanOrEqualTo(2));
  });

  testWidgets('shows loading indicator before data settles', (tester) async {
    final repository = FakeSurahRepository();

    await tester.pumpWidget(buildQuranTestApp(repository: repository));

    expect(find.byType(PulseLoader), findsOneWidget);
  });

  testWidgets('keeps unknown revelation type as is', (tester) async {
    final repository = FakeSurahRepository(
      surahs: <SurahEntity>[
        SurahEntity(
          number: 3,
          name: 'آل عمران',
          englishName: 'Ali Imran',
          englishNameTranslation: 'Family of Imran',
          revelationType: 'custom_place',
          totalAyah: 200,
        ),
      ],
    );

    await tester.pumpWidget(buildQuranTestApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('custom_place'), findsOneWidget);
  });

  testWidgets('navigates to surah details when tapping a surah card', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final bookmarkProvider = BookmarkProvider(prefs: prefs);
    final repository = FakeSurahRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SurahRepository>.value(value: repository),
          ChangeNotifierProvider<BookmarkProvider>.value(
            value: bookmarkProvider,
          ),
        ],
        child: buildRouterTestApp(
          home: const QuranScreen(),
          routes: <RouteBase>[
            GoRoute(
              path: '/quran/surah/:number',
              builder: (context, state) {
                return Scaffold(
                  appBar: AppBar(
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.bookmark_outline),
                        tooltip: 'حفظ العلامة',
                        onPressed: () {},
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('الفاتحة').first);
    await tester.pumpAndSettle();

    expect(find.byTooltip('حفظ العلامة'), findsOneWidget);
  });

  testWidgets('maps short revelation aliases mc/md correctly', (tester) async {
    final repository = FakeSurahRepository(
      surahs: <SurahEntity>[
        SurahEntity(
          number: 1,
          name: 'الفاتحة',
          englishName: 'Al-Fatihah',
          englishNameTranslation: 'The Opening',
          revelationType: 'mc',
          totalAyah: 7,
        ),
        SurahEntity(
          number: 2,
          name: 'البقرة',
          englishName: 'Al-Baqarah',
          englishNameTranslation: 'The Cow',
          revelationType: 'md',
          totalAyah: 286,
        ),
      ],
    );

    await tester.pumpWidget(buildQuranTestApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('مكية'), findsOneWidget);
    expect(find.text('مدنية'), findsOneWidget);
  });

  testWidgets('back button pops QuranScreen route', (tester) async {
    final repository = FakeSurahRepository();

    await tester.pumpWidget(
      Provider<SurahRepository>.value(
        value: repository,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const QuranScreen(),
                        ),
                      );
                    },
                    child: const Text('open'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('القرآن الكريم'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
  });
}
