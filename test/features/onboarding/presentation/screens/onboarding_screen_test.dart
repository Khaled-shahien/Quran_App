import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina_app/core/theme/app_colors.dart';
import 'package:sakina_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:sakina_app/features/onboarding/presentation/widgets/notification_permission_dialog.dart';
import 'package:sakina_app/features/onboarding/presentation/widgets/onboarding_page.dart';

void main() {
  setUp(() {
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
        GoRoute(
          path: '/onboarding/permissions',
          builder: (_, _) => const Scaffold(body: Text('Permission steps')),
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
            seedColor: AppColors.lightPrimary,
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

  testWidgets(
    'All four pages lead to the permission steps from the final start button',
    (tester) async {
      await pumpOnboarding(tester);
      for (var index = 0; index < 3; index++) {
        await tester.tap(find.text('التالي'));
        await tester.pumpAndSettle();
      }
      expect(find.text('تخطي').hitTestable(), findsNothing);
      expect(find.bySemanticsLabel('الصفحة 4 من 4'), findsOneWidget);
      expect(
        find.text(onboardingPages.last.title).hitTestable(),
        findsOneWidget,
      );
      // The last page says, gently, that two optional permissions follow and
      // that neither is asked for before it is explained.
      expect(
        find.byKey(const Key('onboarding-permission-notes')),
        findsOneWidget,
      );
      expect(
        find.text(
          'بعد هذه الصفحة نعرض عليك إذنين اختياريين، ولا نطلب أيًّا منهما قبل أن نشرح فائدته.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('ابدأ الآن'));
      await tester.pumpAndSettle();
      expect(find.text('Permission steps'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), isTrue);
      expect(prefs.getBool('permission_intro_pending'), isTrue);
    },
  );

  testWidgets('Skip leads to the permission steps without any dialog', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();
    expect(find.text('Permission steps'), findsOneWidget);
    expect(find.byType(NotificationPermissionDialog), findsNothing);
  });

  testWidgets('Skip finishes once without requesting notification permission', (
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
    expect(find.byType(NotificationPermissionDialog), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('Permission steps'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_complete'), isTrue);
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
