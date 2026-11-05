import 'package:flutter/material.dart';
import 'package:sakina_app/features/settings/presentation/providers/digit_style_controller.dart';
import 'package:sakina_app/features/settings/presentation/providers/text_size_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sakina_app/features/khatma/presentation/providers/khatma_provider.dart';
import 'package:sakina_app/features/khatma/presentation/screens/khatma_duration_screen.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/features/duas/data/repositories/azkar_repository.dart';
import 'package:sakina_app/core/theme/app_theme.dart';
import 'package:sakina_app/features/duas/data/models/azkar_model.dart';
import 'package:sakina_app/features/duas/presentation/providers/azkar_provider.dart';
import 'package:sakina_app/features/duas/presentation/screens/azkar_details_screen.dart';
import 'package:sakina_app/features/quran/data/repositories/tasbih_repository_impl.dart';
import 'package:sakina_app/features/quran/presentation/providers/tasbih_controller.dart';
import 'package:sakina_app/features/quran/presentation/screens/tasbeeh_screen.dart';
import 'package:sakina_app/features/recitation/presentation/providers/recitation_controller.dart';
import 'package:sakina_app/features/recitation/presentation/providers/recitation_downloads_controller.dart';
import 'package:sakina_app/features/recitation/presentation/screens/recitation_screen.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina_app/core/providers/settings_provider.dart';
import 'package:sakina_app/core/theme/theme_provider.dart';
import 'package:sakina_app/features/duas/data/repositories/adhan_adhkar_repository.dart';
import 'package:sakina_app/features/duas/presentation/screens/after_adhan_screen.dart';
import 'package:sakina_app/features/hadeath/domain/entities/hadeath_entity.dart';
import 'package:sakina_app/features/hadeath/domain/repositories/hadeath_repository.dart';
import 'package:sakina_app/features/hadeath/presentation/providers/hadeath_provider.dart';
import 'package:sakina_app/features/hadeath/presentation/screens/hadeath_screen.dart';
import 'package:sakina_app/features/prayers/data/repositories/adhan_settings_store.dart';
import 'package:sakina_app/features/prayers/presentation/providers/adhan_settings_controller.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_times_provider.dart';
import 'package:sakina_app/features/prayers/presentation/screens/prayer_times_screen.dart';
import 'package:sakina_app/features/quran/presentation/screens/asma_al_husna_screen.dart';
import 'package:sakina_app/features/recitation/presentation/screens/recitation_downloads_screen.dart';
import 'package:sakina_app/features/settings/presentation/providers/reading_mode_controller.dart';
import 'package:sakina_app/features/settings/presentation/screens/settings_screen.dart';

import '../features/settings/providers/settings_provider_test.dart'
    as settings_fakes;
import '../features/prayers/presentation/providers/prayer_times_provider_test.dart'
    as prayer_fakes;
import '../features/duas/presentation/adhkar_progress_test.dart' as adhkar;
import '../features/recitation/fakes.dart';

