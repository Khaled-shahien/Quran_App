import 'dart:async';
import 'package:sakina_app/core/feedback/feedback_service.dart';
import 'package:sakina_app/features/settings/presentation/providers/digit_style_controller.dart';
import 'package:sakina_app/features/settings/presentation/providers/text_size_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina_app/core/providers/settings_provider.dart';
import 'package:sakina_app/core/theme/app_theme.dart';
import 'package:sakina_app/core/theme/theme_provider.dart';
import 'package:sakina_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:sakina_app/features/settings/presentation/widgets/reading_preferences.dart';
import 'package:sakina_app/features/onboarding/presentation/widgets/alarms/alarm_menu_item.dart';
import 'package:sakina_app/features/onboarding/presentation/widgets/alarms/alarm_time_picker_dialog.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_times_provider.dart';
import '../../providers/settings_provider_test.dart' as fakes;
import '../../../prayers/presentation/providers/prayer_times_provider_test.dart'
    as prayer;

class DelayedAlarmScheduler extends fakes.FakeAlarmScheduler {
  final completion = Completer<Map<String, int>>();
  @override
  Future<Map<String, int>> getAlarmTime(String type) => completion.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('dark captions meet AA on both background and card', () {
    final theme = AppTheme.darkTheme;
    final foreground = theme.textTheme.bodySmall!.color!.computeLuminance();
    for (final background in [
      theme.scaffoldBackgroundColor,
      theme.cardTheme.color!,
    ]) {
      expect(
        (foreground + .05) / (background.computeLuminance() + .05),
        greaterThanOrEqualTo(4.5),
      );
    }
    expect(theme.dialogTheme.backgroundColor, theme.colorScheme.surface);
    expect(theme.inputDecorationTheme.filled, isTrue);
    expect(theme.navigationBarTheme.indicatorColor, isNotNull);
  });

  testWidgets('reading preferences persist and restore', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ReadingPreferencesPanel(preferences: prefs)),
      ),
    );
    tester.widget<Slider>(find.byType(Slider).first).onChanged!(34);
    await tester.pump();
    expect(ReadingPreferences.fontSize(prefs), 34);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(prefs.getBool(ReadingPreferences.markersKey), isFalse);
  });

  testWidgets('alarm dialog waits for the stored time', (tester) async {
    final scheduler = DelayedAlarmScheduler();
    final settings = SettingsProvider(
      prefs: await SharedPreferences.getInstance(),
      alarmScheduler: scheduler,
      rescheduleTaskService: fakes.FakeRescheduleTaskService(),
    );
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: const MaterialApp(
          home: Scaffold(
            body: AlarmTimePickerDialog(alarmType: 'morning', title: 'الصباح'),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    scheduler.completion.complete({'hour': 8, 'minute': 15});
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  for (final dark in [false, true]) {
    testWidgets('settings fit small RTL screen with large text, dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => SettingsProvider(
                prefs: prefs,
                alarmScheduler: fakes.FakeAlarmScheduler(),
                rescheduleTaskService: fakes.FakeRescheduleTaskService(),
              ),
            ),
            ChangeNotifierProvider(create: (_) => ThemeProvider(prefs: prefs)),
            ChangeNotifierProvider(create: (_) => TextSizeController(prefs)),
            ChangeNotifierProvider(create: (_) => DigitStyleController(prefs)),
            ChangeNotifierProvider(
              create: (_) => FeedbackService(preferences: prefs),
            ),
            ChangeNotifierProvider(
              create: (_) => PrayerTimesProvider(
                repository: prayer.FakePrayerTimesRepository(),
              ),
            ),
          ],
          child: MaterialApp(
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(2)),
                child: SettingsScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  // Alarms live only in Settings now (no copy in the side menu).
  testWidgets('settings opens the saved time for each alarm', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => SettingsProvider(
              prefs: prefs,
              alarmScheduler: fakes.FakeAlarmScheduler(),
              rescheduleTaskService: fakes.FakeRescheduleTaskService(),
            ),
          ),
          ChangeNotifierProvider(create: (_) => ThemeProvider(prefs: prefs)),
          ChangeNotifierProvider(create: (_) => TextSizeController(prefs)),
          ChangeNotifierProvider(create: (_) => DigitStyleController(prefs)),
          ChangeNotifierProvider(
            create: (_) => FeedbackService(preferences: prefs),
          ),
          ChangeNotifierProvider(
            create: (_) => PrayerTimesProvider(
              repository: prayer.FakePrayerTimesRepository(),
            ),
          ),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    for (final type in ['morning', 'evening', 'mulk', 'baqarah']) {
      final item = find.byWidgetPredicate(
        (w) => w is AlarmMenuItem && w.alarmType == type,
      );
      await tester.scrollUntilVisible(
        item,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(item);
      await tester.pumpAndSettle();
      final dialog = find.byType(AlarmTimePickerDialog);
      expect(tester.widget<AlarmTimePickerDialog>(dialog).alarmType, type);
      Navigator.of(tester.element(dialog)).pop();
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
