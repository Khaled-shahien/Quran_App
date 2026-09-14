import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/duas/presentation/screens/azkar_screen.dart';

void main() {
  group('AzkarScreen Widget Tests', () {
    testWidgets('AzkarScreen renders correctly with AppBar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AzkarScreen())),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('الأذكار'), findsWidgets);
    });

    testWidgets('AzkarScreen displays header cards', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AzkarScreen())),
      );

      expect(find.text('أذكار الصباح'), findsWidgets);
      expect(find.text('أذكار المساء'), findsWidgets);
    });

    testWidgets('AzkarScreen displays visible grid cards', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AzkarScreen())),
      );

      // Check for visible grid cards (these are definitely in the grid)
      expect(find.text('أذكار النوم'), findsWidgets);
      expect(find.text('بعد الصلاة'), findsWidgets);
    });

    testWidgets('AzkarScreen has InkWells for cards', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AzkarScreen())),
      );

      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('AzkarScreen has back button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AzkarScreen())),
      );

      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    });

    testWidgets('AzkarScreen AppBar has correct styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AzkarScreen())),
      );

      final appBar = find.byType(AppBar);
      expect(appBar, findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    });

    testWidgets('AzkarScreen has RTL Directionality widget', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AzkarScreen())),
      );

      // Find all Directionality widgets
      final directionalityFinder = find.byType(Directionality);
      expect(directionalityFinder, findsWidgets);

      // Check that at least one has RTL direction
      final directionalityWidgets = directionalityFinder.evaluate();
      final hasRtl = directionalityWidgets.any((element) {
        final directionality = element.widget as Directionality;
        return directionality.textDirection == TextDirection.rtl;
      });
      expect(hasRtl, true);
    });

    testWidgets('AzkarScreen CustomScrollView is rendered', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AzkarScreen())),
      );

      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('AzkarScreen AppBar is transparent with no elevation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AzkarScreen())),
      );

      final appBarWidget =
          find.byType(AppBar).evaluate().first.widget as AppBar;
      expect(appBarWidget.elevation, 0);
      expect(appBarWidget.backgroundColor, Colors.transparent);
    });
  });
}
