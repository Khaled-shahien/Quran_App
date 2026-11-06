import 'package:sakina_app/core/app/app_frame.dart';
import 'package:sakina_app/core/feedback/feedback_service.dart';
import 'dart:async';
import '../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/di/service_locator.dart';
import 'package:sakina_app/core/theme/app_theme.dart';
import 'package:sakina_app/core/theme/theme_provider.dart';
import 'package:sakina_app/core/navigation/app_router.dart';
import 'package:sakina_app/core/navigation/notification_handler.dart';
import 'package:sakina_app/core/navigation/notification_router.dart';
import 'package:sakina_app/core/providers/notification_provider.dart';
import 'package:sakina_app/core/providers/settings_provider.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_times_provider.dart';

import 'package:sakina_app/features/prayers/domain/repositories/prayer_times_repository.dart';
import 'package:sakina_app/features/prayers/domain/services/prayer_notification_scheduler.dart';
import 'package:sakina_app/features/quran/domain/repositories/surah_repository.dart';
import 'package:sakina_app/features/quran/presentation/providers/bookmark_provider.dart';
import 'package:sakina_app/features/quran/data/repositories/tasbih_repository_impl.dart';
import 'package:sakina_app/features/quran/presentation/providers/tasbih_controller.dart';
import 'package:sakina_app/core/audio/recitation_audio_engine.dart';
import 'package:sakina_app/core/utils/surah_names.dart';
import 'package:sakina_app/core/services/notification_service.dart';
import 'package:sakina_app/features/prayers/data/repositories/adhan_settings_store.dart';
import 'package:sakina_app/features/prayers/presentation/providers/adhan_settings_controller.dart';
import 'package:sakina_app/features/settings/presentation/providers/reading_mode_controller.dart';
import 'package:sakina_app/features/settings/presentation/providers/text_size_controller.dart';
import 'package:sakina_app/core/accessibility/app_text_scale.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/features/settings/presentation/providers/digit_style_controller.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_arrival_watcher.dart';
import 'package:sakina_app/features/prayers/presentation/widgets/adhan_preferences.dart';
import 'package:sakina_app/features/prayers/domain/entities/adhan_settings.dart';
import 'package:sakina_app/features/recitation/domain/repositories/recitation_repository.dart';
import 'package:sakina_app/features/recitation/presentation/providers/recitation_controller.dart';
import 'package:sakina_app/features/recitation/presentation/providers/recitation_downloads_controller.dart';
import 'package:sakina_app/l10n/localization.dart';
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

class _AppRootState extends State<AppRoot> with WidgetsBindingObserver {
  Timer? _prayerClockTimer;
  late final SharedPreferences _prefs;
  late final PrayerTimesRepository _prayerTimesRepository;
  late final PrayerNotificationScheduler _prayerNotificationScheduler;
  late final SurahRepository _surahRepository;
  late final HadeathRepository _hadeathRepository;
  late final PrayerTimesProvider _prayerTimesProvider;

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
  late final TasbihController _tasbihController;

