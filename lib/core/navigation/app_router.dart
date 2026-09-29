import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/foundation.dart';
import 'main_navigation_shell.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/data_sources_screen.dart';
import '../../features/onboarding/presentation/widgets/current_wird_widget.dart';
import '../../features/quran/presentation/screens/quran_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../di/service_locator.dart';
import '../router/fade_slide_route.dart';
import '../widgets/pulse_loader.dart';
import '../../features/duas/presentation/screens/azkar_details_screen.dart';
import '../../features/duas/presentation/screens/azkar_screen.dart';
import '../../features/duas/presentation/screens/duas_screen.dart';
import '../../features/hadeath/domain/entities/hadeath_entity.dart';
import '../../features/hadeath/domain/repositories/hadeath_repository.dart';
import '../../features/hadeath/presentation/screens/'
    'hadeath_details_screen.dart';
import '../../features/hadeath/presentation/screens/hadeath_screen.dart';
import '../../features/khatma/presentation/screens/khatma_duration_screen.dart';
import '../../features/khatma/presentation/screens/khatma_location_screen.dart';
import '../../features/media/presentation/providers/articles_provider.dart';
import '../../features/media/presentation/providers/audio_provider.dart';
import '../../features/media/presentation/providers/video_provider.dart';
import '../../features/media/presentation/screens/articles_screen.dart';
import '../../features/media/presentation/screens/audio_screen.dart';
import '../../features/media/presentation/screens/video_screen.dart';
import '../../features/onboarding/presentation/screens/home_screen.dart';
import '../../features/onboarding/presentation/screens/media_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/qibla/presentation/screens/qibla_screen.dart';
import '../../features/prayers/presentation/screens/prayer_times_screen.dart';
import '../../features/quran/domain/entities/surah_entity.dart';
import '../../features/quran/domain/repositories/surah_repository.dart';
import '../../features/quran/presentation/screens/asma_al_husna_screen.dart';
import '../../features/quran/presentation/screens/quran_screen.dart';
import '../../features/quran/presentation/screens/surah_details_screen.dart';
import '../../features/quran/presentation/screens/tasbeeh_screen.dart';
import '../../features/settings/presentation/screens/'
    'notification_test_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Page<void> _fadePage(GoRouterState state, Widget child) {
  return buildFadeSlidePage<void>(state: state, child: child);
}

Map<String, dynamic>? _routeExtra(Object? value) {
  if (value is! Map) return null;
  return <String, dynamic>{
    for (final entry in value.entries)
      if (entry.key is String) entry.key as String: entry.value,
  };
}

