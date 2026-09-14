import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/widgets/pulse_loader.dart';
import 'package:sakina_app/features/duas/data/models/azkar_model.dart';
import 'package:sakina_app/features/duas/data/repositories/azkar_repository.dart';
import 'package:sakina_app/features/duas/presentation/providers/azkar_provider.dart';
import 'package:sakina_app/features/duas/presentation/screens/azkar_details_screen.dart';

class _DummyAzkarRepository implements AzkarRepository {
  @override
  Future<List<AzkarCategoryModel>> getAllAzkar() async =>
      <AzkarCategoryModel>[];
}

class TestAzkarProvider extends AzkarProvider {
  bool testIsLoading;
  String? testErrorMessage;
  final Map<String, AzkarCategoryModel?> _categoriesByName;

  TestAzkarProvider({
    this.testIsLoading = false,
    this.testErrorMessage,
    Map<String, AzkarCategoryModel?> categoriesByName =
        const <String, AzkarCategoryModel?>{},
  }) : _categoriesByName = categoriesByName,
       super(repository: _DummyAzkarRepository());

  @override
  bool get isLoading => testIsLoading;

  @override
  String? get errorMessage => testErrorMessage;

  @override
  AzkarCategoryModel? getCategoryByName(String name) => _categoriesByName[name];
}

void main() {
  Widget createTestWidget({
    required String categoryName,
    required AzkarProvider provider,
  }) {
    return MaterialApp(
      home: ChangeNotifierProvider<AzkarProvider>.value(
        value: provider,
        child: AzkarDetailsScreen(categoryName: categoryName),
      ),
    );
  }

  group('AzkarDetailsScreen Tests', () {
    testWidgets('should display AppBar with category name', (
      WidgetTester tester,
    ) async {
      const categoryName = 'أذكار الصباح';
      final provider = TestAzkarProvider();

      await tester.pumpWidget(
        createTestWidget(categoryName: categoryName, provider: provider),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text(categoryName), findsOneWidget);
    });

    testWidgets('should display loading indicator when loading', (
      WidgetTester tester,
    ) async {
      final provider = TestAzkarProvider(testIsLoading: true);

      await tester.pumpWidget(
        createTestWidget(categoryName: 'أذكار الصباح', provider: provider),
      );
      await tester.pump();

      expect(find.byType(PulseLoader), findsOneWidget);
    });

    testWidgets('should display error message when error occurs', (
      WidgetTester tester,
    ) async {
      final provider = TestAzkarProvider(testErrorMessage: 'خطأ في التحميل');

      await tester.pumpWidget(
        createTestWidget(categoryName: 'أذكار الصباح', provider: provider),
      );
      await tester.pumpAndSettle();

      expect(find.text('حدث خطأ في تحميل الأذكار'), findsOneWidget);
    });

    testWidgets('should display empty state when no data', (
      WidgetTester tester,
    ) async {
      final provider = TestAzkarProvider(
        categoriesByName: <String, AzkarCategoryModel?>{
          'أذكار الصباح': AzkarCategoryModel(
            id: 1,
            category: 'أذكار الصباح',
            items: <AzkarItemModel>[],
          ),
        },
      );

      await tester.pumpWidget(
        createTestWidget(categoryName: 'أذكار الصباح', provider: provider),
      );
      await tester.pumpAndSettle();

      expect(find.text('لا توجد بيانات لهذا القسم حالياً'), findsOneWidget);
    });

    testWidgets('should display category not found message when null', (
      WidgetTester tester,
    ) async {
      final provider = TestAzkarProvider();

      await tester.pumpWidget(
        createTestWidget(categoryName: 'غير معروف', provider: provider),
      );
      await tester.pumpAndSettle();

      expect(find.text('لا توجد بيانات لهذا القسم حالياً'), findsOneWidget);
    });

    testWidgets('should display list of items when data available', (
      WidgetTester tester,
    ) async {
      final items = [
        AzkarItemModel(
          id: 1,
          title: 'الذكر الأول',
          text: 'نص الذكر الأول',
          repeat: 3,
          reference: 'المرجعية الأولى',
        ),
        AzkarItemModel(
          id: 2,
          title: 'الذكر الثاني',
          text: 'نص الذكر الثاني',
          repeat: 2,
          reference: 'المرجعية الثانية',
        ),
      ];

      final provider = TestAzkarProvider(
        categoriesByName: <String, AzkarCategoryModel?>{
          'أذكار الصباح': AzkarCategoryModel(
            id: 1,
            category: 'أذكار الصباح',
            items: items,
          ),
        },
      );

      await tester.pumpWidget(
        createTestWidget(categoryName: 'أذكار الصباح', provider: provider),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should have back button in AppBar', (
      WidgetTester tester,
    ) async {
      final provider = TestAzkarProvider();

      await tester.pumpWidget(
        createTestWidget(categoryName: 'أذكار الصباح', provider: provider),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    });

    testWidgets('should pop on back button press', (WidgetTester tester) async {
      final provider = TestAzkarProvider();

      await tester.pumpWidget(
        createTestWidget(categoryName: 'أذكار الصباح', provider: provider),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back_ios));
      await tester.pumpAndSettle();
    });

    testWidgets('should display RTL text direction', (
      WidgetTester tester,
    ) async {
      final provider = TestAzkarProvider(
        categoriesByName: <String, AzkarCategoryModel?>{
          'أذكار الصباح': AzkarCategoryModel(
            id: 1,
            category: 'أذكار الصباح',
            items: <AzkarItemModel>[
              AzkarItemModel(
                id: 1,
                title: 'الذكر الأول',
                text: 'نص الذكر الأول',
                repeat: 1,
                reference: '',
              ),
            ],
          ),
        },
      );

      await tester.pumpWidget(
        createTestWidget(categoryName: 'أذكار الصباح', provider: provider),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Directionality), findsWidgets);
    });

    testWidgets('should use Consumer widget for state management', (
      WidgetTester tester,
    ) async {
      final provider = TestAzkarProvider();

      await tester.pumpWidget(
        createTestWidget(categoryName: 'أذكار الصباح', provider: provider),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Consumer<AzkarProvider>), findsOneWidget);
    });

    testWidgets('should have SafeArea for proper insets', (
      WidgetTester tester,
    ) async {
      final provider = TestAzkarProvider();

      await tester.pumpWidget(
        createTestWidget(categoryName: 'أذكار الصباح', provider: provider),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SafeArea), findsWidgets);
    });

    testWidgets('should display Scaffold with proper theme', (
      WidgetTester tester,
    ) async {
      final provider = TestAzkarProvider();

      await tester.pumpWidget(
        createTestWidget(categoryName: 'أذكار الصباح', provider: provider),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle multiple categories correctly', (
      WidgetTester tester,
    ) async {
      final provider = TestAzkarProvider(
        categoriesByName: <String, AzkarCategoryModel?>{
          'أذكار المساء': AzkarCategoryModel(
            id: 2,
            category: 'أذكار المساء',
            items: <AzkarItemModel>[
              AzkarItemModel(
                id: 1,
                title: 'ذكر',
                text: 'النص',
                repeat: 1,
                reference: '',
              ),
            ],
          ),
        },
      );

      await tester.pumpWidget(
        createTestWidget(categoryName: 'أذكار المساء', provider: provider),
      );
      await tester.pumpAndSettle();

      expect(find.text('أذكار المساء'), findsOneWidget);
    });
  });
}
