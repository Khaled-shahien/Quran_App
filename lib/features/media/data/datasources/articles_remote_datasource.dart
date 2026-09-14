import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sakina_app/core/services/cached_api_service.dart';
import 'package:sakina_app/features/media/data/models/article_model.dart';
import 'package:sakina_app/features/media/domain/errors/media_exception.dart';

class ArticlesRemoteDataSource {
  ArticlesRemoteDataSource({
    required http.Client client,
    required CachedApiService cache,
  }) : _client = client,
       _cache = cache;

  final http.Client _client;
  final CachedApiService _cache;

  static int get feedCount => _feeds.length;

  static const List<_RssFeed> _feeds = <_RssFeed>[
    _RssFeed(
      name: 'إسلام ويب',
      url: 'https://islamweb.net/ar/rss/articles.xml',
      category: 'مقالات إسلامية',
    ),
    _RssFeed(
      name: 'طريق الإسلام',
      url: 'https://ar.islamway.net/feed/articles',
      category: 'مقالات ودروس',
    ),
    _RssFeed(
      name: 'الألوكة الشرعية',
      url: 'https://www.alukah.net/sharia/rss/',
      category: 'فقه وعلوم شرعية',
    ),
    _RssFeed(
      name: 'صيد الفوائد',
      url: 'https://www.saaid.net/rss.xml',
      category: 'فوائد ومقالات',
    ),
  ];

  Future<List<ArticleModel>> getArticles() async {
    final articles = <ArticleModel>[];
    Object? lastError;
    var successfulFeeds = 0;

    for (final feed in _feeds) {
      try {
        final body = await _getFeedBody(feed);
        if (body == null || body.trim().isEmpty) continue;

        final parsed = _parseRss(body, feed);
        articles.addAll(parsed);
        successfulFeeds++;
      } catch (error) {
        lastError = error;
        debugPrint('RSS feed failed (${feed.name}): $error');
      }
    }

    if (successfulFeeds == 0 && articles.isEmpty && lastError != null) {
      if (lastError is MediaException) throw lastError;
      throw const MediaException(
        'تعذر تحميل المقالات، تحقق من اتصالك بالإنترنت',
      );
    }

    articles.sort((a, b) => b.pubDate.compareTo(a.pubDate));
    return articles;
  }

  Future<String?> _getFeedBody(_RssFeed feed) async {
    final cacheKey = 'media_rss_${Uri.encodeComponent(feed.url)}';
    final cached = await _cache.getCached(cacheKey);
    if (cached != null) return cached;

    final response = await _client
        .get(
          Uri.parse(feed.url),
          headers: const <String, String>{
            'Accept': 'application/rss+xml, application/xml, text/xml',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw MediaException('تعذر تحميل ${feed.name} (${response.statusCode})');
    }

    await _cache.cache(cacheKey, response.body);
    return response.body;
  }

  List<ArticleModel> _parseRss(String xml, _RssFeed feed) {
    final itemRegex = RegExp(
      r'<item\b[^>]*>(.*?)</item>',
      dotAll: true,
      caseSensitive: false,
    );

    return itemRegex
        .allMatches(xml)
        .take(10)
        .map((match) {
          final itemXml = match.group(1) ?? '';
          final title = _decodeXml(_extractTag(itemXml, 'title'));
          final description = _stripHtml(
            _decodeXml(_extractTag(itemXml, 'description')),
          );
          final link = _decodeXml(_extractTag(itemXml, 'link'));
          final pubDate = _parseDate(_extractTag(itemXml, 'pubDate'));

          return ArticleModel.fromRssItem(
            title: title,
            description: description,
            link: link,
            pubDate: pubDate,
            sourceName: feed.name,
            category: feed.category,
          );
        })
        .where((article) => article.title.isNotEmpty && article.link.isNotEmpty)
        .toList(growable: false);
  }

  String _extractTag(String xml, String tag) {
    final match = RegExp(
      '<$tag\\b[^>]*>(.*?)</$tag>',
      dotAll: true,
      caseSensitive: false,
    ).firstMatch(xml);

    return _unwrapCdata(match?.group(1)?.trim() ?? '');
  }

  String _unwrapCdata(String value) {
    return value
        .replaceFirst(RegExp(r'^<!\[CDATA\[', caseSensitive: false), '')
        .replaceFirst(RegExp(r'\]\]>$'), '')
        .trim();
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _decodeXml(String value) {
    return value
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
          final code = int.tryParse(match.group(1) ?? '');
          return code == null ? match.group(0)! : String.fromCharCode(code);
        })
        .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
          final code = int.tryParse(match.group(1) ?? '', radix: 16);
          return code == null ? match.group(0)! : String.fromCharCode(code);
        })
        .trim();
  }

  DateTime _parseDate(String value) {
    if (value.trim().isEmpty) return DateTime.now();

    final isoDate = DateTime.tryParse(value);
    if (isoDate != null) return isoDate;

    try {
      return HttpDate.parse(value);
    } on FormatException {
      return DateTime.now();
    }
  }
}

class _RssFeed {
  const _RssFeed({
    required this.name,
    required this.url,
    required this.category,
  });

  final String name;
  final String url;
  final String category;
}
