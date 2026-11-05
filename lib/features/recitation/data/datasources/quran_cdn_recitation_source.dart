import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/recitation.dart';

/// HTTP error from the recitation service.
class RecitationHttpException implements Exception {
  const RecitationHttpException(this.statusCode, this.uri);
  final int statusCode;
  final Uri uri;
  @override
  String toString() => 'RecitationHttpException($statusCode, $uri)';
}

/// Reads per-surah audio and ayah timings from the Quran.com API.
///
/// Only the verified reciters bundled with the app are ever requested.
class QuranCdnRecitationSource {
  QuranCdnRecitationSource({required http.Client client}) : _client = client;

  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 20);

  static Uri chapterUri(int reciterId, int surah) => Uri.https(
    'api.quran.com',
    '/api/v4/chapter_recitations/$reciterId/$surah',
    const {'segments': 'true'},
  );

  Future<ChapterRecitation> fetchChapter(int reciterId, int surah) async {
    final uri = chapterUri(reciterId, surah);
    final response = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw RecitationHttpException(response.statusCode, uri);
    }
    return parseChapter(reciterId, surah, response.body);
  }

  /// Parses the API payload; throws [FormatException] when timings are
  /// missing, out of order or belong to another surah.
  static ChapterRecitation parseChapter(int reciterId, int surah, String body) {
    final decoded = jsonDecode(body);
    final audio = decoded is Map ? decoded['audio_file'] : null;
    if (audio is! Map) throw const FormatException('Missing audio_file');
    final url = audio['audio_url'];
    final rawTimings = audio['timestamps'];
    if (url is! String || !url.startsWith('https://')) {
      throw const FormatException('Missing or insecure audio_url');
    }
    if (rawTimings is! List || rawTimings.isEmpty) {
      throw const FormatException('Missing ayah timings');
    }
    final timings = <AyahTiming>[];
    for (final t in rawTimings) {
      if (t is! Map) throw const FormatException('Bad timing entry');
      final key = t['verse_key'];
      final from = t['timestamp_from'];
      final to = t['timestamp_to'];
      final parts = key is String ? key.split(':') : const <String>[];
      final keySurah = parts.length == 2 ? int.tryParse(parts[0]) : null;
      final ayah = parts.length == 2 ? int.tryParse(parts[1]) : null;
      if (keySurah != surah || ayah == null || from is! num || to is! num) {
        throw FormatException('Bad timing for $key');
      }
      if (timings.isNotEmpty && ayah != timings.last.ayah + 1) {
        throw FormatException('Ayah timings out of order at $key');
      }
      timings.add(
        AyahTiming(
          ayah: ayah,
          from: Duration(milliseconds: from.round()),
          to: Duration(milliseconds: to.round()),
        ),
      );
    }
    if (timings.first.ayah != 1) {
      throw const FormatException('Timings do not start at ayah 1');
    }
    return ChapterRecitation(
      reciterId: reciterId,
      surah: surah,
      audioUrl: url,
      timings: timings,
    );
  }

  /// Size of the audio file in bytes (from the server's headers).
  Future<int> fileSize(String url) async {
    final response = await _client.head(Uri.parse(url)).timeout(_timeout);
    final length = int.tryParse(response.headers['content-length'] ?? '');
    if (response.statusCode != 200 || length == null) {
      throw RecitationHttpException(response.statusCode, Uri.parse(url));
    }
    return length;
  }

  /// Streams the audio file's bytes.
  Future<http.StreamedResponse> openStream(String url) async {
    final response = await _client
        .send(http.Request('GET', Uri.parse(url)))
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw RecitationHttpException(response.statusCode, Uri.parse(url));
    }
    return response;
  }

  /// Serializes a chapter so a downloaded surah also works offline.
  static String encodeChapter(ChapterRecitation c) => jsonEncode({
    'audio_file': {
      'audio_url': c.audioUrl,
      'timestamps': [
        for (final t in c.timings)
          {
            'verse_key': '${c.surah}:${t.ayah}',
            'timestamp_from': t.from.inMilliseconds,
            'timestamp_to': t.to.inMilliseconds,
          },
      ],
    },
  });
}
