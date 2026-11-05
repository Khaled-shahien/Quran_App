import '../../features/islamic_guide/data/islamic_guide_repository_impl.dart';
import '../../features/islamic_guide/domain/repositories/islamic_guide_repository.dart';
import 'package:sakina_app/features/quran/data/data_sources/local_quran_data_source.dart';
import 'package:sakina_app/features/quran/data/repositories/ayah_repository.dart';
import 'package:sakina_app/features/quran/domain/repositories/ayah_repository.dart';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sakina_app/core/audio/just_audio_recitation_engine.dart';
import 'package:sakina_app/core/audio/recitation_audio_engine.dart';
import 'package:sakina_app/features/recitation/data/datasources/quran_cdn_recitation_source.dart';
import 'package:sakina_app/features/recitation/data/repositories/recitation_repository_impl.dart';
import 'package:sakina_app/features/recitation/domain/repositories/recitation_repository.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina_app/core/constants/api_keys.dart';
import 'package:sakina_app/core/services/cached_api_service.dart';
import 'package:sakina_app/features/prayers/data/services/local_prayer_notification_scheduler.dart';

import 'package:sakina_app/features/prayers/domain/repositories/prayer_times_repository.dart';
import 'package:sakina_app/features/prayers/domain/services/prayer_notification_scheduler.dart';
import 'package:sakina_app/features/prayers/data/repositories/prayer_times_repository_impl.dart';

import 'package:sakina_app/features/quran/data/data_sources/local_surah_data_source.dart';
import 'package:sakina_app/features/quran/domain/repositories/surah_repository.dart';
import 'package:sakina_app/features/quran/data/repositories/surah_repository.dart';

import 'package:sakina_app/features/hadeath/data/data_sources/local_hadeath_data_source.dart';
import 'package:sakina_app/features/hadeath/domain/repositories/hadeath_repository.dart';
import 'package:sakina_app/features/hadeath/data/repositories/hadeath_repository_impl.dart';

import 'package:sakina_app/features/duas/data/repositories/azkar_repository.dart';
import 'package:sakina_app/features/duas/data/repositories/adhan_adhkar_repository.dart';
import 'package:sakina_app/features/duas/data/repositories/duas_repository.dart';
import 'package:sakina_app/features/khatma/data/repositories/khatma_repository.dart';
import 'package:sakina_app/features/media/data/datasources/articles_remote_datasource.dart';

import 'package:sakina_app/features/media/data/datasources/video_remote_datasource.dart';
import 'package:sakina_app/features/media/data/repositories/media_repository_impl.dart';
import 'package:sakina_app/features/media/domain/repositories/media_repository.dart';
import 'package:sakina_app/features/media/domain/usecases/get_articles.dart';
import 'package:sakina_app/features/media/domain/usecases/get_islamic_videos.dart';

import 'package:sakina_app/features/media/presentation/providers/articles_provider.dart';

import 'package:sakina_app/features/media/presentation/providers/video_provider.dart';

import 'package:sakina_app/core/services/notification_service.dart';
import 'package:sakina_app/core/services/workmanager_service.dart';

/// Global instance for dependency injection based on GetIt.
final GetIt getIt = GetIt.instance;

