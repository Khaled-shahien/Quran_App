import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/features/duas/data/repositories/azkar_repository.dart';
import 'package:sakina_app/core/theme/app_theme.dart';
import 'package:sakina_app/features/duas/data/models/azkar_model.dart';
import 'package:sakina_app/features/duas/presentation/providers/azkar_provider.dart';
import 'package:sakina_app/features/duas/presentation/screens/azkar_details_screen.dart';
import 'package:sakina_app/features/quran/data/repositories/tasbih_repository_impl.dart';
import 'package:sakina_app/features/quran/presentation/providers/tasbih_controller.dart';
import 'package:sakina_app/features/quran/presentation/screens/tasbeeh_screen.dart';
import 'package:sakina_app/features/recitation/presentation/providers/recitation_controller.dart';
import 'package:sakina_app/features/recitation/presentation/providers/recitation_downloads_controller.dart';
import 'package:sakina_app/features/recitation/presentation/screens/recitation_screen.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/duas/presentation/adhkar_progress_test.dart' as adhkar;
import '../features/recitation/fakes.dart';

/// Every main screen must stay usable for seniors: 200% system text on a
/// small phone without overflow, 48dp tap targets and labelled buttons.
Future<void> pumpAudited(
  WidgetTester tester,
  Widget home, {
  required List<SingleChildWidget> providers,
  bool dark = false,
}) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    MultiProvider(
      providers: providers,
      child: MaterialApp(
        theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> expectAccessible(WidgetTester tester) async {
  expect(tester.takeException(), isNull, reason: 'no overflow at 200% text');
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
}

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  for (final dark in [false, true]) {
    testWidgets('tasbih (dark=$dark)', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpAudited(
        tester,
        const TasbeehScreen(),
        dark: dark,
        providers: [
          ChangeNotifierProvider(
            create: (_) => TasbihController(
              repository: SharedPreferencesTasbihRepository(prefs),
            ),
          ),
        ],
      );
      await expectAccessible(tester);
      semantics.dispose();
    });

    testWidgets('adhkar (dark=$dark)', (tester) async {
      final semantics = tester.ensureSemantics();
      final azkar = AzkarProvider(repository: _AdhkarRepo());
      await azkar.loadAzkar();
      await pumpAudited(
        tester,
        const AzkarDetailsScreen(categoryName: 'أذكار الصباح'),
        dark: dark,
        providers: [
          Provider<SharedPreferences>.value(value: prefs),
          ChangeNotifierProvider.value(value: azkar),
        ],
      );
      await expectAccessible(tester);
      semantics.dispose();
    });

    testWidgets('recitation (dark=$dark)', (tester) async {
      final semantics = tester.ensureSemantics();
      final repository = FakeRepository();
      final controller = RecitationController(
        repository: repository,
        engine: FakeEngine(),
        preferences: prefs,
        surahName: (s) => 'سورة $s',
      );
      await controller.initialize();
      await pumpAudited(
        tester,
        const RecitationScreen(),
        dark: dark,
        providers: [
          ChangeNotifierProvider.value(value: controller),
          ChangeNotifierProvider(
            create: (_) =>
                RecitationDownloadsController(repository: repository),
          ),
        ],
      );
      await expectAccessible(tester);
      semantics.dispose();
    });
  }
}

class _AdhkarRepo implements AzkarRepository {
  @override
  Future<Result<List<AzkarCategoryModel>>> getAllAzkar() async => Success([
    AzkarCategoryModel(id: 1, category: 'أذكار الصباح', items: adhkar.items),
  ]);
}
