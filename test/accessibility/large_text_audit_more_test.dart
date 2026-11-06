import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/providers/settings_provider.dart';
import 'package:sakina_app/core/theme/app_design.dart';
import 'package:sakina_app/core/theme/app_theme.dart';
import 'package:sakina_app/core/theme/theme_provider.dart';
import 'package:sakina_app/features/duas/presentation/providers/azkar_provider.dart';
import 'package:sakina_app/features/duas/presentation/providers/duas_provider.dart';
import 'package:sakina_app/features/hadeath/presentation/providers/hadeath_provider.dart';
import 'package:sakina_app/features/islamic_guide/data/islamic_guide_repository_impl.dart';
import 'package:sakina_app/features/islamic_guide/presentation/providers/islamic_guide_provider.dart';
import 'package:sakina_app/features/islamic_guide/presentation/screens/islamic_guide_screen.dart';
import 'package:sakina_app/features/khatma/data/repositories/khatma_repository.dart';
import 'package:sakina_app/features/khatma/presentation/providers/khatma_provider.dart';
import 'package:sakina_app/features/khatma/presentation/screens/khatma_location_screen.dart';
import 'package:sakina_app/features/onboarding/presentation/providers/favorites_provider.dart';
import 'package:sakina_app/features/onboarding/presentation/screens/home_screen.dart';
import 'package:sakina_app/features/onboarding/presentation/screens/media_screen.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_times_provider.dart';
import 'package:sakina_app/features/qibla/presentation/qibla_controller.dart';
import 'package:sakina_app/features/qibla/presentation/screens/qibla_screen.dart';
import 'package:sakina_app/features/quran/data/data_sources/local_quran_data_source.dart';
import 'package:sakina_app/features/quran/data/data_sources/local_surah_data_source.dart';
import 'package:sakina_app/features/quran/data/repositories/ayah_repository.dart';
import 'package:sakina_app/features/quran/data/repositories/surah_repository.dart';
import 'package:sakina_app/features/quran/domain/entities/surah_entity.dart';
import 'package:sakina_app/features/quran/domain/repositories/surah_repository.dart';
import 'package:sakina_app/features/quran/presentation/providers/bookmark_provider.dart';
import 'package:sakina_app/features/quran/presentation/screens/quran_screen.dart';
import 'package:sakina_app/features/quran/presentation/screens/quran_search_screen.dart';
import 'package:sakina_app/features/quran/presentation/screens/surah_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/onboarding/presentation/screens/home_screen_test.dart'
    as home;
import '../features/qibla/qibla_test.dart' as qibla;
import 'large_text_audit_test.dart';

