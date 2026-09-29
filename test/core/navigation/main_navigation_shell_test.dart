import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina_app/core/navigation/main_navigation_shell.dart';
import 'package:sakina_app/core/theme/app_theme.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('routes render without a bottom navigation bar, dark=$dark', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        final router = GoRouter(
          initialLocation: '/home',
          routes: [
            ShellRoute(
              builder: (context, state, child) =>
                  MainNavigationShell(location: state.uri.path, child: child),
              routes: [
                for (final path in MainNavigationShell.paths)
                  GoRoute(
                    path: path,
                    builder: (_, _) => Scaffold(body: Text('Content $path')),
                  ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            builder: (context, child) =>
                Directionality(textDirection: TextDirection.rtl, child: child!),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.text('Content /home'), findsOneWidget);
        router.push('/quran');
        await tester.pumpAndSettle();
        expect(find.text('Content /quran'), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
        router.pop();
        await tester.pumpAndSettle();
        expect(find.text('Content /home'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    });
  }
}
