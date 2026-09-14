import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:sakina_app/features/duas/data/models/azkar_model.dart';
import 'package:sakina_app/features/duas/data/repositories/azkar_repository.dart';
import 'package:sakina_app/features/duas/presentation/providers/azkar_provider.dart';
import 'package:sakina_app/features/duas/presentation/screens/azkar_details_screen.dart';
import 'package:sakina_app/features/duas/presentation/screens/azkar_screen.dart';

class FakeAzkarRepository implements AzkarRepository {
  @override
  Future<List<AzkarCategoryModel>> getAllAzkar() async {
    return <AzkarCategoryModel>[
      AzkarCategoryModel(
        id: 1,
        category: 'أذكار الصباح',
        items: <AzkarItemModel>[
          AzkarItemModel(
            id: 101,
            title: 'ذكر الصباح',
            text: 'اللَّهُمَّ بِكَ أَصْبَحْنَا وَبِكَ أَمْسَيْنَا',
            repeat: 1,
            reference: 'رواه الترمذي',
          ),
        ],
      ),
    ];
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = true;
  });

  testWidgets('Duas flow: azkar list -> details navigation', (tester) async {
    final provider = AzkarProvider(repository: FakeAzkarRepository());
    await provider.loadAzkar();

    await tester.pumpWidget(
      ChangeNotifierProvider<AzkarProvider>.value(
        value: provider,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: <RouteBase>[
              GoRoute(
                path: '/',
                builder: (context, state) => const AzkarScreen(),
              ),
              GoRoute(
                path: '/azkar/details',
                builder: (context, state) {
                  final Map<String, dynamic>? extra =
                      state.extra as Map<String, dynamic>?;
                  return AzkarDetailsScreen(
                    categoryName: extra?['categoryName'] as String? ?? '',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('الأذكار'), findsOneWidget);
    expect(find.text('أذكار الصباح'), findsOneWidget);

    await tester.tap(find.text('أذكار الصباح').first);
    await tester.pumpAndSettle();

    expect(find.byType(AzkarDetailsScreen), findsOneWidget);
    expect(find.text('أذكار الصباح'), findsWidgets);
    expect(find.text('ذكر الصباح'), findsOneWidget);
    expect(find.textContaining('اللَّهُمَّ بِكَ أَصْبَحْنَا'), findsOneWidget);
  });
}