  @override
  void initState() {
    super.initState();
    _initializeProviders();
    WidgetsBinding.instance.addObserver(this);
    _prayerClockTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _onClockTick(),
    );
  }

  final PrayerArrivalWatcher _arrivalWatcher = PrayerArrivalWatcher();
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  void _onClockTick() {
    _prayerTimesProvider.updateClock();
    final arrived = _arrivalWatcher.tick(
      _prayerTimesProvider.nextPrayer,
      DateTime.now(),
    );
    if (arrived != null && _lifecycle == AppLifecycleState.resumed) {
      _onPrayerArrived(arrived);
    }
  }

  /// While the app is open at prayer time: pause recitation (it must never
  /// play over the adhan) and offer the adhan adhkar and to resume.
  Future<void> _onPrayerArrived(NextPrayer prayer) async {
    final settings = AdhanSettingsStore(_prefs).read();
    final daily = DailyPrayer.values.where(
      (p) => appL10n.prayerName(p) == prayer.name,
    );
    if (daily.isNotEmpty &&
        settings.modeFor(daily.first) == PrayerAlertMode.silent) {
      return;
    }
    final navContext = appNavigatorKey.currentContext;
    if (navContext == null) return;
    final recitation = Provider.of<RecitationController?>(
      navContext,
      listen: false,
    );
    final paused = await recitation?.pauseForInterruption() ?? false;
    if (!navContext.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(navContext);
    if (messenger == null) return;
    final l10n = l10nOf(navContext);
    messenger
      ..clearMaterialBanners()
      ..showMaterialBanner(
        MaterialBanner(
          content: Text(l10n.prayerTimeArrived(prayer.name)),
          leading: const Icon(Icons.mosque_rounded),
          actions: [
            TextButton(
              onPressed: () {
                messenger.hideCurrentMaterialBanner();
                appRouter.push(
                  Uri(
                    path: '/after-adhan',
                    queryParameters: {'prayer': prayer.name},
                  ).toString(),
                );
              },
              child: Text(l10n.afterAdhanOpen),
            ),
            if (paused)
              TextButton(
                onPressed: () {
                  messenger.hideCurrentMaterialBanner();
                  recitation?.resumeAfterInterruption();
                },
                child: Text(l10n.recitationResume),
              ),
            TextButton(
              onPressed: messenger.hideCurrentMaterialBanner,
              child: Text(l10n.appStringsMessage8),
            ),
          ],
        ),
      );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    if (state == AppLifecycleState.resumed &&
        _prayerTimesProvider.selectedCoordinates != null) {
      _prayerTimesProvider.refreshIfNeeded();
    }
  }

  @override
  void dispose() {
    _prayerClockTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _prayerTimesProvider.dispose();

    _hadeathProvider.dispose();
    _favoritesProvider.dispose();
    _themeProvider.dispose();
    _azkarProvider.dispose();
    _duasProvider.dispose();
    _bookmarkProvider.dispose();
    _settingsProvider.dispose();
    _khatmaProvider.dispose();
    _notificationProvider.dispose();
    _tasbihController.dispose();
    super.dispose();
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
      preferences: _prefs,
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

    // TODO: resolve TasbihRepository from GetIt.
    _tasbihController = TasbihController(
      repository: SharedPreferencesTasbihRepository(_prefs),
    );

    // Initialize notification provider globally at app startup
    _notificationProvider = NotificationProvider(prefs: _prefs);
    _notificationProvider.initialize();

    // Set notification navigation callback
    NotificationRouter.hold();
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
        ChangeNotifierProvider<TasbihController>.value(
          value: _tasbihController,
        ),
        // Created on first use; one player for the whole app.
        ChangeNotifierProvider<RecitationController>(
          create: (_) => RecitationController(
            repository: getIt<RecitationRepository>(),
            engine: getIt<RecitationAudioEngine>(),
            preferences: _prefs,
            surahName: (surah) =>
                appL10n.surahAudioModelMessage1(surahNameAr(surah) ?? '$surah'),
          )..initialize(),
        ),
        ChangeNotifierProvider<ReadingModeController>(
          create: (_) => ReadingModeController(_prefs),
        ),
        ChangeNotifierProvider<TextSizeController>(
          create: (_) => TextSizeController(_prefs),
        ),
        ChangeNotifierProvider<FeedbackService>.value(
          value: getIt<FeedbackService>(),
        ),
        ChangeNotifierProvider<DigitStyleController>(
          create: (_) => DigitStyleController(_prefs),
        ),
        ChangeNotifierProvider<AdhanSettingsController>(
          create: (_) => AdhanSettingsController(
            store: AdhanSettingsStore(_prefs),
            platform: AdhanPlatform(
              reschedule: _prayerTimesProvider.refresh,
              canScheduleExact:
                  NotificationService.instance.canScheduleExactAlarms,
              requestExact:
                  NotificationService.instance.requestExactAlarmPermission,
              scheduleTest:
                  NotificationService.instance.scheduleTestPrayerAlert,
            ),
          ),
        ),
        ChangeNotifierProvider<RecitationDownloadsController>(
          create: (_) => RecitationDownloadsController(
            repository: getIt<RecitationRepository>(),
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)!.applicationTitle,
            theme: AppTheme.light(themeProvider.design),
            darkTheme: AppTheme.dark(themeProvider.design),
            themeMode: themeProvider.effectiveThemeMode,
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: appRouter,
            builder: (context, child) {
              final textSize = context.watch<TextSizeController>().factor;
              final digits = context.watch<DigitStyleController>().style;
              return DigitStyleScope(
                style: digits,
                child: AppTextScale(
                  factor: textSize,
                  child: AppFrame(
                    sheetContext: () => appNavigatorKey.currentContext,
                    child: child!,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
