import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/onboarding/presentation/widgets/date_card_widget.dart';

void main() {
  testWidgets('shows weekday, Hijri and Gregorian dates', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: DateCardWidget(clock: () => DateTime(2024, 3, 11, 10)),
          ),
        ),
      ),
    );

    expect(find.text('الاثنين'), findsOneWidget);
    expect(find.textContaining('1 رمضان 1445هـ', findRichText: true), findsOne);
    expect(find.textContaining('11 مارس 2024م', findRichText: true), findsOne);

    // The midnight refresh timer must not leak past the widget.
    await tester.pumpWidget(const SizedBox());
  });
}
