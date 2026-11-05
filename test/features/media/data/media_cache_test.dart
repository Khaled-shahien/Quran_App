import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/core/services/cached_api_service.dart';
import 'package:sakina_app/features/media/data/datasources/articles_remote_datasource.dart';
import 'package:sakina_app/features/media/data/datasources/video_remote_datasource.dart';
import 'package:sakina_app/features/media/data/repositories/media_repository_impl.dart';
import 'package:sakina_app/features/media/domain/errors/media_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';

const articleBody =
    '<rss><channel><item><title>Article</title>'
    '<link>https://example.com/article</link>'
    '<pubDate>2026-09-28T10:00:00Z</pubDate></item></channel></rss>';
const videoBody =
    '{"items":[{"id":{"videoId":"video1"},"snippet":'
    '{"title":"Video","channelTitle":"Channel"}}]}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late MediaRepositoryImpl repository;
  late bool offline;
  late bool malformed;
  late bool empty;
  late int statusCode;
  late int requests;

  MediaRepositoryImpl createRepository({String apiKey = 'test-key'}) {
    final client = MockClient((request) async {
      requests++;
      if (offline) throw const SocketException('offline');
      final body = malformed
          ? '<html>Service unavailable</html>'
          : request.url.host == 'www.googleapis.com'
          ? (empty ? '{"items":[]}' : videoBody)
          : (empty ? '<rss><channel></channel></rss>' : articleBody);
      return http.Response(body, statusCode);
    });
    addTearDown(client.close);
    final cache = CachedApiService(prefs);
    return MediaRepositoryImpl(
      articlesDataSource: ArticlesRemoteDataSource(
        client: client,
        cache: cache,
      ),
      videoDataSource: VideoRemoteDataSource(
        client: client,
        cache: cache,
        apiKey: apiKey,
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    offline = false;
    malformed = false;
    empty = false;
    statusCode = 200;
    requests = 0;
    repository = createRepository();
  });

  Future<void> expire() async {
    for (final key in prefs.getKeys().where((k) => k.endsWith('_timestamp'))) {
      await prefs.setInt(
        key,
        DateTime.now()
            .subtract(const Duration(hours: 7))
            .millisecondsSinceEpoch,
      );
    }
  }

  for (final kind in ['articles', 'video']) {
    Future<List<Object>> load() async => switch (kind) {
      'articles' => unwrap(repository.getArticles()),
      _ => unwrap(repository.getIslamicVideos('query')),
    };
    group(kind, () {
      test('valid empty result is cacheable offline', () async {
        empty = true;
        expect(await load(), isEmpty);
        final before = requests;
        offline = true;
        expect(await load(), isEmpty);
        expect(requests, before);
      });
      test('HTTP failure is not cached; retry recovers', () async {
        statusCode = 503;
        await expectLater(load(), throwsA(isA<MediaException>()));
        expect(prefs.getKeys(), isEmpty);
        statusCode = 200;
        expect(await load(), isNotEmpty);
      });
      test('fresh persisted cache works offline in a new repository', () async {
        final initial = await load();
        expect(initial, isNotEmpty);
        final before = requests;
        offline = true;
        repository = createRepository();
        expect(await load(), hasLength(initial.length));
        expect(requests, before);
      });
      test('cold offline failure is retryable', () async {
        offline = true;
        await expectLater(load(), throwsA(isA<MediaException>()));
        expect(prefs.getKeys(), isEmpty);
        offline = false;
        expect(await load(), isNotEmpty);
      });
      test('expired cache refreshes online', () async {
        await load();
        await expire();
        final before = requests;
        expect(await load(), isNotEmpty);
        expect(requests, greaterThan(before));
        offline = true;
        final refreshed = requests;
        expect(await load(), isNotEmpty);
        expect(requests, refreshed);
      });
      test(
        'expired cache is not presented as fresh offline; retry recovers',
        () async {
          await load();
          await expire();
          offline = true;
          await expectLater(load(), throwsA(isA<MediaException>()));
          expect(prefs.getKeys(), isEmpty);
          offline = false;
          expect(await load(), isNotEmpty);
        },
      );
      test(
        'corrupt cached body is replaced by a valid network response',
        () async {
          await load();
          for (final key in prefs.getKeys().where(
            (k) => !k.endsWith('_timestamp'),
          )) {
            await prefs.setString(key, 'broken payload');
          }
          final before = requests;
          expect(await load(), isNotEmpty);
          expect(requests, greaterThan(before));
        },
      );
      test(
        'invalid network payload is not cached and retry recovers',
        () async {
          malformed = true;
          await expectLater(load(), throwsA(isA<MediaException>()));
          expect(prefs.getKeys(), isEmpty);
          malformed = false;
          expect(await load(), isNotEmpty);
        },
      );
    });
  }

  test('video cache can be browsed without an API key', () async {
    await unwrap(repository.getIslamicVideos('query'));
    final before = requests;
    repository = createRepository(apiKey: '');
    offline = true;
    expect(await unwrap(repository.getIslamicVideos('query')), hasLength(1));
    expect(requests, before);
    await expectLater(
      unwrap(repository.getIslamicVideos('other query')),
      throwsA(isA<MissingApiKeyException>()),
    );
  });

  test('video cache is query-specific', () async {
    await unwrap(repository.getIslamicVideos('query'));
    offline = true;
    await expectLater(
      unwrap(repository.getIslamicVideos('another query')),
      throwsA(isA<MediaException>()),
    );
    expect(await unwrap(repository.getIslamicVideos('query')), hasLength(1));
  });

  test('RSS returns available feeds when another source fails', () async {
    var count = 0;
    final client = MockClient((request) async {
      count++;
      if (count == 1) throw const SocketException('one unavailable feed');
      return http.Response(articleBody, 200);
    });
    addTearDown(client.close);
    final source = ArticlesRemoteDataSource(
      client: client,
      cache: CachedApiService(prefs),
    );
    expect(
      await source.getArticles(),
      hasLength(ArticlesRemoteDataSource.feedCount - 1),
    );
    expect(count, ArticlesRemoteDataSource.feedCount);
  });

  test(
    'YouTube 403 preserves quota exception without caching response',
    () async {
      statusCode = 403;
      await expectLater(
        unwrap(repository.getIslamicVideos('query')),
        throwsA(isA<QuotaExceededException>()),
      );
      expect(prefs.getKeys(), isEmpty);
    },
  );
}

/// Returns the value or throws the friendly MediaException the repository
/// carries as the failure's cause, matching the original expectations.
Future<List<T>> unwrap<T>(Future<Result<List<T>>> result) async =>
    switch (await result) {
      Success(:final value) => value,
      Err(:final failure) => throw failure.cause ?? failure,
    };
