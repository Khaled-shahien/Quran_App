import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The bundled Quran (`assets/quran_master.json`, 114 surahs with their
/// ayahs), decoded once per process and shared by every reader of it.
///
/// The file is about 2.7 MB, so it is decoded off the UI isolate. Callers
/// must treat the returned maps as read-only and copy before changing.
abstract final class QuranMasterAsset {
  static const String path = 'assets/quran_master.json';

  static List<Map<String, dynamic>>? _decoded;
  static Future<List<Map<String, dynamic>>>? _loading;
  static Zone? _loadingZone;

  /// The surahs in file order. A failed load is not kept, so the next call
  /// tries again.
  static Future<List<Map<String, dynamic>>> load({AssetBundle? bundle}) {
    final decoded = _decoded;
    if (decoded != null) return Future.value(decoded);
    // Share a load already under way, but only within the zone that started
    // it: a future begun in another (e.g. finished test) zone may never
    // complete here.
    if (_loading != null && identical(_loadingZone, Zone.current)) {
      return _loading!;
    }
    _loadingZone = Zone.current;
    return _loading = _decode(bundle ?? rootBundle).then(
      (surahs) => _decoded = surahs,
      onError: (Object error, StackTrace stack) {
        _loading = null;
        return Future<List<Map<String, dynamic>>>.error(error, stack);
      },
    );
  }

  @visibleForTesting
  static void resetForTesting() {
    _decoded = null;
    _loading = null;
    _loadingZone = null;
  }

  static Future<List<Map<String, dynamic>>> _decode(AssetBundle bundle) async {
    // `cache: false`: the decoded result is kept here instead, so the
    // 2.7 MB string is not held twice.
    final String raw = await bundle.loadString(path, cache: false);
    return _inBackground ? Isolate.run(() => parse(raw)) : parse(raw);
  }

  /// A real isolate never completes inside a widget test's fake clock, and
  /// the web has no isolates; both decode inline.
  static bool get _inBackground =>
      !kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST');

  /// Decodes and checks the shape of the file.
  @visibleForTesting
  static List<Map<String, dynamic>> parse(String raw) {
    final Object? decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Quran data must be a list of surahs');
    }
    final surahs = <Map<String, dynamic>>[
      for (final Object? item in decoded)
        if (item is Map<String, dynamic>)
          item
        else
          throw const FormatException('Each surah must be an object'),
    ];
    if (surahs.length != 114) {
      throw FormatException('Expected 114 surahs, found ${surahs.length}');
    }
    return List<Map<String, dynamic>>.unmodifiable(surahs);
  }
}
