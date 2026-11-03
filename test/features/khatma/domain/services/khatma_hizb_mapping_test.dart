import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/khatma/domain/models/khatma_model.dart';
import 'package:sakina_app/features/khatma/domain/services/khatma_quran_locator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The plan counts 60 hizb of four quarters each. These starts come from the
  // hizbQuarter values in the bundled assets/quran_master.json.
  for (final (hizb, surah, ayah) in [
    (1, 1, 1),
    (2, 2, 75),
    (3, 2, 142),
    (60, 87, 1),
  ]) {
    test('hizb $hizb starts at $surah:$ayah', () async {
      final position = await KhatmaQuranLocator().resolveStartPosition(
        trackingUnit: KhatmaTrackingUnit.hizb,
        unitIndex: hizb,
      );
      expect((position.surahNumber, position.ayahNumber), (surah, ayah));
    });
  }
}
