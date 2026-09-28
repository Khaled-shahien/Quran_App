import 'package:sakina_app/l10n/localization.dart';
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sakina_app/core/services/cached_api_service.dart';
import 'package:sakina_app/features/media/data/models/video_model.dart';
import 'package:sakina_app/features/media/domain/errors/media_exception.dart';

class VideoRemoteDataSource {
  VideoRemoteDataSource({
    required http.Client client,
    required CachedApiService cache,
    required String apiKey,
  }) : _client = client,
       _cache = cache,
       _apiKey = apiKey;

  final http.Client _client;
  final CachedApiService _cache;
  final String _apiKey;

  Future<List<VideoModel>> searchVideos(String query) async {
    if (_apiKey.trim().isEmpty) {
      throw MissingApiKeyException(appL10n.videoRemoteDatasourceMessage1);
    }

    final cacheKey = 'media_youtube_${Uri.encodeComponent(query)}';
    final cached = await _cache.getCached(cacheKey);
    if (cached != null) {
      return _parseVideos(cached);
    }

    final uri =
        Uri.https('www.googleapis.com', '/youtube/v3/search', <String, String>{
          'part': 'snippet',
          'q': query,
          'type': 'video',
          'maxResults': '20',
          'relevanceLanguage': 'ar',
          'safeSearch': 'strict',
          'key': _apiKey,
        });

    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 403) {
      throw QuotaExceededException(appL10n.videoRemoteDatasourceMessage2);
    }

    if (response.statusCode != 200) {
      throw MediaException(
        appL10n.videoRemoteDatasourceMessage3((response.statusCode).toString()),
      );
    }

    await _cache.cache(cacheKey, response.body);
    return _parseVideos(response.body);
  }

  List<VideoModel> _parseVideos(String responseBody) {
    final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    final items = decoded['items'] as List<dynamic>? ?? const [];

    return items
        .map((item) => VideoModel.fromJson(item as Map<String, dynamic>))
        .where((video) => video.videoId.isNotEmpty)
        .toList(growable: false);
  }
}
