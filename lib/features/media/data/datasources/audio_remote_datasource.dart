import 'package:sakina_app/l10n/localization.dart';
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sakina_app/core/services/cached_api_service.dart';
import 'package:sakina_app/features/media/data/models/reciter_model.dart';
import 'package:sakina_app/features/media/domain/errors/media_exception.dart';

class AudioRemoteDataSource {
  AudioRemoteDataSource({
    required http.Client client,
    required CachedApiService cache,
  }) : _client = client,
       _cache = cache;

  final http.Client _client;
  final CachedApiService _cache;

  static const String _recitersUrl =
      'https://mp3quran.net/api/v3/reciters?language=ar';
  static const String _cacheKey = 'media_mp3quran_reciters_ar';

  Future<List<ReciterModel>> getReciters() async {
    final cached = await _cache.getParsed(_cacheKey, _parseReciters);
    if (cached != null) {
      return cached;
    }

    final response = await _client
        .get(Uri.parse(_recitersUrl))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw MediaException(
        appL10n.audioRemoteDatasourceMessage1((response.statusCode).toString()),
      );
    }

    final reciters = _parseReciters(response.body);
    await _cache.cache(_cacheKey, response.body);
    return reciters;
  }

  List<ReciterModel> _parseReciters(String responseBody) {
    final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    final reciters = decoded['reciters'];
    if (reciters is! List<dynamic>) {
      throw const FormatException('Missing reciters list');
    }

    return reciters
        .map((item) => ReciterModel.fromJson(item as Map<String, dynamic>))
        .where((reciter) => reciter.serverUrl.isNotEmpty)
        .toList(growable: false);
  }
}
