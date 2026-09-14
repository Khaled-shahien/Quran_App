import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/media/data/models/reciter_model.dart';

void main() {
  group('ReciterModel', () {
    test('parses first usable moshaf and builds padded audio URLs', () {
      final reciter = ReciterModel.fromJson(<String, dynamic>{
        'id': 1,
        'name': 'عبد الباسط عبد الصمد',
        'moshaf': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'رواية حفص عن عاصم',
            'server': 'https://server8.mp3quran.net/basit/',
            'surah_list': '1,2,114',
          },
        ],
      });

      expect(reciter.id, 1);
      expect(reciter.name, 'عبد الباسط عبد الصمد');
      expect(reciter.hasSurah(2), isTrue);
      expect(reciter.hasSurah(3), isFalse);
      expect(
        reciter.getAudioUrl(1),
        'https://server8.mp3quran.net/basit/001.mp3',
      );
      expect(
        reciter.getAudioUrl(114),
        'https://server8.mp3quran.net/basit/114.mp3',
      );
    });
  });
}
