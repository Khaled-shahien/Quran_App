import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina_app/core/navigation/app_router.dart';
import 'package:sakina_app/l10n/app_localizations.dart';

/// Unknown locations show an Arabic page with a way home (audit ARCH-05).
void main() {
  testWidgets('an unknown location offers the way back home', (tester) async {
    final router = GoRouter(
      initialLocation: '/does-not-exist',
      errorBuilder: (_, _) => const RouteNotFoundScreen(),
      routes: [GoRoute(path: '/home', builder: (_, _) => const Text('home'))],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تعذر فتح هذه الصفحة.'), findsOneWidget);
    await tester.tap(find.text('العودة إلى الرئيسية'));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });
}
