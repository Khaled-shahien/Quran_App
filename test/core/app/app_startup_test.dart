import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina_app/core/app/app_startup.dart';
import 'package:sakina_app/core/app/startup_failure_app.dart';
import 'package:sakina_app/core/di/service_locator.dart';

void main() {
  const healthyApp = Text('app', textDirection: TextDirection.ltr);

  test('successful startup runs the app', () async {
    final shown = <Widget>[];
    await startApp(
      initialize: () async {},
      run: shown.add,
      buildApp: () => healthyApp,
    );
    expect(shown, [healthyApp]);
  });

  testWidgets('failed startup shows recovery UI and retry can succeed', (
    tester,
  ) async {
    var attempts = 0;
    late Widget shown;
    await startApp(
      initialize: () async {
        if (++attempts == 1) throw StateError('prefs unavailable');
      },
      run: (app) => shown = app,
      buildApp: () => healthyApp,
    );
    await tester.pumpWidget(shown);
    await tester.pumpAndSettle();
    expect(find.byType(StartupFailureApp), findsOneWidget);
    expect(find.text('تعذر تشغيل التطبيق'), findsOneWidget);
    expect(find.textContaining('prefs unavailable'), findsNothing);

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pump();
    expect(attempts, 2);
    await tester.pumpWidget(shown);
    await tester.pumpAndSettle();
    expect(find.text('app'), findsOneWidget);
  });

  testWidgets('repeated taps start one retry at a time', (tester) async {
    final retry = Completer<void>();
    var retries = 0;
    await tester.pumpWidget(
      StartupFailureApp(
        onRetry: () {
          retries++;
          return retry.future;
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(retries, 1);
    retry.complete();
    await tester.pumpAndSettle();
  });

  test('service locator setup can run again after a failed attempt', () async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(getIt.reset);
    await setupServiceLocator();
    await expectLater(setupServiceLocator(), completes);
  });
}