class _KhatmaStub extends Mock implements KhatmaProvider {}

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  final looks = <(String, ThemeData)>[
    for (final design in AppDesign.values) ...[
      ('${design.name} light', AppTheme.light(design)),
      if (!design.alwaysDark) ('${design.name} dark', AppTheme.dark(design)),
    ],
  ];

  for (final look in looks) {
    testWidgets('home (${look.$1})', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpAudited(
        tester,
        const HomeScreen(),
        theme: look.$2,
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider(prefs: prefs)),
          ChangeNotifierProvider(
            create: (_) => FavoritesProvider(prefs: prefs),
          ),
          ChangeNotifierProvider(create: (_) => BookmarkProvider(prefs: prefs)),
          ChangeNotifierProvider(
            create: (_) => SettingsProvider(
              prefs: prefs,
              alarmScheduler: home.FakeAlarmScheduler(),
              rescheduleTaskService: home.FakeRescheduleTaskService(),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => PrayerTimesProvider(
              repository: home.FakePrayerTimesRepository(),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) =>
                KhatmaProvider(repository: KhatmaRepositoryImpl(prefs: prefs)),
          ),
          ChangeNotifierProvider(
            create: (_) =>
                AzkarProvider(repository: home.FakeAzkarRepository()),
          ),
          ChangeNotifierProvider(
            create: (_) => DuasProvider(repository: home.FakeDuasRepository()),
          ),
          ChangeNotifierProvider(
            create: (_) =>
                HadeathProvider(repository: home.FakeHadeathRepository()),
          ),
          Provider<SurahRepository>(create: (_) => home.FakeSurahRepository()),
        ],
      );
      await expectAccessible(tester);
      semantics.dispose();
    });

    testWidgets('surah list (${look.$1})', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpAudited(
        tester,
        const QuranScreen(),
        theme: look.$2,
        providers: [
          Provider<SurahRepository>(create: (_) => home.FakeSurahRepository()),
          ChangeNotifierProvider(create: (_) => BookmarkProvider(prefs: prefs)),
        ],
      );
      await expectAccessible(tester);
      semantics.dispose();
    });

    testWidgets('quran reader (${look.$1})', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.runAsync(() async {
        await pumpAudited(
          tester,
          SurahDetailsScreen(
            surah: SurahEntity(
              number: 1,
              name: 'الفاتحة',
              englishName: 'Al-Fatiha',
              englishNameTranslation: 'The Opening',
              revelationType: 'Meccan',
              totalAyah: 7,
            ),
            surahNumber: 1,
          ),
          theme: look.$2,
          providers: [
            Provider<SharedPreferences>.value(value: prefs),
            ChangeNotifierProvider(
              create: (_) => BookmarkProvider(prefs: prefs),
            ),
          ],
        );
        await rootBundle.loadString('assets/quran_master.json');
      });
      await tester.pump(const Duration(milliseconds: 300));
      await expectAccessible(tester);
      semantics.dispose();
    });

    testWidgets('quran search (${look.$1})', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpAudited(
        tester,
        QuranSearchScreen(
          repository: AyahRepositoryImpl(
            localDataSource: LocalQuranDataSource(),
            sharedPreferences: prefs,
          ),
        ),
        theme: look.$2,
        providers: [
          Provider<SurahRepository>(create: (_) => home.FakeSurahRepository()),
        ],
      );
      await expectAccessible(tester);
      semantics.dispose();
    });

    testWidgets('khatma start (${look.$1})', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpAudited(
        tester,
        const KhatmaLocationScreen(),
        theme: look.$2,
        providers: [
          ChangeNotifierProvider<KhatmaProvider>.value(value: _KhatmaStub()),
        ],
      );
      await expectAccessible(tester);
      semantics.dispose();
    });

    testWidgets('qibla (${look.$1})', (tester) async {
      final semantics = tester.ensureSemantics();
      final device = qibla.FakeQiblaDevice();
      final controller = QiblaController(device: device);
      addTearDown(() async {
        controller.dispose();
        await device.close();
      });
      await pumpAudited(
        tester,
        QiblaScreen(controller: controller),
        theme: look.$2,
        providers: [Provider<SharedPreferences>.value(value: prefs)],
      );
      await expectAccessible(tester);
      semantics.dispose();
    });

    testWidgets('islamic guide (${look.$1})', (tester) async {
      final semantics = tester.ensureSemantics();
      final provider = IslamicGuideProvider(
        repository: IslamicGuideRepositoryImpl(
          ayahRepository: AyahRepositoryImpl(
            localDataSource: LocalQuranDataSource(),
            sharedPreferences: prefs,
          ),
          surahRepository: SurahRepositoryImpl(
            localDataSource: LocalSurahDataSource(),
            sharedPreferences: prefs,
          ),
        ),
      );
      await tester.runAsync(provider.load);
      await pumpAudited(
        tester,
        const IslamicGuideScreen(),
        theme: look.$2,
        providers: [ChangeNotifierProvider.value(value: provider)],
      );
      await expectAccessible(tester);
      semantics.dispose();
    });

    testWidgets('library (${look.$1})', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpAudited(
        tester,
        const MediaScreen(),
        theme: look.$2,
        providers: [Provider<SharedPreferences>.value(value: prefs)],
      );
      await expectAccessible(tester);
      semantics.dispose();
    });
  }
}
