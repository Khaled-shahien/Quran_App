import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sakina_app/features/hadeath/presentation/widgets/hadeath_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget buildHarness({required Widget child}) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Colors.teal,
          secondary: Color(0xFFE6F4EA),
        ),
      ),
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('renders title and action icons', (tester) async {
    await tester.pumpWidget(
      buildHarness(
        child: HadeathCard(title: 'حديث الاختبار', onTap: () {}),
      ),
    );

    expect(find.text('حديث الاختبار'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(find.byIcon(Icons.menu_book), findsOneWidget);

    final card = tester.widget<Card>(find.byType(Card));
    expect(card.color, const Color(0xFFE6F4EA));
  });

  testWidgets('invokes callback when card is tapped', (tester) async {
    var tapped = 0;

    await tester.pumpWidget(
      buildHarness(
        child: HadeathCard(
          title: 'حديث قابل للنقر',
          onTap: () {
            tapped++;
          },
        ),
      ),
    );

    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(tapped, 1);
  });
}
