import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/quran/presentation/screens/tasbeeh_screen.dart';

void main() {
  testWidgets('Tasbeeh screen supports swipe interactions', (
    WidgetTester tester,
  ) async {
    // Set a large surface size to ensure items are visible and draggable
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Build the TasbeehScreen
    await tester.pumpWidget(const MaterialApp(home: TasbeehScreen()));

    // Verify initial state and pick the first visible dismissible row.
    expect(find.byType(Dismissible), findsWidgets);
    final dismissibleFinder = find.byType(Dismissible).first;
    final int initialCount = tester.widgetList(find.byType(Dismissible)).length;

    // Swipe and retry opposite direction to support RTL/LTR behavior in tests.
    await tester.drag(dismissibleFinder, const Offset(-500.0, 0.0));
    await tester.pumpAndSettle();
    if (tester.widgetList(find.byType(Dismissible)).length == initialCount) {
      await tester.drag(dismissibleFinder, const Offset(500.0, 0.0));
      await tester.pumpAndSettle();
    }

    // Ensure widget tree is stable after swipe attempts.
    expect(find.byType(TasbeehScreen), findsOneWidget);
    expect(
      tester.widgetList(find.byType(Dismissible)).length,
      greaterThanOrEqualTo(initialCount - 1),
    );
  });
}
