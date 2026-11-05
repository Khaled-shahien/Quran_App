import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/qibla/presentation/screens/qibla_screen.dart';
import 'package:sakina_app/l10n/app_localizations.dart';

double paintedHeading(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(QiblaDial),
      matching: find.byType(CustomPaint),
    ),
  );
  return (paint.painter as dynamic).heading as double;
}

Widget dial(double heading, {bool reduceMotion = false}) => MaterialApp(
  locale: const Locale('ar'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(
      body: QiblaDial(bearing: 136, heading: heading, aligned: false),
    ),
  ),
);

void main() {
  testWidgets('glides the short way across north', (tester) async {
    await tester.pumpWidget(dial(350));
    await tester.pumpWidget(dial(10));
    await tester.pump(const Duration(milliseconds: 100));
    final mid = paintedHeading(tester);
    // Moving 350 -> 370 (= 10), never back through 180.
    expect(mid, greaterThan(350));
    expect(mid, lessThan(370));
    await tester.pumpAndSettle();
    expect(paintedHeading(tester) % 360, closeTo(10, 1e-6));
  });

  testWidgets('jumps straight to the reading with reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(dial(0, reduceMotion: true));
    await tester.pumpWidget(dial(90, reduceMotion: true));
    await tester.pump();
    expect(paintedHeading(tester), closeTo(90, 1e-6));
  });
}
