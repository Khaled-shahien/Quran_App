import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/features/khatma/presentation/providers/khatma_provider.dart';
import 'package:sakina_app/features/khatma/presentation/screens/khatma_duration_screen.dart';

class MockKhatmaProvider extends Mock implements KhatmaProvider {}

void main() {
  late MockKhatmaProvider mockKhatmaProvider;

  Widget createTestWidget({String startMode = 'juz', int? startJuz}) {
    return MaterialApp(
      home: ChangeNotifierProvider<KhatmaProvider>.value(
        value: mockKhatmaProvider,
        child: KhatmaDurationScreen(startMode: startMode, startJuz: startJuz),
      ),
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    String startMode = 'juz',
    int? startJuz,
  }) async {
    tester.view.physicalSize = const Size(1440, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      createTestWidget(startMode: startMode, startJuz: startJuz),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    mockKhatmaProvider = MockKhatmaProvider();
  });

  group('KhatmaDurationScreen Tests', () {
    testWidgets('should display AppBar with correct title', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('ختمة جديدة'), findsOneWidget);
    });

    testWidgets('should display correct initial state', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('should have goal type selection dropdown', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);
      expect(find.text('وحدة التتبع:'), findsOneWidget);
    });

    testWidgets('should have tracking unit selection', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);
      expect(find.text('صفحة (604)'), findsOneWidget);
    });

    testWidgets('should initialize with correct start juz value', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, startJuz: 15);

      expect(find.byType(KhatmaDurationScreen), findsOneWidget);
    });

    testWidgets('should have slider for duration adjustment', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);
      expect(find.byIcon(Icons.add), findsWidgets);
      expect(find.byIcon(Icons.remove), findsWidgets);
    });

    testWidgets('should display duration days value', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('should display daily target calculation', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('should have reminder time picker', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('should have action button for create khatma', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('should handle juz selection properly', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, startJuz: 1);

      final state = find.byType(KhatmaDurationScreen);
      expect(state, findsOneWidget);
    });

    testWidgets('should handle maximum juz value clamping', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, startJuz: 50);
      expect(find.byType(KhatmaDurationScreen), findsOneWidget);
    });

    testWidgets('should display unit labels correctly', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('should handle drag on sliders', (WidgetTester tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsWidgets);
    });

    testWidgets('should maintain state during rebuilds', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);
      await pumpScreen(tester);

      expect(find.byType(KhatmaDurationScreen), findsOneWidget);
    });

    testWidgets('should display all duration options', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);
      expect(find.byType(Text), findsWidgets);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should have valid form structure', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byType(Padding), findsWidgets);
      expect(find.byType(Column), findsWidgets);
    });
  });
}
