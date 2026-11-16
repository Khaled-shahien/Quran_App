import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/quran/presentation/screens/asma_al_husna_screen.dart';
import 'package:sakina_app/features/quran/presentation/widgets/asma_item_card.dart';

/// Names are built from code points so the expected text cannot drift
/// through editor normalisation of the diacritics.
String _cp(List<int> points) => String.fromCharCodes(points);

/// الْمُذِلُّ, spelled like name 24 الْمُعِزُّ (damma before shadda).
final String _alMudhill = _cp(const [
  0x0627, 0x0644, 0x0652, 0x0645, 0x064F, //
  0x0630, 0x0650, 0x0644, 0x064F, 0x0651,
]);

/// الذَّلِيلُ, the wrong word that was once shown as name 25.
final String _adhDhalil = _cp(const [
  0x0627, 0x0644, 0x0630, 0x064E, 0x0651, //
  0x0644, 0x0650, 0x064A, 0x0644, 0x064F,
]);

void main() {
  testWidgets('name 25 is Al-Mudhill, and Adh-Dhalil appears nowhere', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AsmaAlHusnaScreen()));
    await tester.pumpAndSettle();

    final card = find.byWidgetPredicate(
      (w) => w is AsmaItemCard && w.number == '25',
    );
    await tester.scrollUntilVisible(
      card,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final AsmaItemCard item = tester.widget(card);
    expect(item.arabicName, _alMudhill);
    expect(item.meaning, 'The Giver of Dishonor');
    expect(find.text(_adhDhalil), findsNothing);
  });

  testWidgets('the list holds all 99 names, numbered 1 to 99 in order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 60000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: AsmaAlHusnaScreen()));
    await tester.pumpAndSettle();

    final numbers = tester
        .widgetList<AsmaItemCard>(find.byType(AsmaItemCard))
        .map((c) => int.parse(c.number))
        .toList();
    expect(numbers, List<int>.generate(99, (i) => i + 1));
    final names = tester
        .widgetList<AsmaItemCard>(find.byType(AsmaItemCard))
        .map((c) => c.arabicName)
        .toSet();
    expect(names.length, 99, reason: 'no name repeated');
    expect(names.contains(_adhDhalil), isFalse);
  });
}
