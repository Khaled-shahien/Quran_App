import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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

      final repository = DuasRepositoryImpl();
      final result = await repository.getAllDuas();

      expect(result, hasLength(1));
      expect(result.first.category, 'أدعية قرآنية');
      expect(result.first.items, hasLength(1));
      expect(result.first.items.first.title, 'دعاء');
    });

    test('throws wrapped exception on malformed JSON', () async {
      await evictAssetCache();
      await mockAssets({'assets/quran_duas.json': '{not-json'});

      final repository = DuasRepositoryImpl();

      expect(
        repository.getAllDuas,
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to load duas data'),
          ),
        ),
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

      final repository = AzkarRepositoryImpl();
      final result = await repository.getAllAzkar();

      expect(result, hasLength(1));
      expect(result.first.category, 'أذكار الصباح');
      expect(result.first.items.first.repeat, 3);
    });

    test('throws wrapped exception when asset is missing', () async {
      await evictAssetCache();
      await mockAssets(const <String, String>{});

      final repository = AzkarRepositoryImpl();

      expect(
        repository.getAllAzkar,
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to load azkar data'),
          ),
        ),
      );
    });
  });
}
