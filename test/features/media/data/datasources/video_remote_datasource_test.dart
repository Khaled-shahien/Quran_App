import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sakina_app/core/services/cached_api_service.dart';
import 'package:sakina_app/features/media/data/datasources/video_remote_datasource.dart';
import 'package:sakina_app/features/media/domain/errors/media_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Built at runtime so this test file does not itself match the scanner.
  final fakeKey =
      'AI'
      'za${'x' * 35}';
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  VideoRemoteDataSource dataSource(
    MockClientHandler handler, {
    String? apiKey,
  }) => VideoRemoteDataSource(
    client: MockClient(handler),
    cache: CachedApiService(prefs),
    apiKey: apiKey ?? fakeKey,
  );

  test('sends the key as a header and never in the URL', () async {
    late http.BaseRequest sent;
    await dataSource((request) async {
      sent = request;
      return http.Response('{"items":[]}', 200);
    }).searchVideos('quran');

    expect(sent.headers['X-Goog-Api-Key'], fakeKey);
    expect(sent.url.queryParameters, isNot(contains('key')));
    expect(sent.url.toString(), isNot(contains(fakeKey)));
  });

  test('a connection failure does not expose the key', () async {
    Object? failure;
    try {
      await dataSource(
        (request) => throw http.ClientException('closed', request.url),
      ).searchVideos('quran');
    } catch (error) {
      failure = error;
    }

    expect(failure, isNotNull);
    expect(failure.toString(), isNot(contains(fakeKey)));
  });

  test('cached data and its keys do not contain the key', () async {
    await dataSource(
      (_) async => http.Response('{"items":[]}', 200),
    ).searchVideos('quran');

    expect(prefs.getKeys(), isNotEmpty);
    for (final key in prefs.getKeys()) {
      expect(key, isNot(contains(fakeKey)));
      expect(prefs.get(key).toString(), isNot(contains(fakeKey)));
    }
  });

  test('a missing key fails before any request is made', () async {
    var requests = 0;
    for (final emptyKey in ['', '   ']) {
      await expectLater(
        dataSource((_) async {
          requests++;
          return http.Response('{"items":[]}', 200);
        }, apiKey: emptyKey).searchVideos('quran'),
        throwsA(isA<MissingApiKeyException>()),
      );
    }
    expect(requests, 0);
  });
}
