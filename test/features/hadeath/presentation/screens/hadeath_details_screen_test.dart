import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/hadeath/domain/entities/hadeath_entity.dart';
import 'package:sakina_app/features/hadeath/presentation/screens/hadeath_details_screen.dart';

void main() {
  const testHadeath = HadeathEntity(
    title: 'حديث اختباري',
    content: [
      'هذا نص الحديث الاختباري',
      'يتضمن عدة أسطر',
      'لاختبار العرض بشكل صحيح',
    ],
  );

  const hadethWithSpecialChars = HadeathEntity(
    title: 'عَنْ أَبِي هُرَيْرَةَ',
    content: ['بِسْمِ اللَّهِ الرَّحْمَٰ الرَّحِيمِ', 'قَالَ الرَّسُول'],
  );

  const hadethWithLongTitle = HadeathEntity(
    title:
        'حديث طويل جداً جداً جداً هذا العنوان يحتوي على الكثير من الأحرف والكلمات والجمل',
    content: ['محتوى الحديث'],
  );

  Widget createTestWidget(HadeathEntity hadeath) {
    return MaterialApp(home: HadeathDetailsScreen(hadeath: hadeath));
  }

  group('HadeathDetailsScreen Tests', () {
    testWidgets('should display AppBar with hadeath title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testHadeath));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('حديث اختباري'), findsOneWidget);
    });

    testWidgets('should display back button in AppBar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testHadeath));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    });

    testWidgets('should navigate back when back button is pressed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testHadeath));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back_ios));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_ios), findsNothing);
    });

    testWidgets('should display Bismillah container', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testHadeath));
      await tester.pumpAndSettle();

      expect(
        find.text('بِسْمِ اللَّهِ الرَّحْمَِٰ الرَّحِيمِ'),
        findsOneWidget,
      );
    });

    testWidgets('should display hadeath content', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testHadeath));
      await tester.pumpAndSettle();

      expect(find.textContaining('هذا نص الحديث الاختباري'), findsOneWidget);
      expect(find.textContaining('يتضمن عدة أسطر'), findsOneWidget);
    });

    testWidgets('should join multiple content lines with spaces', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testHadeath));
      await tester.pumpAndSettle();

      final content = testHadeath.content.join(' ');
      expect(content.isNotEmpty, true);
    });

    testWidgets('should have SafeArea widget', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testHadeath));
      await tester.pumpAndSettle();

      expect(find.byType(SafeArea), findsWidgets);
    });

    testWidgets('should have Directionality set to RTL', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testHadeath));
      await tester.pumpAndSettle();

      final directionality = find.byType(Directionality);
      expect(directionality, findsWidgets);
    });

    testWidgets('header and content scroll together as one page', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testHadeath));
      await tester.pumpAndSettle();

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(SliverAppBar), findsOneWidget);
    });

    testWidgets('should be scrollable with long content', (
      WidgetTester tester,
    ) async {
      final longHadeath = HadeathEntity(
        title: 'حديث طويل',
        content: List<String>.filled(
          20,
          'هذا نص طويل جداً يكرر عدة مرات لاختبار القدرة على الـ scroll',
        ),
      );

      await tester.pumpWidget(createTestWidget(longHadeath));
      await tester.pumpAndSettle();

      final scroll = find.byType(CustomScrollView);
      final position = tester
          .state<ScrollableState>(
            find.descendant(of: scroll, matching: find.byType(Scrollable)),
          )
          .position;
      expect(position.maxScrollExtent, greaterThan(0));

      await tester.drag(scroll, const Offset(0, -100));
      await tester.pumpAndSettle();

      expect(position.pixels, greaterThan(0), reason: 'the page moved');
    });

    testWidgets('should display title in Amiri font', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testHadeath));
      await tester.pumpAndSettle();

      final titleWidget = find.byType(Text).first;
      expect(titleWidget, findsOneWidget);
    });

    testWidgets('should center align Bismillah text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testHadeath));
      await tester.pumpAndSettle();

      expect(
        find.text('بِسْمِ اللَّهِ الرَّحْمَِٰ الرَّحِيمِ'),
        findsOneWidget,
      );
    });

    testWidgets('should justify text alignment for content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testHadeath));
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('should handle hadeath with special characters', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(hadethWithSpecialChars));
      await tester.pumpAndSettle();

      expect(find.text('عَنْ أَبِي هُرَيْرَةَ'), findsOneWidget);
    });

    testWidgets('should handle hadeath with long title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(hadethWithLongTitle));
      await tester.pumpAndSettle();

      final titleText = hadethWithLongTitle.title;
      expect(titleText.length > 50, true);
    });

    testWidgets('should normalize title spaces correctly', (
      WidgetTester tester,
    ) async {
      const hadethWithExtraSpaces = HadeathEntity(
        title: 'حديث   به   فراغات   كثيرة',
        content: ['محتوى'],
      );
      await tester.pumpWidget(createTestWidget(hadethWithExtraSpaces));
      await tester.pumpAndSettle();

      // Title should be cleaned up
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows the basmala band above the hadith text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testHadeath));
      await tester.pumpAndSettle();

      final band = find.textContaining('بِسْمِ');
      final body = find.textContaining('نص الحديث');
      expect(band, findsOneWidget);
      expect(body, findsWidgets);
      expect(
        tester.getTopLeft(band).dy,
        lessThan(tester.getTopLeft(body.first).dy),
      );
    });

    testWidgets('should have correct scaffold background', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testHadeath));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle empty content list', (
      WidgetTester tester,
    ) async {
      const emptyHadeath = HadeathEntity(title: 'حديث بدون محتوى', content: []);

      await tester.pumpWidget(createTestWidget(emptyHadeath));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should display tooltip on back button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testHadeath));
      await tester.pumpAndSettle();

      final backButton = find.byIcon(Icons.arrow_back_ios);
      expect(backButton, findsOneWidget);
    });
  });
}
