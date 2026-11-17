import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/quran/data/data_sources/local_surah_data_source.dart';
import 'package:sakina_app/features/quran/data/data_sources/quran_master_asset.dart';

/// One decode of the bundled Quran for the whole app (audit PERF-01), and no
/// silent built-in replacement when it is broken (audit ARCH-01).
class _Bundle extends CachingAssetBundle {
  _Bundle(this.content);
  String content;
  var loads = 0;

  @override
  Future<ByteData> load(String key) async {
    loads++;
    return ByteData.sublistView(utf8.encode(content));
  }
}

String _surahs(int count) => jsonEncode([
  for (var i = 1; i <= count; i++)
    {'number': i, 'name': 'س$i', 'ayahs': <Object>[]},
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(QuranMasterAsset.resetForTesting);
  tearDown(QuranMasterAsset.resetForTesting);

  test('the real asset has 114 surahs and 6,236 ayahs', () async {
    final surahs = await QuranMasterAsset.load();
    expect(surahs, hasLength(114));
    final ayahs = surahs.fold<int>(
      0,
      (sum, surah) => sum + (surah['ayahs'] as List).length,
    );
    expect(ayahs, 6236);
  });

  test('is read once and shared by every caller', () async {
    final bundle = _Bundle(_surahs(114));
    final first = await QuranMasterAsset.load(bundle: bundle);
    final second = await QuranMasterAsset.load(bundle: bundle);
    expect(identical(first, second), isTrue);
    expect(bundle.loads, 1);
  });

  test('concurrent first loads share one read', () async {
    final bundle = _Bundle(_surahs(114));
    await Future.wait([
      QuranMasterAsset.load(bundle: bundle),
      QuranMasterAsset.load(bundle: bundle),
    ]);
    expect(bundle.loads, 1);
  });

  test('the list cannot be changed by one caller for the others', () async {
    final surahs = await QuranMasterAsset.load(bundle: _Bundle(_surahs(114)));
    expect(() => surahs.removeLast(), throwsUnsupportedError);
  });

  test('a broken asset fails, and a later call tries again', () async {
    final bundle = _Bundle('{"not": "a list"}');
    await expectLater(
      QuranMasterAsset.load(bundle: bundle),
      throwsFormatException,
    );
    bundle.content = _surahs(114);
    expect(await QuranMasterAsset.load(bundle: bundle), hasLength(114));
  });

  test('a truncated Quran is rejected', () {
    expect(() => QuranMasterAsset.parse(_surahs(113)), throwsFormatException);
    expect(() => QuranMasterAsset.parse('[1]'), throwsFormatException);
  });

  test('surah metadata comes from the asset, never built-in data', () async {
    // Prime the shared cache with a failure: the data source must surface it.
    final bundle = _Bundle('[]');
    await expectLater(
      QuranMasterAsset.load(bundle: bundle),
      throwsFormatException,
    );
    QuranMasterAsset.resetForTesting();
    final surahs = await LocalSurahDataSource().loadAllSurahs();
    expect(surahs, hasLength(114));
    expect(surahs.first.ayahs, isNotEmpty, reason: 'real data, not a stub');
  });
}
