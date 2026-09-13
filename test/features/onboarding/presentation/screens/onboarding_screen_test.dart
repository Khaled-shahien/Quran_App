import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quran_app/core/theme/app_colors.dart';
import 'package:quran_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:quran_app/features/onboarding/presentation/widgets/notification_permission_dialog.dart';
import 'package:quran_app/features/onboarding/presentation/widgets/onboarding_page.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({
      'has_seen_notification_permission': true,
    });
  });

  Future<void> pumpOnboarding(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
    Brightness brightness = Brightness.light,
    bool disableAnimations = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const OnboardingScreen()),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Home destination')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: ThemeData(
          brightness: brightness,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: brightness,
          ),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: child!,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Next, previous and RTL swipes keep page progress in sync', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    expect(find.byTooltip('السابق'), findsNothing);
    expect(find.bySemanticsLabel('الصفحة 1 من 4'), findsOneWidget);

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('الصفحة 2 من 4'), findsOneWidget);
    expect(find.text(onboardingPages[1].title).hitTestable(), findsOneWidget);

    await tester.tap(find.byTooltip('السابق'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('الصفحة 1 من 4'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(320, 0));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('الصفحة 2 من 4'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('الصفحة 1 من 4'), findsOneWidget);
  });

  testWidgets('All four pages lead to home from the final start button', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    for (var index = 0; index < 3; index++) {
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
    }
    expect(find.text('تخطي').hitTestable(), findsNothing);
    expect(find.bySemanticsLabel('الصفحة 4 من 4'), findsOneWidget);
    expect(find.text(onboardingPages.last.title).hitTestable(), findsOneWidget);
    await tester.tap(find.text('ابدأ الآن'));
    await tester.pumpAndSettle();
    expect(find.text('Home destination'), findsOneWidget);
  });

  testWidgets('Skip enters home when notification prompt was already seen', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();
    expect(find.text('Home destination'), findsOneWidget);
    expect(find.byType(NotificationPermissionDialog), findsNothing);
  });

  testWidgets('Skip shows one notification prompt and allows declining', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await pumpOnboarding(tester);
    final skip = tester
        .widget<TextButton>(find.widgetWithText(TextButton, 'تخطي'))
        .onPressed!;
    skip();
    skip();
    await tester.pumpAndSettle();
    expect(find.byType(NotificationPermissionDialog), findsOneWidget);
    await tester.tap(find.text('ليس الآن'));
    await tester.pumpAndSettle();
    expect(find.text('Home destination'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('has_seen_notification_permission'), isTrue);
  });

  testWidgets('Reduced motion still allows page navigation', (tester) async {
    await pumpOnboarding(tester, disableAnimations: true);
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('الصفحة 2 من 4'), findsOneWidget);
  });

  for (final size in [
    const Size(320, 568),
    const Size(844, 390),
    const Size(1024, 768),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets('All pages fit $size, $brightness and large text', (
        tester,
      ) async {
        await pumpOnboarding(
          tester,
          size: size,
          textScale: 2,
          brightness: brightness,
        );
        for (var index = 0; index < onboardingPages.length; index++) {
          expect(tester.takeException(), isNull);
          final action = find.text(index == 3 ? 'ابدأ الآن' : 'التالي');
          expect(action.hitTestable(), findsOneWidget);
          if (index < 3) {
            await tester.tap(action);
            await tester.pumpAndSettle();
          }
        }
      });
    }
  }
}
