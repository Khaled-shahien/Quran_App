import 'package:sakina_app/features/quran/presentation/providers/verse_library_controller.dart';
import 'package:sakina_app/features/quran/data/repositories/verse_library_repository.dart';
import 'package:sakina_app/core/database/app_database.dart';
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
import 'package:sakina_app/features/quran/domain/repositories/tasbih_repository.dart';
import 'package:sakina_app/features/quran/presentation/providers/tasbih_controller.dart';
import 'package:sakina_app/core/audio/recitation_audio_engine.dart';
import 'package:sakina_app/core/utils/surah_names.dart';
import 'package:sakina_app/core/services/diagnostics_log.dart';
import 'package:sakina_app/core/services/notification_service.dart';
import 'package:sakina_app/core/services/notification_permission_service.dart';
import 'package:sakina_app/features/prayers/data/repositories/adhan_settings_store.dart';
import 'package:sakina_app/features/prayers/presentation/providers/adhan_settings_controller.dart';
import 'package:sakina_app/features/settings/presentation/providers/reading_mode_controller.dart';
import 'package:sakina_app/features/settings/presentation/providers/text_size_controller.dart';
import 'package:sakina_app/core/accessibility/app_text_scale.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/features/settings/presentation/providers/digit_style_controller.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_arrival_watcher.dart';
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
    // After the first frame, so startup is not slowed by scheduling.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_khatmaProvider.refreshReminder());
      unawaited(_followDeviceLocation());
      unawaited(_recheckNotificationPermission());
    });
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
    if (settings.modeFor(prayer.prayer) == PrayerAlertMode.silent) return;
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
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _leftAppSinceCheck = true;
    }
    if (state == AppLifecycleState.resumed) {
      // A new day can change the Khatma range the reminder names.
      unawaited(_khatmaProvider.refreshReminder());
      unawaited(_followTimezoneChange());
      unawaited(_refreshExactAlarmStatus());
      unawaited(
        _recheckNotificationPermission(afterLeaving: _leftAppSinceCheck),
      );
      _leftAppSinceCheck = false;
    }
    if (state == AppLifecycleState.resumed &&
        _prayerTimesProvider.selectedCoordinates != null) {
      unawaited(
        _prayerTimesProvider.refreshIfNeeded().then(
          (_) => _followDeviceLocation(),
        ),
      );
    }
  }

  /// A device prayer location follows the phone: at most every few hours,
  /// only in the foreground, only with access already granted, and it
  /// reschedules only after a real move (PrayerTimesProvider decides).
  Future<void> _followDeviceLocation() async {
    try {
      await _prayerTimesProvider.refreshDeviceLocationIfStale();
    } catch (error) {
      unawaited(DiagnosticsLog.record(error, source: 'device_location'));
    }
  }

  late final NotificationPermissionService _notificationPermissions =
      NotificationPermissionService(prefs: _prefs);
  NotificationPermissionStatus? _notificationStatus;

  /// The app went to the background (e.g. to system settings) since the
  /// last check. The system permission dialog only makes it inactive.
  bool _leftAppSinceCheck = false;

  /// Notifications can be allowed or blocked in system settings while the
  /// app is away. When they become allowed there, reminders and prayer
  /// alerts are rescheduled once through the usual paths, so nothing waits
  /// for the next background run. A grant from an in-app request is left to
  /// the screen that asked, which schedules itself.
  Future<void> _recheckNotificationPermission({
    bool afterLeaving = false,
  }) async {
    try {
      final previous = _notificationStatus;
      final current = await _notificationPermissions.status();
      _notificationStatus = current;
      if (!afterLeaving ||
          previous == null ||
          previous == current ||
          current != NotificationPermissionStatus.granted ||
          !mounted) {
        return;
      }
      await _settingsProvider.resyncAlarms();
      if (_prayerTimesProvider.selectedCoordinates != null) {
        await _prayerTimesProvider.refresh();
      }
    } catch (error) {
      unawaited(DiagnosticsLog.record(error, source: 'notification_access'));
    }
  }

  /// The exact-alarm permission can be revoked or granted while the app is
  /// in the background; the controller re-plans alerts when it changed.
  Future<void> _refreshExactAlarmStatus() async {
    final navContext = appNavigatorKey.currentContext;
    if (navContext == null) return;
    try {
      await Provider.of<AdhanSettingsController?>(
        navContext,
        listen: false,
      )?.refreshExactStatus();
    } catch (error) {
      unawaited(DiagnosticsLog.record(error, source: 'exact_alarm'));
    }
  }

  /// After travel or a manual timezone change, reminders and prayer times
  /// follow the new zone (audit NOTIF-02).
  Future<void> _followTimezoneChange() async {
    try {
      if (!await NotificationService.instance.refreshTimezoneIfChanged()) {
        return;
      }
      if (!mounted) return;
      await _settingsProvider.resyncAlarms();
      if (_prayerTimesProvider.selectedCoordinates != null) {
        await _prayerTimesProvider.refresh();
      }
    } catch (error) {
      unawaited(DiagnosticsLog.record(error, source: 'timezone'));
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

    _tasbihController = TasbihController(repository: getIt<TasbihRepository>());

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
        // Interface sounds never play over recitation.
        ProxyProvider<RecitationController, SacredAudioGate>(
          lazy: false,
          update: (_, recitation, _) {
            getIt<FeedbackService>().isSacredAudioPlaying = () =>
                recitation.isPlaying;
            return const SacredAudioGate();
          },
        ),
        ChangeNotifierProvider<ReadingModeController>(
          create: (_) => ReadingModeController(_prefs),
        ),
        // Loaded on first use, so the database opens only when needed.
        ChangeNotifierProvider<VerseLibraryController>(
          create: (_) => VerseLibraryController(
            VerseLibraryRepository(getIt.getAsync<AppDatabase>),
          ),
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
              requestNotifications:
                  NotificationService.instance.requestPermissions,
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
