import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/features/onboarding/presentation/widgets/simple_home.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_times_provider.dart';
import 'package:sakina_app/features/settings/presentation/providers/simple_mode_controller.dart';
import 'package:sakina_app/features/settings/presentation/providers/text_size_controller.dart';
import 'package:sakina_app/features/settings/presentation/widgets/settings_controls.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('ar'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  test('travel distance is the great-circle distance', () {
    // Cairo to Alexandria is about 180 km.
    final km = travelDistanceKm(30.0444, 31.2357, 31.2001, 29.9187);
    expect(km, inInclusiveRange(170, 190));
    expect(travelDistanceKm(30, 31, 30, 31), 0);
    expect(PrayerTimesProvider.travelThresholdKm, 50);
  });

  testWidgets('simple mode turns on larger text the first time', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final simple = SimpleModeController(prefs);
    final text = TextSizeController(prefs);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SimpleModeController>.value(value: simple),
          ChangeNotifierProvider<TextSizeController>.value(value: text),
        ],
        child: _app(const SimpleModePreference()),
      ),
    );
    await tester.tap(find.byKey(const Key('simple-mode')));
    await tester.pumpAndSettle();
    expect(simple.enabled, isTrue);
    expect(prefs.getBool(SimpleModeController.key), isTrue);
    expect(text.size, AppTextSize.large);

    // Turning it off keeps the text size the user now has.
    await tester.tap(find.byKey(const Key('simple-mode')));
    await tester.pumpAndSettle();
    expect(simple.enabled, isFalse);
    expect(text.size, AppTextSize.large);
  });

  testWidgets('the simple home has four large tiles', (tester) async {
    await tester.pumpWidget(_app(const SimpleHomeTiles()));
    for (final label in ['القرآن', 'مواقيت الصلاة', 'الأذكار', 'القبلة']) {
      expect(find.text(label), findsOneWidget);
      final size = tester.getSize(
        find.ancestor(of: find.text(label), matching: find.byType(InkWell)),
      );
      expect(size.height, greaterThanOrEqualTo(140));
    }
  });
}
