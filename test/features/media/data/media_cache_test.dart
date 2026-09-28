import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sakina_app/core/services/cached_api_service.dart';
import 'package:sakina_app/features/media/data/datasources/articles_remote_datasource.dart';
import 'package:sakina_app/features/media/data/datasources/audio_remote_datasource.dart';
import 'package:sakina_app/features/media/data/datasources/video_remote_datasource.dart';
import 'package:sakina_app/features/media/data/repositories/media_repository_impl.dart';
import 'package:sakina_app/features/media/domain/errors/media_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';

const articleBody =
    '<rss><channel><item><title>Article</title>'
    '<link>https://example.com/article</link>'
    '<pubDate>2026-09-28T10:00:00Z</pubDate></item></channel></rss>';
const audioBody =
    '{"reciters":[{"id":1,"name":"Reciter","moshaf":'
    '[{"server":"https://example.com/","surah_list":"1,2","name":"Reading"}]}]}';
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
          : request.url.host == 'mp3quran.net'
          ? (empty ? '{"reciters":[]}' : audioBody)
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
      audioDataSource: AudioRemoteDataSource(client: client, cache: cache),
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

  for (final kind in ['articles', 'audio', 'video']) {
    Future<List<Object>> load() async => switch (kind) {
      'articles' => repository.getArticles(),
      'audio' => repository.getReciters(),
      _ => repository.getIslamicVideos('query'),
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
    await repository.getIslamicVideos('query');
    final before = requests;
    repository = createRepository(apiKey: '');
    offline = true;
    expect(await repository.getIslamicVideos('query'), hasLength(1));
    expect(requests, before);
    await expectLater(
      repository.getIslamicVideos('other query'),
      throwsA(isA<MissingApiKeyException>()),
    );
  });

  test('video cache is query-specific', () async {
    await repository.getIslamicVideos('query');
    offline = true;
    await expectLater(
      repository.getIslamicVideos('another query'),
      throwsA(isA<MediaException>()),
    );
    expect(await repository.getIslamicVideos('query'), hasLength(1));
  });

  test('cached reciter generates audio URLs without HTTP', () async {
    await repository.getReciters();
    offline = true;
    final before = requests;
    final reciters = await repository.getReciters();
    final audios = await repository.getSurahAudios(reciters.single);
    expect(audios, hasLength(2));
    expect(audios.first.audioUrl, 'https://example.com/001.mp3');
    expect(requests, before);
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
        repository.getIslamicVideos('query'),
        throwsA(isA<QuotaExceededException>()),
      );
      expect(prefs.getKeys(), isEmpty);
    },
  );
}
