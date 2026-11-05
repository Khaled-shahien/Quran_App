import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/features/quran/data/repositories/tasbih_repository_impl.dart';
import 'package:sakina_app/features/quran/presentation/providers/tasbih_controller.dart';
import 'package:sakina_app/features/quran/presentation/screens/tasbeeh_screen.dart';
import 'package:sakina_app/features/settings/presentation/providers/digit_style_controller.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Arabic-Indic digits built from code points, never typed.
final String arabic0123456789 = String.fromCharCodes(
  List.generate(10, (i) => 0x0660 + i),
);

void main() {
  test('western leaves text unchanged', () {
    expect(applyDigitStyle('12:05 م', DigitStyle.western), '12:05 م');
  });

  test('arabic converts every digit and nothing else', () {
    expect(applyDigitStyle('0123456789', DigitStyle.arabic), arabic0123456789);
    expect(
      applyDigitStyle('الصفحة 3', DigitStyle.arabic),
      'الصفحة ${arabic0123456789[3]}',
    );
  });

  test('style defaults to western and is remembered', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    expect(DigitStyleController(prefs).style, DigitStyle.western);
    await DigitStyleController(prefs).setStyle(DigitStyle.arabic);
    expect(DigitStyleController(prefs).style, DigitStyle.arabic);
  });

  testWidgets('tasbih count follows the chosen digits', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TasbihController(
          repository: SharedPreferencesTasbihRepository(prefs),
        ),
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DigitStyleScope(
            style: DigitStyle.arabic,
            child: TasbeehScreen(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    final zeroZero = '${arabic0123456789[0]}${arabic0123456789[0]}';
    expect(find.text(zeroZero), findsOneWidget);
    expect(find.text('00'), findsNothing);
  });
}
