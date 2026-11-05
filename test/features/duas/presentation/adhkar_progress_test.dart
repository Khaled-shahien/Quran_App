import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/features/duas/data/models/azkar_model.dart';
import 'package:sakina_app/features/duas/data/repositories/azkar_repository.dart';
import 'package:sakina_app/features/duas/presentation/providers/adhkar_progress_controller.dart';
import 'package:sakina_app/features/duas/presentation/providers/azkar_provider.dart';
import 'package:sakina_app/features/duas/presentation/screens/azkar_details_screen.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

final items = [
  AzkarItemModel(id: 1, title: 'أ', text: 'نص أ', repeat: 3, reference: 'م'),
  AzkarItemModel(id: 2, title: 'ب', text: 'نص ب', repeat: 1, reference: 'م'),
];

class _Repo implements AzkarRepository {
  @override
  Future<Result<List<AzkarCategoryModel>>> getAllAzkar() async => Success([
    AzkarCategoryModel(id: 1, category: 'أذكار الصباح', items: items),
  ]);
}

void main() {
  late SharedPreferences prefs;
  var day = DateTime(2026, 11, 5, 7);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    day = DateTime(2026, 11, 5, 7);
  });

  AdhkarProgressController controller() => AdhkarProgressController(
    preferences: prefs,
    category: 'أذكار الصباح',
    items: items,
    clock: () => day,
  );

  test('counts up to the target and never overshoots', () {
    final c = controller();
    expect(c.increment(items[0]), isFalse);
    expect(c.increment(items[0]), isFalse);
    expect(c.increment(items[0]), isTrue, reason: 'third tap completes');
    expect(c.increment(items[0]), isFalse);
    expect(c.countOf(items[0]), 3);
  });

  test('all complete only when every dhikr is done', () {
    final c = controller();
    for (var i = 0; i < 3; i++) {
      c.increment(items[0]);
    }
    expect(c.allComplete, isFalse);
    c.increment(items[1]);
    expect(c.allComplete, isTrue);
  });

  test(
    'progress survives a restart the same day, then resets tomorrow',
    () async {
      controller().increment(items[0]);
      await Future<void>.delayed(Duration.zero);
      expect(controller().countOf(items[0]), 1);

      day = DateTime(2026, 11, 6, 7);
      expect(controller().countOf(items[0]), 0);
    },
  );

  test('reset can be undone', () {
    final c = controller();
    c.increment(items[0]);
    c.increment(items[1]);
    final before = c.reset();
    expect(c.completedItems, 0);
    c.restore(before);
    expect(c.countOf(items[0]), 1);
    expect(c.isComplete(items[1]), isTrue);
  });

  testWidgets('tapping a card counts and the end shows encouragement', (
    tester,
  ) async {
    final azkar = AzkarProvider(repository: _Repo());
    await azkar.loadAzkar();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SharedPreferences>.value(value: prefs),
          ChangeNotifierProvider.value(value: azkar),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AzkarDetailsScreen(categoryName: 'أذكار الصباح'),
        ),
      ),
    );

    expect(find.text('0 من 3'), findsOneWidget);
    await tester.tap(find.text('نص أ'));
    await tester.pump();
    expect(find.text('1 من 3'), findsOneWidget);

    await tester.tap(find.text('نص أ'));
    await tester.tap(find.text('نص أ'));
    await tester.tap(find.text('نص ب'));
    await tester.pump();
    expect(find.text('تم'), findsNWidgets(2));
    expect(find.textContaining('ما شاء الله'), findsWidgets);

    await tester.tap(find.text('البدء من جديد'));
    await tester.pumpAndSettle();
    expect(find.text('0 من 3'), findsOneWidget);
    await tester.tap(find.text('تراجع'));
    await tester.pump();
    expect(find.text('تم'), findsNWidgets(2));
  });
}
