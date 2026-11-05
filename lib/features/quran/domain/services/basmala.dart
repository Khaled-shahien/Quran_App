/// The bundled Uthmani text (Tanzil) puts the basmala at the start of the
/// first ayah of every surah except Al-Fatiha (where it is ayah 1 itself) and
/// At-Tawbah (which has none). The reader shows it as an unnumbered header
/// instead, so it is split off here without changing a single character.
library;

/// The basmala exactly as in Al-Fatiha 1:1 of the bundled text, built from
/// code points because editors and keyboards may reorder Arabic marks.
final String uthmaniBasmala = String.fromCharCodes(const <int>[
  0x0628,
  0x0650,
  0x0633,
  0x0652,
  0x0645,
  0x0650,
  0x0020,
  0x0671,
  0x0644,
  0x0644,
  0x0651,
  0x064E,
  0x0647,
  0x0650,
  0x0020,
  0x0671,
  0x0644,
  0x0631,
  0x0651,
  0x064E,
  0x062D,
  0x0652,
  0x0645,
  0x064E,
  0x0670,
  0x0646,
  0x0650,
  0x0020,
  0x0671,
  0x0644,
  0x0631,
  0x0651,
  0x064E,
  0x062D,
  0x0650,
  0x064A,
  0x0645,
  0x0650,
]);

/// Al-Tin (95) and Al-Qadr (97) carry a shadda on the first letter in the
/// source, from joining with the previous surah. The header still uses
/// [uthmaniBasmala]; this form only matters for splitting.
final String _joinedBasmala = String.fromCharCodes(const <int>[
  0x0628,
  0x0651,
  0x0650,
  0x0633,
  0x0652,
  0x0645,
  0x0650,
  0x0020,
  0x0671,
  0x0644,
  0x0644,
  0x0651,
  0x064E,
  0x0647,
  0x0650,
  0x0020,
  0x0671,
  0x0644,
  0x0631,
  0x0651,
  0x064E,
  0x062D,
  0x0652,
  0x0645,
  0x064E,
  0x0670,
  0x0646,
  0x0650,
  0x0020,
  0x0671,
  0x0644,
  0x0631,
  0x0651,
  0x064E,
  0x062D,
  0x0650,
  0x064A,
  0x0645,
  0x0650,
]);

const int _fatiha = 1;
const int _tawbah = 9;

class BasmalaSplit {
  const BasmalaSplit({required this.hasBasmala, required this.ayahText});

  /// Whether a basmala header should be shown before this ayah.
  final bool hasBasmala;

  /// The ayah text to display after the header (unchanged when no split).
  final String ayahText;
}

/// Splits a leading basmala off ayah 1 of surahs 2–114 except 9.
///
/// Only an exact match of the known source forms followed by a space is
/// split, so the remaining text is always the original minus that prefix.
BasmalaSplit splitLeadingBasmala({
  required int surahNumber,
  required int ayahNumber,
  required String text,
}) {
  if (ayahNumber != 1 || surahNumber == _fatiha || surahNumber == _tawbah) {
    return BasmalaSplit(hasBasmala: false, ayahText: text);
  }
  for (final prefix in [uthmaniBasmala, _joinedBasmala]) {
    final withSpace = '$prefix ';
    if (text.startsWith(withSpace) && text.length > withSpace.length) {
      return BasmalaSplit(
        hasBasmala: true,
        ayahText: text.substring(withSpace.length),
      );
    }
  }
  return BasmalaSplit(hasBasmala: false, ayahText: text);
}
