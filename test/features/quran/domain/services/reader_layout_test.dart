import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/quran/domain/services/reader_layout.dart';

void main() {
  test('layout names round-trip and unknown values fall back', () {
    for (final layout in ReaderLayout.values) {
      expect(ReaderLayout.parse(layout.name), layout);
    }
    expect(ReaderLayout.parse(null), ReaderLayout.continuous);
    expect(ReaderLayout.parse('book'), ReaderLayout.continuous);
    expect(ReaderLayout.parse(3), ReaderLayout.continuous);
  });

  test('verse numbers use Arabic-Indic digits', () {
    expect(toArabicIndicDigits(0).runes.single, 0x0660);
    expect(toArabicIndicDigits(7).runes.single, 0x0667);
    expect(toArabicIndicDigits(286).runes.toList(), [0x0662, 0x0668, 0x0666]);
  });

  test('the ayah marker is the end-of-ayah sign then the number', () {
    final marker = ayahEndMarker(12).runes.toList();
    expect(marker, [0x06DD, 0x0661, 0x0662]);
  });

  group('old bookmarks', () {
    // Ten verses of 200 characters: the old reader closed a page at 550,
    // so pages held verses 1-3, 4-6, 7-9 and 10.
    final verses = <LegacyVerse>[
      for (var ayah = 1; ayah <= 10; ayah++)
        (ayah: ayah, length: 200, basmala: false),
    ];

    test('a page index maps to the first verse of that old page', () {
      int? lead(int page) =>
          legacyPageLeadAyah(verses: verses, pageIndex: page, basmalaLength: 0);
      expect(lead(0), 1);
      expect(lead(1), 4);
      expect(lead(2), 7);
      expect(lead(3), 10);
    });

    test('an index past the end or negative gives nothing', () {
      expect(
        legacyPageLeadAyah(verses: verses, pageIndex: 4, basmalaLength: 0),
        isNull,
      );
      expect(
        legacyPageLeadAyah(verses: verses, pageIndex: -1, basmalaLength: 0),
        isNull,
      );
    });

    test('the basmala header counted towards the first page', () {
      final withBasmala = <LegacyVerse>[
        (ayah: 1, length: 200, basmala: true),
        (ayah: 2, length: 200, basmala: false),
        (ayah: 3, length: 200, basmala: false),
      ];
      // 200 + 150 + 200 reaches 550 after verse 2, so verse 3 starts page 1.
      expect(
        legacyPageLeadAyah(
          verses: withBasmala,
          pageIndex: 1,
          basmalaLength: 150,
        ),
        3,
      );
    });
  });
}
