import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina_app/core/providers/settings_provider.dart';
import 'package:sakina_app/core/theme/app_theme.dart';
import 'package:sakina_app/core/theme/theme_provider.dart';
import 'package:sakina_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_times_provider.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import '../../providers/settings_provider_test.dart' as settings_fakes;
import '../../../prayers/presentation/providers/prayer_times_provider_test.dart'
    as prayer_fakes;

// Raster baselines are owned by the Windows CI job to avoid cross-host font
// rasterizer differences. Behavioral/theme/RTL tests run on every host.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Cairo')
      ..addFont(rootBundle.load('fonts/Cairo.ttf'));
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  for (final dark in [false, true]) {
    testWidgets('settings visual baseline ${dark ? 'dark' : 'light'}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(420, 920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'theme_mode': dark ? 'dark' : 'light',
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => SettingsProvider(
                prefs: prefs,
                alarmScheduler: settings_fakes.FakeAlarmScheduler(),
                rescheduleTaskService:
                    settings_fakes.FakeRescheduleTaskService(),
              ),
            ),
            ChangeNotifierProvider(create: (_) => ThemeProvider(prefs: prefs)),
            ChangeNotifierProvider(
              create: (_) => PrayerTimesProvider(
                repository: prayer_fakes.FakePrayerTimesRepository(),
              ),
            ),
          ],
          child: MaterialApp(
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const RepaintBoundary(
              key: Key('settings-golden'),
              child: SettingsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const Key('settings-golden')),
        matchesGoldenFile(
          'goldens/windows/settings_${dark ? 'dark' : 'light'}.png',
        ),
      );
    }, skip: !Platform.isWindows);
  }
}
