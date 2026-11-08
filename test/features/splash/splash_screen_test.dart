import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina_app/core/navigation/notification_router.dart';
import 'package:sakina_app/features/splash/presentation/screens/splash_screen.dart';

void main() {
  tearDown(NotificationRouter.clearNavigationCallback);

  Future<void> pumpSplash(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
        GoRoute(path: '/home', builder: (_, _) => const Text('home')),
        GoRoute(path: '/onboarding', builder: (_, _) => const Text('intro')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  testWidgets('leaves the splash in well under a second', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
        GoRoute(path: '/home', builder: (_, _) => const Text('home')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump(SplashScreen.minimumDisplay);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('a new install goes to onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpSplash(tester);
    expect(find.text('intro'), findsOneWidget);
  });

  testWidgets('completed onboarding goes home on the next launch', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    await pumpSplash(tester);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('an older install with only the prompt flag goes home', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'has_seen_notification_permission': true,
    });
    await pumpSplash(tester);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('a held launch tap is delivered after routing home', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final routes = <String>[];
    NotificationRouter.hold();
    NotificationRouter.setNavigationCallback((route, _) => routes.add(route));
    NotificationRouter.handleNotification(type: 'prayer_time');
    await pumpSplash(tester);
    expect(routes, ['/prayers']);
  });

  testWidgets('a held launch tap does not interrupt first-run onboarding', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final routes = <String>[];
    NotificationRouter.hold();
    NotificationRouter.setNavigationCallback((route, _) => routes.add(route));
    NotificationRouter.handleNotification(type: 'prayer_time');
    await pumpSplash(tester);
    expect(routes, isEmpty);
    expect(find.text('intro'), findsOneWidget);
  });
}
