import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sakina_app/core/services/cached_api_service.dart';
import 'package:sakina_app/features/media/data/datasources/articles_remote_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  test('accepts RSS dates with numeric offsets', () async {
    final client = MockClient(
      (_) async => http.Response.bytes(
        utf8.encode('''
<rss><channel><item>
  <title>a</title><link>https://example.com/a</link>
  <pubDate>Mon, 01 Jul 2024 10:00:00 +0300</pubDate>
</item></channel></rss>'''),
        200,
      ),
    );

    final articles = await ArticlesRemoteDataSource(
      client: client,
      cache: CachedApiService(prefs),
    ).getArticles();

    expect(articles, isNotEmpty);
    expect(articles.first.pubDate, DateTime.utc(2024, 7, 1, 7));
  });

  test('loads and parses RSS articles from available feeds', () async {
    final client = MockClient((request) async {
      const body = '''
        <rss>
          <channel>
            <item>
              <title><![CDATA[عنوان مقال]]></title>
              <description><![CDATA[<p>وصف &amp; مختصر</p>]]></description>
              <link>https://example.com/article</link>
              <pubDate>Mon, 01 Jul 2024 10:00:00 GMT</pubDate>
            </item>
          </channel>
        </rss>
        ''';

      return http.Response.bytes(
        utf8.encode(body),
        200,
        headers: const <String, String>{
          'content-type': 'application/rss+xml; charset=utf-8',
        },
      );
    });

    final dataSource = ArticlesRemoteDataSource(
      client: client,
      cache: CachedApiService(prefs),
    );

    final articles = await dataSource.getArticles();

    expect(articles, hasLength(ArticlesRemoteDataSource.feedCount));
    expect(articles.first.title, 'عنوان مقال');
    expect(articles.first.description, 'وصف & مختصر');
    expect(articles.first.link, 'https://example.com/article');
  });
}
