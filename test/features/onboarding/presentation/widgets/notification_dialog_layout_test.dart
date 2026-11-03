import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/onboarding/presentation/widgets/notification_permission_dialog.dart';
import 'package:sakina_app/features/settings/presentation/widgets/settings_controls.dart';
import 'package:sakina_app/l10n/app_localizations.dart';

Widget _app(Widget home, {double textScale = 1}) => MaterialApp(
  locale: const Locale('ar'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: home,
);

void main() {
  testWidgets('the dialog fits a small screen with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        Scaffold(body: NotificationPermissionDialog(onFinish: () {})),
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final decline = find.byType(TextButton);
    await tester.ensureVisible(decline);
    await tester.pumpAndSettle();
    expect(tester.getRect(decline).bottom, lessThanOrEqualTo(480));
  });

  for (final (granted, shown) in [
    (false, findsOneWidget),
    (true, findsNothing),
  ]) {
    testWidgets('permission granted=$granted feedback', (tester) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => requestNotificationPermissionWithFeedback(
                  context,
                  request: () async => granted,
                ),
                child: const Text('enable'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('enable'));
      await tester.pump();
      expect(find.byType(SnackBar), shown);
    });
  }
}