int? _routeInt(Map<String, dynamic>? extra, String key) {
  final value = extra?[key];
  if (value is num && value.isFinite) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

final GoRouter appRouter = GoRouter(
  navigatorKey: appNavigatorKey,
  initialLocation: '/splash',
  routes: <RouteBase>[
    ShellRoute(
      builder: (context, state, child) =>
          MainNavigationShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => _fadePage(state, const HomeScreen()),
        ),
        GoRoute(
          path: '/quran',
          pageBuilder: (context, state) =>
              _fadePage(state, const QuranScreen()),
        ),
        GoRoute(
          path: '/prayers',
          pageBuilder: (context, state) =>
              _fadePage(state, const PrayerTimesScreen()),
        ),
        GoRoute(
          path: '/duas',
          pageBuilder: (context, state) =>
              _fadePage(state, const AzkarScreen()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) =>
              _fadePage(state, const SettingsScreen()),
        ),
      ],
    ),
    GoRoute(
      path: '/settings/data-sources',
      pageBuilder: (context, state) =>
          _fadePage(state, const DataSourcesScreen()),
    ),
    GoRoute(
      path: '/quran/search',
      pageBuilder: (context, state) =>
          _fadePage(state, const QuranSearchScreen()),
    ),
    GoRoute(
      path: '/khatma',
      pageBuilder: (context, state) => _fadePage(
        state,
        Scaffold(
          appBar: AppBar(title: Text(l10nOf(context).appRouterMessage1)),
          body: const SingleChildScrollView(child: CurrentWirdWidget()),
        ),
      ),
    ),
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => _fadePage(state, const SplashScreen()),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) =>
          _fadePage(state, const OnboardingScreen()),
    ),

    GoRoute(
      path: '/quran/surah/:number',
      pageBuilder: (context, state) {
        final int? surahNumber = int.tryParse(
          state.pathParameters['number'] ?? '',
        );
        final Map<String, dynamic>? extra = _routeExtra(state.extra);
        final SurahEntity? surah = extra?['surah'] is SurahEntity
            ? extra!['surah'] as SurahEntity
            : null;
        final int? initialSurahNumber = _routeInt(extra, 'initialSurahNumber');
        final int? initialAyahNumber = _routeInt(extra, 'initialAyahNumber');
        final int? initialPageNumber = _routeInt(extra, 'initialPageNumber');
        final String? rangeTrackingUnit =
            extra?['rangeTrackingUnit'] as String?;
        final int? rangeFromUnit = _routeInt(extra, 'rangeFromUnit');
        final int? rangeToUnit = _routeInt(extra, 'rangeToUnit');

        if (surahNumber == null) {
          return _fadePage(
            state,
            _RouteDataErrorScreen(message: l10nOf(context).appRouterMessage2),
          );
        }

        if (surah == null) {
          return _fadePage(
            state,
            _SurahDetailsRouteLoader(
              surahNumber: surahNumber,
              initialSurahNumber: initialSurahNumber,
              initialAyahNumber: initialAyahNumber,
              initialPageNumber: initialPageNumber,
              rangeTrackingUnit: rangeTrackingUnit,
              rangeFromUnit: rangeFromUnit,
              rangeToUnit: rangeToUnit,
            ),
          );
        }

        return _fadePage(
          state,
          SurahDetailsScreen(
            surah: surah,
            surahNumber: surahNumber,
            initialSurahNumber: initialSurahNumber,
            initialAyahNumber: initialAyahNumber,
            initialPageNumber: initialPageNumber,
            rangeTrackingUnit: rangeTrackingUnit,
            rangeFromUnit: rangeFromUnit,
            rangeToUnit: rangeToUnit,
          ),
        );
      },
    ),

    GoRoute(
      path: '/qibla',
      pageBuilder: (context, state) => _fadePage(state, const QiblaScreen()),
    ),

    GoRoute(
      path: '/duas/all',
      pageBuilder: (context, state) => _fadePage(state, const DuasScreen()),
    ),
    GoRoute(
      path: '/azkar/details',
      pageBuilder: (context, state) {
        final Map<String, dynamic>? extra = _routeExtra(state.extra);
        return _fadePage(
          state,
          AzkarDetailsScreen(
            categoryName: extra?['categoryName'] as String? ?? '',
          ),
        );
      },
    ),
    GoRoute(
      path: '/duas/morning',
      pageBuilder: (context, state) => _fadePage(
        state,
        const AzkarDetailsScreen(categoryName: 'أذكار الصباح'),
      ),
    ),
    GoRoute(
      path: '/duas/evening',
      pageBuilder: (context, state) => _fadePage(
        state,
        const AzkarDetailsScreen(categoryName: 'أذكار المساء'),
      ),
    ),
    GoRoute(
      path: '/hadeath',
      pageBuilder: (context, state) => _fadePage(state, const HadeathScreen()),
    ),
    GoRoute(
      path: '/hadeath/details/:index',
      pageBuilder: (context, state) {
        final HadeathEntity? hadeath = state.extra is HadeathEntity
            ? state.extra as HadeathEntity
            : null;
        final int? index = int.tryParse(state.pathParameters['index'] ?? '');

        if (index == null) {
          return _fadePage(
            state,
            _RouteDataErrorScreen(message: l10nOf(context).appRouterMessage3),
          );
        }

        if (hadeath == null) {
          return _fadePage(state, _HadeathDetailsRouteLoader(index: index));
        }

        return _fadePage(state, HadeathDetailsScreen(hadeath: hadeath));
      },
    ),
    GoRoute(
      path: '/tasbeeh',
      pageBuilder: (context, state) => _fadePage(state, const TasbeehScreen()),
    ),
    GoRoute(
      path: '/asma',
      pageBuilder: (context, state) =>
          _fadePage(state, const AsmaAlHusnaScreen()),
    ),
    GoRoute(
      path: '/media',
      pageBuilder: (context, state) => _fadePage(state, const MediaScreen()),
    ),
    GoRoute(
      path: '/media/articles',
      pageBuilder: (context, state) => _fadePage(
        state,
        ChangeNotifierProvider<ArticlesProvider>(
          create: (_) => getIt<ArticlesProvider>()..loadArticles(),
          child: const ArticlesScreen(),
        ),
      ),
    ),
    GoRoute(
      path: '/media/audio',
      pageBuilder: (context, state) => _fadePage(
        state,
        ChangeNotifierProvider<AudioProvider>(
          create: (_) => getIt<AudioProvider>()..loadReciters(),
          child: const AudioScreen(),
        ),
      ),
    ),
    GoRoute(
      path: '/media/videos',
      pageBuilder: (context, state) => _fadePage(
        state,
        ChangeNotifierProvider<VideoProvider>(
          create: (_) => getIt<VideoProvider>()..loadVideos(),
          child: const VideoScreen(),
        ),
      ),
    ),
    if (kDebugMode)
      GoRoute(
        path: '/settings/notification-test',
        pageBuilder: (context, state) =>
            _fadePage(state, const NotificationTestScreen()),
      ),
    GoRoute(
      path: '/khatma/location',
      pageBuilder: (context, state) =>
          _fadePage(state, const KhatmaLocationScreen()),
    ),
    GoRoute(
      path: '/khatma/duration',
      pageBuilder: (context, state) {
        final Map<String, dynamic>? extra = _routeExtra(state.extra);
        final String startMode =
            extra?['startMode'] as String? ?? l10nOf(context).appRouterMessage4;
        final int? startJuz = _routeInt(extra, 'startJuz');

        return _fadePage(
          state,
          KhatmaDurationScreen(startMode: startMode, startJuz: startJuz),
        );
      },
    ),
  ],
);

