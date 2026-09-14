import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina_app/core/theme/theme_provider.dart';
import 'package:sakina_app/features/quran/presentation/widgets/quran_settings_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ThemeProvider> buildThemeProvider({bool dark = false}) async {
    SharedPreferences.setMockInitialValues(
      dark ? <String, Object>{'theme_mode': 'dark'} : <String, Object>{},
    );
    final prefs = await SharedPreferences.getInstance();
    return ThemeProvider(prefs: prefs);
  }

  Widget buildApp({required ThemeProvider provider}) {
    return ChangeNotifierProvider<ThemeProvider>.value(
      value: provider,
      child: const MaterialApp(home: Scaffold(body: QuranSettingsDialog())),
    );
  }

  testWidgets('renders title, close action and theme switch', (tester) async {
    final provider = await buildThemeProvider();

    await tester.pumpWidget(buildApp(provider: provider));
    await tester.pumpAndSettle();

    expect(find.text('إعدادات القراءة'), findsOneWidget);
    expect(find.text('الوضع الليلي'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('switch toggles dark mode and persists provider state', (
    tester,
  ) async {
    final provider = await buildThemeProvider(dark: false);

    await tester.pumpWidget(buildApp(provider: provider));
    await tester.pumpAndSettle();

    expect(provider.isDarkMode, isFalse);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(provider.isDarkMode, isTrue);
  });

  testWidgets('close button dismisses dialog using navigator pop', (
    tester,
  ) async {
    final provider = await buildThemeProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (_) => const QuranSettingsDialog(),
                      );
                    },
                    child: const Text('open'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('إعدادات القراءة'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('إعدادات القراءة'), findsNothing);
  });
}
