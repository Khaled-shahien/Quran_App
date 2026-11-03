import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina_app/core/navigation/app_router.dart';
import 'package:sakina_app/core/navigation/notification_handler.dart';

Widget _page(String name) => Builder(
  builder: (context) => Scaffold(
    body: Column(
      children: [
        Text(name),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('back'),
        ),
      ],
    ),
  ),
);

void main() {
  Future<GoRouter> pumpRouter(WidgetTester tester) async {
    final router = GoRouter(
      navigatorKey: appNavigatorKey,
      initialLocation: '/splash',
      routes: [
        for (final path in [
          '/splash',
          '/home',
          '/duas/morning',
          '/quran/surah/:number',
          '/prayers',
          '/khatma',
        ])
          GoRoute(path: path, builder: (_, state) => _page(state.uri.path)),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  for (final (route, data, expected)
      in <(String, Map<String, dynamic>?, String)>[
        ('/duas', {'type': 'morning'}, '/duas/morning'),
        ('/quran', {'surahNumber': 67}, '/quran/surah/67'),
        ('/prayers', null, '/prayers'),
        ('/khatma', null, '/khatma'),
      ]) {
    testWidgets('a tap on $expected can go back to home', (tester) async {
      await pumpRouter(tester);

      handleNotificationNavigation(route, data);
      await tester.pumpAndSettle();
      expect(find.text(expected), findsOneWidget);

      await tester.tap(find.text('back'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('/home'), findsOneWidget);
    });
  }

  testWidgets('invalid and general payloads open home only', (tester) async {
    final router = await pumpRouter(tester);

    handleNotificationNavigation('/unknown', null);
    await tester.pumpAndSettle();

    expect(find.text('/home'), findsOneWidget);
    expect(router.canPop(), isFalse);
  });
}
