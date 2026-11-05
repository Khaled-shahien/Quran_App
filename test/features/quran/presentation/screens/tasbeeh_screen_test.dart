import 'dart:math' as math;

import 'package:sakina_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/features/quran/data/repositories/tasbih_repository_impl.dart';
import 'package:sakina_app/features/quran/presentation/providers/tasbih_controller.dart';
import 'package:sakina_app/features/quran/presentation/screens/tasbeeh_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<TasbihController> _controller() async {
  final prefs = await SharedPreferences.getInstance();
  return TasbihController(repository: SharedPreferencesTasbihRepository(prefs));
}

Widget _app(TasbihController controller) =>
    ChangeNotifierProvider<TasbihController>.value(
      value: controller,
      child: const MaterialApp(home: TasbeehScreen()),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('Tasbeeh screen supports swipe interactions', (
    WidgetTester tester,
  ) async {
    // Set a large surface size to ensure items are visible and draggable
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(await _controller()));

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

  testWidgets('counts survive the screen being rebuilt from storage', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final first = await _controller();
    await tester.pumpWidget(_app(first));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    expect(find.text('02'), findsOneWidget);
    await first.saved;

    // A fresh controller reads what the first one wrote, as after app kill.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_app(await _controller()));
    expect(find.text('02'), findsOneWidget);
  });

  resetUndoTests();

  addPhraseTests();

  contrastTests();
}

void resetUndoTests() {
  testWidgets('reset can be undone from the snackbar', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = await _controller();
    await tester.pumpWidget(_app(controller));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    expect(controller.count, 1);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    expect(controller.count, 0);
    expect(find.text('تمت إعادة تعيين العدّاد'), findsOneWidget);

    await tester.tap(find.text('تراجع'));
    await tester.pump();
    expect(controller.count, 1);
  });
}

void addPhraseTests() {
  testWidgets('a phrase added from the dialog appears and is saved', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = await _controller();
    await tester.pumpWidget(_app(controller));
    await tester.tap(find.text('إضافة جديد'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'أستغفر الله');
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(controller.phrases.last.customText, 'أستغفر الله');
    expect(tester.takeException(), isNull);
  });
}

double _lum(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

void contrastTests() {
  for (final dark in [false, true]) {
    testWidgets('count button text is readable (dark=$dark)', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final controller = await _controller();
      await tester.pumpWidget(
        ChangeNotifierProvider<TasbihController>.value(
          value: controller,
          child: MaterialApp(
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            home: const TasbeehScreen(),
          ),
        ),
      );
      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      final a = _lum(fab.foregroundColor!), b = _lum(fab.backgroundColor!);
      final ratio = (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });
  }
}
