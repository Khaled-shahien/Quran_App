import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/khatma/domain/models/khatma_model.dart';
import 'package:sakina_app/features/khatma/domain/services/khatma_quran_locator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resolvePositionsForUnitRange returns complete Juz ranges', () async {
    final KhatmaQuranLocator locator = KhatmaQuranLocator();

    final List<KhatmaAyahPosition> juz1 = await locator
        .resolvePositionsForUnitRange(
          trackingUnit: KhatmaTrackingUnit.juz,
          fromUnit: 1,
          toUnit: 1,
        );
    expect(juz1, hasLength(148));
    expect(juz1.first.surahNumber, 1);
    expect(juz1.first.ayahNumber, 1);
    expect(juz1.last.surahNumber, 2);
    expect(juz1.last.ayahNumber, 141);
    expect(
      juz1.any((ayah) => ayah.surahNumber == 2 && ayah.ayahNumber == 1),
      isTrue,
    );

    final List<KhatmaAyahPosition> juz2 = await locator
        .resolvePositionsForUnitRange(
          trackingUnit: KhatmaTrackingUnit.juz,
          fromUnit: 2,
          toUnit: 2,
        );
    expect(juz2.first.surahNumber, 2);
    expect(juz2.first.ayahNumber, 142);
    expect(juz2.last.surahNumber, 2);
    expect(juz2.last.ayahNumber, 252);

    final List<KhatmaAyahPosition> juz30 = await locator
        .resolvePositionsForUnitRange(
          trackingUnit: KhatmaTrackingUnit.juz,
          fromUnit: 30,
          toUnit: 30,
        );
    expect(juz30.first.surahNumber, 78);
    expect(juz30.first.ayahNumber, 1);
    expect(juz30.last.surahNumber, 114);
    expect(juz30.last.ayahNumber, 6);
  });
}
