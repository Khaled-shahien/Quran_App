import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sakina_app/features/onboarding/presentation/screens/onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Onboarding screen loads smoke test', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: OnboardingScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('أهلًا بك في سكينة'), findsOneWidget);
    expect(find.text('التالي'), findsOneWidget);
  });
}
