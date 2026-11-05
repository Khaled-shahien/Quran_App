import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/features/duas/data/repositories/azkar_repository.dart';
import 'package:sakina_app/features/duas/data/repositories/duas_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = 'flutter/assets';

  Future<void> mockAssets(Map<String, String> assets) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    messenger.setMockMessageHandler(channel, (message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      final value = assets[key];
      if (value == null) {
        return null;
      }
      final bytes = Uint8List.fromList(utf8.encode(value));
      return ByteData.view(bytes.buffer);
    });
  }

  Future<void> evictAssetCache() async {
    rootBundle.evict('assets/quran_duas.json');
    rootBundle.evict('assets/prayers_data.json');
  }

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler(channel, null);
  });

  group('DuasRepositoryImpl', () {
    test('returns parsed duas categories on success', () async {
      await evictAssetCache();
      await mockAssets({
        'assets/quran_duas.json':
            '[{"id":1,"category":"أدعية قرآنية","items":'
            '[{"id":10,"title":"دعاء","text":"نص","repeat":1,'
            '"reference":"مرجع"}]}]',
      });

      final result = await DuasRepositoryImpl().getAllDuas();

      final categories = result.valueOrNull!;
      expect(categories, hasLength(1));
      expect(categories.first.category, 'أدعية قرآنية');
      expect(categories.first.items, hasLength(1));
      expect(categories.first.items.first.title, 'دعاء');
    });

    test('returns a ContentFailure on malformed JSON', () async {
      await evictAssetCache();
      await mockAssets({'assets/quran_duas.json': '{not-json'});

      final result = await DuasRepositoryImpl().getAllDuas();

      expect(result.failureOrNull, isA<ContentFailure>());
      expect(
        result.failureOrNull!.cause,
        isA<FormatException>(),
        reason: 'the technical cause is kept for logging',
      );
    });
  });

  group('AzkarRepositoryImpl', () {
    test('returns parsed azkar categories on success', () async {
      await evictAssetCache();
      await mockAssets({
        'assets/prayers_data.json':
            '[{"id":2,"category":"أذكار الصباح","items":'
            '[{"id":11,"title":"ذكر","text":"نص الذكر",'
            '"repeat":3,"reference":"مرجع"}]}]',
      });

      final result = await AzkarRepositoryImpl().getAllAzkar();

      final categories = result.valueOrNull!;
      expect(categories, hasLength(1));
      expect(categories.first.category, 'أذكار الصباح');
      expect(categories.first.items.first.repeat, 3);
    });

    test('keeps dhikr text and reference byte-for-byte', () async {
      const text = ' بِسْمِ اللَّهِ… ﴿١﴾ ';
      const reference = ' رواه مسلم ';
      await evictAssetCache();
      await mockAssets({
        'assets/prayers_data.json': jsonEncode([
          {
            'id': 1,
            'category': 'أذكار الصباح',
            'items': [
              {
                'id': 1,
                'title': 'ذكر',
                'text': text,
                'repeat': 33,
                'reference': reference,
              },
            ],
          },
        ]),
      });

      final result = await AzkarRepositoryImpl().getAllAzkar();

      final item = result.valueOrNull!.single.items.single;
      expect(item.text, text);
      expect(item.reference, reference);
      expect(item.repeat, 33);
    });

    test('returns a ContentFailure when the asset is missing', () async {
      await evictAssetCache();
      await mockAssets(const <String, String>{});

      final result = await AzkarRepositoryImpl().getAllAzkar();

      expect(result.failureOrNull, isA<ContentFailure>());
    });
  });
}
