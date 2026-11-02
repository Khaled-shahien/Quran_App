import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina_app/core/providers/notification_provider.dart';
import 'package:sakina_app/features/onboarding/presentation/widgets/notification_permission_dialog.dart';
import 'package:sakina_app/l10n/app_localizations.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpAndPrompt(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => NotificationProvider(prefs: prefs),
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => promptForNotificationPermissionOnce(context),
              child: const Text('prompt'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('prompt'));
    await tester.pumpAndSettle();
  }

  testWidgets('explains reminders once, then remembers the answer', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await pumpAndPrompt(tester);
    expect(find.byType(NotificationPermissionDialog), findsOneWidget);

    // The decline button records the answer without any OS permission request.
    final buttons = find.descendant(
      of: find.byType(NotificationPermissionDialog),
      matching: find.byType(TextButton),
    );
    await tester.tap(buttons.last);
    await tester.pumpAndSettle();
    expect(find.byType(NotificationPermissionDialog), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('has_seen_notification_permission'), isTrue);

    await tester.tap(find.text('prompt'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationPermissionDialog), findsNothing);
  });

  testWidgets('stays quiet when prayer reminders are turned off', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'prayer_notifications_enabled': false,
    });
    await pumpAndPrompt(tester);
    expect(find.byType(NotificationPermissionDialog), findsNothing);
  });
}
