import 'package:sakina_app/core/result/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/theme/app_theme.dart';
import 'package:sakina_app/features/media/domain/entities/article.dart';
import 'package:sakina_app/features/media/domain/entities/video.dart';
import 'package:sakina_app/features/media/domain/errors/media_exception.dart';
import 'package:sakina_app/features/media/domain/repositories/media_repository.dart';
import 'package:sakina_app/features/media/domain/usecases/get_articles.dart';
import 'package:sakina_app/features/media/domain/usecases/get_islamic_videos.dart';
import 'package:sakina_app/features/media/presentation/providers/articles_provider.dart';
import 'package:sakina_app/features/media/presentation/providers/video_provider.dart';
import 'package:sakina_app/features/media/presentation/screens/articles_screen.dart';
import 'package:sakina_app/features/media/presentation/screens/video_screen.dart';
import 'package:sakina_app/features/media/presentation/widgets/media_state_views.dart';
import 'package:sakina_app/l10n/localization.dart';

class _Repository implements MediaRepository {
  bool offline = true;
  Object? videoFailure;

  void check() {
    if (offline) throw MediaException(appL10n.mediaRepositoryImplMessage5);
  }

  @override
  Future<Result<List<Article>>> getArticles() => Result.guard(
    () => _legacyGetArticles(),
    onError: (error, _) => UnexpectedFailure(cause: error),
  );

  Future<List<Article>> _legacyGetArticles() async {
    check();
    return [
      Article(
        title: 'Article result',
        description: 'Summary',
        link: 'https://example.com',
        pubDate: DateTime(2026),
        sourceName: 'Source',
        category: 'Category',
      ),
    ];
  }

  @override
  Future<Result<List<Video>>> getIslamicVideos(String query) => Result.guard(
    () => _legacyGetIslamicVideos(query),
    onError: (error, _) => UnexpectedFailure(cause: error),
  );

  Future<List<Video>> _legacyGetIslamicVideos(String query) async {
    if (videoFailure != null) throw videoFailure!;
    check();
    return [
      const Video(
        videoId: 'id',
        title: 'Video result',
        description: '',
        thumbnailUrl: '',
        channelTitle: 'Channel',
        publishedAt: null,
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final dark in [false, true]) {
    for (final kind in ['Article', 'Video']) {
      testWidgets('$kind offline retry and failed refresh, dark=$dark', (
        tester,
      ) async {
        final repository = _Repository();
        final articles = ArticlesProvider(getArticles: GetArticles(repository));
        final video = VideoProvider(
          getIslamicVideos: GetIslamicVideos(repository),
        );
        addTearDown(articles.dispose);
        addTearDown(video.dispose);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: articles),
              ChangeNotifierProvider.value(value: video),
            ],
            child: MaterialApp(
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              home: switch (kind) {
                'Article' => const ArticlesScreen(),
                _ => const VideoScreen(),
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(MediaErrorView), findsOneWidget);
        expect(find.text(appL10n.mediaRepositoryImplMessage5), findsOneWidget);
        expect(
          Directionality.of(tester.element(find.byType(MediaErrorView))),
          TextDirection.rtl,
        );

        repository.offline = false;
        await tester.tap(find.text(appL10n.retry));
        await tester.pumpAndSettle();
        expect(find.byType(MediaErrorView), findsNothing);
        expect(find.text('$kind result'), findsOneWidget);

        repository.offline = true;
        await tester.drag(
          find.byType(RefreshIndicator).first,
          const Offset(0, 400),
        );
        await tester.pumpAndSettle();
        expect(find.byType(MediaErrorView), findsOneWidget);
        expect(find.text('$kind result'), findsNothing);

        repository.offline = false;
        await tester.tap(find.text(appL10n.retry));
        await tester.pumpAndSettle();
        expect(find.text('$kind result'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  for (final failure in [
    MissingApiKeyException(appL10n.videoRemoteDatasourceMessage1),
    QuotaExceededException(appL10n.videoRemoteDatasourceMessage2),
  ]) {
    test('video retains channel fallback for ${failure.runtimeType}', () async {
      final repository = _Repository()..videoFailure = failure;
      final provider = VideoProvider(
        getIslamicVideos: GetIslamicVideos(repository),
      );
      addTearDown(provider.dispose);
      await provider.loadVideos();
      expect(provider.isLoading, isFalse);
      expect(provider.hasError, isFalse);
      expect(provider.videos, isEmpty);
      expect(provider.channels, VideoProvider.fallbackChannels);
      expect(provider.fallbackMessage, failure.message);
      repository.videoFailure = null;
      repository.offline = false;
      await provider.loadVideos();
      expect(provider.channels, isEmpty);
      expect(provider.fallbackMessage, isNull);
      expect(provider.videos, hasLength(1));
    });
  }
}