/// Every main screen must stay usable for seniors: 200% system text on a
/// small phone without overflow, 48dp tap targets and labelled buttons.
Future<void> pumpAudited(
  WidgetTester tester,
  Widget home, {
  required List<SingleChildWidget> providers,
  bool dark = false,
}) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    MultiProvider(
      providers: providers,
      child: MaterialApp(
        theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> expectAccessible(WidgetTester tester) async {
  expect(tester.takeException(), isNull, reason: 'no overflow at 200% text');
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
}

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  for (final dark in [false, true]) {
    testWidgets('tasbih (dark=$dark)', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpAudited(
        tester,
        const TasbeehScreen(),
        dark: dark,
        providers: [
          ChangeNotifierProvider(
            create: (_) => TasbihController(
              repository: SharedPreferencesTasbihRepository(prefs),
            ),
          ),
        ],
      );
      await expectAccessible(tester);
      semantics.dispose();
    });

    testWidgets('adhkar (dark=$dark)', (tester) async {
      final semantics = tester.ensureSemantics();
      final azkar = AzkarProvider(repository: _AdhkarRepo());
      await azkar.loadAzkar();
      await pumpAudited(
        tester,
        const AzkarDetailsScreen(categoryName: 'أذكار الصباح'),
        dark: dark,
        providers: [
          Provider<SharedPreferences>.value(value: prefs),
          ChangeNotifierProvider.value(value: azkar),
        ],
      );
      await expectAccessible(tester);
      semantics.dispose();
    });

    testWidgets('recitation (dark=$dark)', (tester) async {
      final semantics = tester.ensureSemantics();
      final repository = FakeRepository();
      final controller = RecitationController(
        repository: repository,
        engine: FakeEngine(),
        preferences: prefs,
        surahName: (s) => 'سورة $s',
      );
      await controller.initialize();
      await pumpAudited(
        tester,
        const RecitationScreen(),
        dark: dark,
        providers: [
          ChangeNotifierProvider.value(value: controller),
          ChangeNotifierProvider(
            create: (_) =>
                RecitationDownloadsController(repository: repository),
          ),
        ],
      );
      await expectAccessible(tester);
      semantics.dispose();
    });
    testWidgets('settings (dark=$dark)', (tester) async {
      final semantics = tester.ensureSemantics();
      final prayer = PrayerTimesProvider(
        repository: prayer_fakes.FakePrayerTimesRepository(),
        preferences: prefs,
      );
      await prayer.selectLocation(30.04, 31.23, 'القاهرة', 5);
      await pumpAudited(
        tester,
        const SettingsScreen(),
        dark: dark,
        providers: [
          Provider<SharedPreferences>.value(value: prefs),
          ChangeNotifierProvider(
            create: (_) => SettingsProvider(
              prefs: prefs,
              alarmScheduler: settings_fakes.FakeAlarmScheduler(),
              rescheduleTaskService: settings_fakes.FakeRescheduleTaskService(),
            ),
          ),
          ChangeNotifierProvider(create: (_) => ThemeProvider(prefs: prefs)),
          ChangeNotifierProvider(create: (_) => TextSizeController(prefs)),
          ChangeNotifierProvider(create: (_) => DigitStyleController(prefs)),
          ChangeNotifierProvider.value(value: prayer),
          ChangeNotifierProvider(create: (_) => ReadingModeController(prefs)),
          ChangeNotifierProvider(
            create: (_) => AdhanSettingsController(
              store: AdhanSettingsStore(prefs),
              platform: AdhanPlatform(
                reschedule: () async {},
                canScheduleExact: () async => false,
                requestExact: () async => true,
                scheduleTest: (_) async {},
              ),
            ),
          ),
        ],
      );
      await expectAccessible(tester);
      semantics.dispose();
    });

    testWidgets('prayer times (dark=$dark)', (tester) async {
      final semantics = tester.ensureSemantics();
      final prayer = PrayerTimesProvider(
        repository: prayer_fakes.FakePrayerTimesRepository(),
        preferences: prefs,
      );
      await prayer.selectLocation(30.04, 31.23, 'القاهرة', 5);
      await pumpAudited(
        tester,
        const PrayerTimesScreen(),
        dark: dark,
        providers: [ChangeNotifierProvider.value(value: prayer)],
      );
      await expectAccessible(tester);
      semantics.dispose();
    });

    testWidgets('adhan adhkar (dark=$dark)', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpAudited(
        tester,
        AfterAdhanScreen(
          repository: AdhanAdhkarRepositoryImpl(),
          prayerName: 'المغرب',
        ),
        dark: dark,
        providers: [Provider<SharedPreferences>.value(value: prefs)],
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
      await expectAccessible(tester);
      semantics.dispose();
    });

    testWidgets('downloads (dark=$dark)', (tester) async {
      final semantics = tester.ensureSemantics();
      final repository = FakeRepository();
      final controller = RecitationController(
        repository: repository,
        engine: FakeEngine(),
        preferences: prefs,
        surahName: (s) => 'سورة ',
      );
      await pumpAudited(
        tester,
        const RecitationDownloadsScreen(),
        dark: dark,
        providers: [
          ChangeNotifierProvider.value(value: controller),
          ChangeNotifierProvider(
            create: (_) =>
                RecitationDownloadsController(repository: repository),
          ),
        ],
      );
      await expectAccessible(tester);
      semantics.dispose();
    });

    testWidgets('hadith list (dark=$dark)', (tester) async {
      final semantics = tester.ensureSemantics();
      final hadith = HadeathProvider(repository: _HadithRepo());
      await hadith.loadAhadeth();
      await pumpAudited(
        tester,
        const HadeathScreen(),
        dark: dark,
        providers: [ChangeNotifierProvider.value(value: hadith)],
      );
      await expectAccessible(tester);
      semantics.dispose();
    });

    testWidgets('asma al-husna (dark=$dark)', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpAudited(
        tester,
        const AsmaAlHusnaScreen(),
        dark: dark,
        providers: [Provider<SharedPreferences>.value(value: prefs)],
      );
      await expectAccessible(tester);
      semantics.dispose();
    });
    testWidgets('khatma duration (dark=$dark)', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpAudited(
        tester,
        const KhatmaDurationScreen(startMode: 'juz', startJuz: 1),
        dark: dark,
        providers: [
          ChangeNotifierProvider<KhatmaProvider>.value(value: _KhatmaStub()),
        ],
      );
      await expectAccessible(tester);
      semantics.dispose();
    });
  }
}

class _KhatmaStub extends Mock implements KhatmaProvider {}

class _HadithRepo implements HadeathRepository {
  @override
  Future<Result<List<HadeathEntity>>> getAllAhadeth() async => const Success([
    HadeathEntity(title: 'الحديث الأول', content: ['نص الحديث']),
  ]);
}

class _AdhkarRepo implements AzkarRepository {
  @override
  Future<Result<List<AzkarCategoryModel>>> getAllAzkar() async => Success([
    AzkarCategoryModel(id: 1, category: 'أذكار الصباح', items: adhkar.items),
  ]);
}