/// Sets up the dependency injection container.
///
/// This asynchronous function initializes [SharedPreferences] and registers all
/// the data sources and repositories required by the application using [GetIt].
/// It guarantees that our dependencies are correctly instantiated as lazy
/// singletons so they share instances but load strictly upon access.
Future<void> setupServiceLocator() async {
  try {
    // A startup retry must not fail on registrations from the failed attempt.
    await getIt.reset();

    // ==========================================
    // Core / External Utilities
    // ==========================================
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(prefs);
    getIt.registerLazySingleton<AyahRepository>(
      () => AyahRepositoryImpl(
        localDataSource: LocalQuranDataSource(),
        sharedPreferences: prefs,
      ),
    );
    getIt.registerLazySingleton<http.Client>(() => http.Client());
    getIt.registerLazySingleton<CachedApiService>(
      () => CachedApiService(getIt<SharedPreferences>()),
    );

    // ==========================================
    // Data Sources
    // ==========================================

    getIt.registerLazySingleton<LocalSurahDataSource>(
      () => LocalSurahDataSource(),
    );

    getIt.registerLazySingleton<LocalHadeathDataSource>(
      () => LocalHadeathDataSource(),
    );

    getIt.registerLazySingleton<ArticlesRemoteDataSource>(
      () => ArticlesRemoteDataSource(
        client: getIt<http.Client>(),
        cache: getIt<CachedApiService>(),
      ),
    );

    getIt.registerLazySingleton<VideoRemoteDataSource>(
      () => VideoRemoteDataSource(
        client: getIt<http.Client>(),
        cache: getIt<CachedApiService>(),
        apiKey: ApiKeys.youtubeApiKey,
      ),
    );

    // ==========================================
    // Repositories
    // ==========================================

    getIt.registerLazySingleton<PrayerTimesRepository>(
      () => PrayerTimesRepositoryImpl(),
    );

    getIt.registerLazySingleton<SurahRepository>(
      () => SurahRepositoryImpl(
        localDataSource: getIt<LocalSurahDataSource>(),
        sharedPreferences: getIt<SharedPreferences>(),
      ),
    );

    getIt.registerLazySingleton<HadeathRepository>(
      () => HadeathRepositoryImpl(
        localDataSource: getIt<LocalHadeathDataSource>(),
      ),
    );

    getIt.registerLazySingleton<IslamicGuideRepository>(
      () => IslamicGuideRepositoryImpl(
        ayahRepository: getIt<AyahRepository>(),
        surahRepository: getIt<SurahRepository>(),
      ),
    );

    getIt.registerLazySingleton<AzkarRepository>(() => AzkarRepositoryImpl());

    getIt.registerLazySingleton<DuasRepository>(() => DuasRepositoryImpl());

    getIt.registerLazySingleton<AdhanAdhkarRepository>(
      () => AdhanAdhkarRepositoryImpl(),
    );

    getIt.registerLazySingleton<KhatmaRepository>(
      () => KhatmaRepositoryImpl(prefs: getIt<SharedPreferences>()),
    );

    getIt.registerLazySingleton<MediaRepository>(
      () => MediaRepositoryImpl(
        articlesDataSource: getIt<ArticlesRemoteDataSource>(),

        videoDataSource: getIt<VideoRemoteDataSource>(),
      ),
    );

    // ==========================================
    // Use Cases
    // ==========================================

    getIt.registerLazySingleton<GetArticles>(
      () => GetArticles(getIt<MediaRepository>()),
    );

    getIt.registerLazySingleton<GetIslamicVideos>(
      () => GetIslamicVideos(getIt<MediaRepository>()),
    );

    // ==========================================
    // Feature Providers
    // ==========================================

    getIt.registerFactory<ArticlesProvider>(
      () => ArticlesProvider(getArticles: getIt<GetArticles>()),
    );

    getIt.registerFactory<VideoProvider>(
      () => VideoProvider(getIslamicVideos: getIt<GetIslamicVideos>()),
    );

    // ==========================================
    // Services
    // ==========================================

    getIt.registerLazySingleton<NotificationService>(
      () => NotificationService(),
    );

    getIt.registerLazySingleton<PrayerNotificationScheduler>(
      () => LocalPrayerNotificationScheduler(
        prefs: getIt<SharedPreferences>(),
        onScheduled: () =>
            WorkManagerService().registerImmediateRescheduleTask(),
        notificationGateway: NotificationServicePrayerNotificationGateway(
          notificationService: getIt<NotificationService>(),
        ),
      ),
    );

    getIt.registerLazySingleton<WorkManagerService>(() => WorkManagerService());

    // ==========================================
    // Quran recitation
    // ==========================================

    getIt.registerLazySingleton<RecitationRepository>(
      () => RecitationRepositoryImpl(
        remote: QuranCdnRecitationSource(client: getIt<http.Client>()),
        downloadsDirectory: () async => Directory(
          '${(await getApplicationSupportDirectory()).path}/recitation',
        ),
      ),
    );
    getIt.registerLazySingleton<RecitationAudioEngine>(
      () => JustAudioRecitationEngine(
        notificationChannelName: appL10n.recitationChannelName,
      ),
    );
  } catch (e) {
    developer.log(
      'Service Locator setup failed',
      name: 'sakina_app.di',
      error: e,
      level: 1000,
    );
    rethrow;
  }
}
