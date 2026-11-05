import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/widgets/external_link_confirmation.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:sakina_app/l10n/localization.dart';

void main() {
  late List<Uri> launched;
  late Future<ExternalLinkOutcome> pending;

  Future<bool> fakeLauncher(Uri uri) async {
    launched.add(uri);
    return true;
  }

  Future<void> tapLink(WidgetTester tester, String url) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => pending = openExternalLinkWithConsent(
              context,
              url,
              launcher: fakeLauncher,
            ),
            child: const Text('link'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('link'));
    await tester.pumpAndSettle();
  }

  setUp(() => launched = <Uri>[]);

  testWidgets('shows the Arabic confirmation before leaving the app', (
    tester,
  ) async {
    await tapLink(tester, 'https://example.org/a');

    expect(
      find.text('سيتم فتح رابط خارج التطبيق، هل تريد المتابعة؟'),
      findsOneWidget,
    );
    expect(launched, isEmpty, reason: 'nothing opens before consent');
  });

  testWidgets('continue opens the link', (tester) async {
    await tapLink(tester, 'https://example.org/a');
    await tester.tap(find.text(appL10n.externalLinkContinue));
    await tester.pumpAndSettle();

    expect(await pending, ExternalLinkOutcome.opened);
    expect(launched.single.toString(), 'https://example.org/a');
  });

  testWidgets('cancel stays in the app', (tester) async {
    await tapLink(tester, 'https://example.org/a');
    await tester.tap(find.text(appL10n.appStringsMessage9));
    await tester.pumpAndSettle();

    expect(await pending, ExternalLinkOutcome.cancelled);
    expect(launched, isEmpty);
  });

  testWidgets('dismissing the dialog counts as cancel', (tester) async {
    await tapLink(tester, 'https://example.org/a');
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(await pending, ExternalLinkOutcome.cancelled);
    expect(launched, isEmpty);
  });

  testWidgets('unsafe schemes fail without asking or launching', (
    tester,
  ) async {
    await tapLink(tester, 'intent://evil#Intent;end');

    expect(find.byType(AlertDialog), findsNothing);
    expect(await pending, ExternalLinkOutcome.failed);
    expect(launched, isEmpty);
  });
}