class _RouteDataErrorScreen extends StatelessWidget {
  final String message;

  const _RouteDataErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l10nOf(context).appRouterMessage5)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _SurahDetailsRouteLoader extends StatelessWidget {
  final int surahNumber;
  final int? initialSurahNumber;
  final int? initialAyahNumber;
  final int? initialPageNumber;
  final String? rangeTrackingUnit;
  final int? rangeFromUnit;
  final int? rangeToUnit;

  const _SurahDetailsRouteLoader({
    required this.surahNumber,
    this.initialSurahNumber,
    this.initialAyahNumber,
    this.initialPageNumber,
    this.rangeTrackingUnit,
    this.rangeFromUnit,
    this.rangeToUnit,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SurahEntity>(
      future: context.read<SurahRepository>().getSurahByIndex(surahNumber),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: PulseLoader(lines: 5)));
        }

        final SurahEntity? surah = snapshot.data;
        if (snapshot.hasError || surah == null) {
          return _RouteDataErrorScreen(
            message: l10nOf(context).appRouterMessage6,
          );
        }

        return SurahDetailsScreen(
          surah: surah,
          surahNumber: surahNumber,
          initialSurahNumber: initialSurahNumber,
          initialAyahNumber: initialAyahNumber,
          initialPageNumber: initialPageNumber,
          rangeTrackingUnit: rangeTrackingUnit,
          rangeFromUnit: rangeFromUnit,
          rangeToUnit: rangeToUnit,
        );
      },
    );
  }
}

class _HadeathDetailsRouteLoader extends StatelessWidget {
  final int index;

  const _HadeathDetailsRouteLoader({required this.index});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HadeathEntity>>(
      future: context.read<HadeathRepository>().getAllAhadeth(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: PulseLoader(lines: 5)));
        }

        final List<HadeathEntity> all =
            snapshot.data ?? const <HadeathEntity>[];
        if (snapshot.hasError || index < 0 || index >= all.length) {
          return _RouteDataErrorScreen(
            message: l10nOf(context).appRouterMessage7,
          );
        }

        return HadeathDetailsScreen(hadeath: all[index]);
      },
    );
  }
}
