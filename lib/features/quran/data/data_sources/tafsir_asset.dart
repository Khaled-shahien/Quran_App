import 'dart:async';
import 'dart:io' show Platform;
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Al-Tafsir al-Muyassar (King Fahd Glorious Quran Printing Complex), as
/// distributed by Tanzil.net (`ar.muyassar`), bundled unchanged: one line
/// per ayah, `surah|ayah|text`, followed by Tanzil's own header comment.
///
/// About 2.5 MB, so it is parsed off the UI isolate, once per process,
/// and only when the first tafsir is opened.
abstract final class TafsirAsset {
  static const String path = 'assets/tafsir/ar.muyassar.txt';

  static Map<int, List<String>>? _parsed;
  static Future<Map<int, List<String>>>? _loading;
  static Zone? _loadingZone;

  /// The tafsir of [surah]:[ayah], or null if the file has none for it.
  static Future<String?> of(int surah, int ayah, {AssetBundle? bundle}) async {
    final Map<int, List<String>> all = await load(bundle: bundle);
    final List<String>? ayahs = all[surah];
    if (ayahs == null || ayah < 1 || ayah > ayahs.length) return null;
    final String text = ayahs[ayah - 1];
    return text.isEmpty ? null : text;
  }

  /// Every surah's tafsir by ayah. A failed load is not kept.
  static Future<Map<int, List<String>>> load({AssetBundle? bundle}) {
    final parsed = _parsed;
    if (parsed != null) return Future.value(parsed);
    if (_loading != null && identical(_loadingZone, Zone.current)) {
      return _loading!;
    }
    _loadingZone = Zone.current;
    return _loading = _read(bundle ?? rootBundle).then(
      (value) => _parsed = value,
      onError: (Object error, StackTrace stack) {
        _loading = null;
        return Future<Map<int, List<String>>>.error(error, stack);
      },
    );
  }

  @visibleForTesting
  static void resetForTesting() {
    _parsed = null;
    _loading = null;
    _loadingZone = null;
  }

  static Future<Map<int, List<String>>> _read(AssetBundle bundle) async {
    final String raw = await bundle.loadString(path, cache: false);
    final bool background =
        !kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST');
    return background ? Isolate.run(() => parse(raw)) : parse(raw);
  }

  /// Parses the Tanzil text format; rejects a file whose ayahs are out of
  /// order or missing, so a damaged asset is never half-shown.
  @visibleForTesting
  static Map<int, List<String>> parse(String raw) {
    final Map<int, List<String>> result = {};
    for (final String line in raw.split('\n')) {
      if (line.isEmpty || line.startsWith('#')) continue;
      final int first = line.indexOf('|');
      final int second = first < 0 ? -1 : line.indexOf('|', first + 1);
      if (second < 0) throw FormatException('Bad tafsir line', line);
      final int? surah = int.tryParse(line.substring(0, first));
      final int? ayah = int.tryParse(line.substring(first + 1, second));
      if (surah == null || ayah == null || surah < 1 || surah > 114) {
        throw FormatException('Bad tafsir reference', line);
      }
      final List<String> ayahs = result.putIfAbsent(surah, () => []);
      if (ayah != ayahs.length + 1) {
        throw FormatException('Tafsir ayahs out of order at $surah:$ayah');
      }
      ayahs.add(line.substring(second + 1).trim());
    }
    if (result.length != 114) {
      throw FormatException('Expected 114 surahs, found ${result.length}');
    }
    return Map.unmodifiable(result);
  }
}
