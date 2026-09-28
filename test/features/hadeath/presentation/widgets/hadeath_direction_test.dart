import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/theme/app_theme.dart';
import 'package:sakina_app/features/hadeath/presentation/widgets/hadeath_card.dart';
import 'package:sakina_app/features/quran/presentation/widgets/asma_item_card.dart';

void main() {
  for (final direction in TextDirection.values) {
    for (final dark in [false, true]) {
      testWidgets('forward card and English text, $direction dark=$dark', (
        tester,
      ) async {
        var taps = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            home: Directionality(
              textDirection: direction,
              child: Scaffold(
                body: Column(
                  children: [
                    HadeathCard(title: 'حديث', onTap: () => taps++),
                    const AsmaItemCard(
                      number: '1',
                      arabicName: 'الرَّحْمٰنُ',
                      meaning: 'The Most Gracious (1).',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        final arrow = find.byIcon(Icons.chevron_right);
        expect(arrow, findsOneWidget);
        final book = find.byIcon(Icons.menu_book);
        expect(
          tester.getCenter(arrow).dx < tester.getCenter(book).dx,
          direction == TextDirection.rtl,
        );
        // The glyph's RTL transform must mirror once, not use an RTL-specific icon.
        final transforms = tester.widgetList<Transform>(
          find.descendant(of: arrow, matching: find.byType(Transform)),
        );
        expect(
          transforms.any((t) => t.transform.entry(0, 0) < 0),
          direction == TextDirection.rtl,
        );
        await tester.tap(find.text('حديث'));
        expect(taps, 1);
        expect(
          tester
              .widget<Text>(find.text('The Most Gracious (1).'))
              .textDirection,
          TextDirection.ltr,
        );
        expect(
          tester.widget<Text>(find.text('الرَّحْمٰنُ')).textDirection,
          TextDirection.rtl,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
