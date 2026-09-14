import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/di/service_locator.dart';
import 'package:sakina_app/core/theme/app_theme.dart';
import 'package:sakina_app/core/theme/noise_background.dart';
import 'package:sakina_app/core/theme/theme_provider.dart';
import 'package:sakina_app/core/navigation/app_router.dart';
import 'package:sakina_app/core/navigation/notification_handler.dart';
import 'package:sakina_app/core/navigation/notification_router.dart';
import 'package:sakina_app/core/providers/notification_provider.dart';
import 'package:sakina_app/core/providers/settings_provider.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_times_provider.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_times_performance_provider.dart';
import 'package:sakina_app/features/prayers/domain/repositories/prayer_times_repository.dart';
import 'package:sakina_app/features/prayers/domain/services/prayer_notification_scheduler.dart';
import 'package:sakina_app/features/quran/domain/repositories/surah_repository.dart';
import 'package:sakina_app/features/quran/presentation/providers/bookmark_provider.dart';
import 'package:sakina_app/features/hadeath/domain/repositories/hadeath_repository.dart';
import 'package:sakina_app/features/hadeath/presentation/providers/hadeath_provider.dart';
import 'package:sakina_app/features/duas/data/repositories/azkar_repository.dart';
import 'package:sakina_app/features/duas/presentation/providers/azkar_provider.dart';
import 'package:sakina_app/features/duas/data/repositories/duas_repository.dart';
import 'package:sakina_app/features/duas/presentation/providers/duas_provider.dart';
import 'package:sakina_app/features/onboarding/presentation/providers/favorites_provider.dart';
import 'package:sakina_app/features/khatma/data/repositories/khatma_repository.dart';
import 'package:sakina_app/features/khatma/presentation/providers/khatma_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Root widget that sets up all providers and theming
///
/// This widget is responsible for:
/// - Setting up the MultiProvider with all application providers
/// - Configuring the theme
/// - Setting up routing and navigation
/// - Applying app-wide UI wrappers (RTL, NoiseBackground)
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late final SharedPreferences _prefs;
  late final PrayerTimesRepository _prayerTimesRepository;
  late final PrayerNotificationScheduler _prayerNotificationScheduler;
  late final SurahRepository _surahRepository;
  late final HadeathRepository _hadeathRepository;
  late final PrayerTimesProvider _prayerTimesProvider;
  late final PrayerTimesPerformanceProvider _prayerTimesPerformanceProvider;
  late final HadeathProvider _hadeathProvider;
  late final FavoritesProvider _favoritesProvider;
  late final ThemeProvider _themeProvider;
  late final AzkarRepository _azkarRepository;
  late final AzkarProvider _azkarProvider;
  late final DuasRepository _duasRepository;
  late final DuasProvider _duasProvider;
  late final BookmarkProvider _bookmarkProvider;
  late final SettingsProvider _settingsProvider;
  late final KhatmaRepository _khatmaRepository;
  late final KhatmaProvider _khatmaProvider;
  late final NotificationProvider _notificationProvider;

  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  void _initializeProviders() {
    // Get SharedPreferences from service locator
    _prefs = getIt<SharedPreferences>();

    // Get repositories from service locator
    _prayerTimesRepository = getIt<PrayerTimesRepository>();
    _prayerNotificationScheduler = getIt<PrayerNotificationScheduler>();
    _surahRepository = getIt<SurahRepository>();
    _hadeathRepository = getIt<HadeathRepository>();
    _azkarRepository = getIt<AzkarRepository>();
    _duasRepository = getIt<DuasRepository>();
    _khatmaRepository = getIt<KhatmaRepository>();

    // Initialize providers with repositories
    _prayerTimesProvider = PrayerTimesProvider(
      repository: _prayerTimesRepository,
      notificationScheduler: _prayerNotificationScheduler,
    );

    _prayerTimesPerformanceProvider = PrayerTimesPerformanceProvider(
      repository: _prayerTimesRepository,
      notificationScheduler: _prayerNotificationScheduler,
    );

    _hadeathProvider = HadeathProvider(repository: _hadeathRepository);

    _favoritesProvider = FavoritesProvider(prefs: _prefs);

    _themeProvider = ThemeProvider(prefs: _prefs);

    _azkarProvider = AzkarProvider(repository: _azkarRepository)..loadAzkar();

    _duasProvider = DuasProvider(repository: _duasRepository)..loadDuas();

    _bookmarkProvider = BookmarkProvider(prefs: _prefs);
    _settingsProvider = SettingsProvider(prefs: _prefs);

    _khatmaProvider = KhatmaProvider(repository: _khatmaRepository);

    // Initialize notification provider globally at app startup
    _notificationProvider = NotificationProvider(prefs: _prefs);
    _notificationProvider.initialize();

    // Set notification navigation callback
    NotificationRouter.setNavigationCallback(handleNotificationNavigation);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide SharedPreferences as a value (no recreation needed)
        Provider<SharedPreferences>.value(value: _prefs),

        // Provide repositories as values (pre-initialized)
        Provider<PrayerTimesRepository>.value(value: _prayerTimesRepository),
        Provider<SurahRepository>.value(value: _surahRepository),
        Provider<HadeathRepository>.value(value: _hadeathRepository),
        Provider<KhatmaRepository>.value(value: _khatmaRepository),

        // Provide providers as values (pre-initialized)
        ChangeNotifierProvider<PrayerTimesProvider>.value(
          value: _prayerTimesProvider,
        ),
        ChangeNotifierProvider<PrayerTimesPerformanceProvider>.value(
          value: _prayerTimesPerformanceProvider,
        ),
        ChangeNotifierProvider<HadeathProvider>.value(value: _hadeathProvider),
        ChangeNotifierProvider<FavoritesProvider>.value(
          value: _favoritesProvider,
        ),
        ChangeNotifierProvider<ThemeProvider>.value(value: _themeProvider),
        ChangeNotifierProvider<AzkarProvider>.value(value: _azkarProvider),
        ChangeNotifierProvider<DuasProvider>.value(value: _duasProvider),
        ChangeNotifierProvider<BookmarkProvider>.value(
          value: _bookmarkProvider,
        ),
        ChangeNotifierProvider<SettingsProvider>.value(
          value: _settingsProvider,
        ),
        ChangeNotifierProvider<KhatmaProvider>.value(value: _khatmaProvider),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: _notificationProvider,
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Sakina',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: const Locale('ar', 'SA'),
            routerConfig: appRouter,
            builder: (context, child) {
              return NoiseBackground(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: child!,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
