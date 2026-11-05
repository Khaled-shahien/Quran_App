/// Static educational content shown in the "دليل المسلم" screen.
library;

/// A reference to one or more consecutive verses of a single surah.
///
/// Quranic text is never duplicated in the guide asset; it is resolved from
/// the reviewed Quran asset at display time.
class QuranRef {
  const QuranRef({required this.surah, required this.from, required this.to});

  final int surah;
  final int from;
  final int to;

  @override
  bool operator ==(Object other) =>
      other is QuranRef &&
      other.surah == surah &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(surah, from, to);
}

/// One labelled piece of an item: prose, numbered steps, a dua text,
/// Quran references and an optional citation.
class GuideBlock {
  const GuideBlock({
    required this.label,
    this.text,
    this.dua,
    this.steps = const <String>[],
    this.quran = const <QuranRef>[],
    this.source,
  });

  final String label;
  final String? text;
  final String? dua;
  final List<String> steps;
  final List<QuranRef> quran;
  final String? source;
}

class GuideItem {
  const GuideItem({
    required this.title,
    required this.blocks,
    this.subtitle,
    this.badges = const <String>[],
  });

  final String title;
  final String? subtitle;
  final List<String> badges;
  final List<GuideBlock> blocks;
}

/// Known section ids, used for deep links into a tab.
abstract final class GuideSectionId {
  static const String prophets = 'prophets';
  static const String prayer = 'prayer';
  static const String specialPrayers = 'special_prayers';
  static const String pillars = 'pillars';
}

class GuideSection {
  const GuideSection({
    required this.id,
    required this.title,
    required this.items,
    this.intro,
  });

  final String id;
  final String title;
  final String? intro;
  final List<GuideItem> items;
}

/// A resolved verse ready for display.
class GuideVerse {
  const GuideVerse({
    required this.surah,
    required this.surahName,
    required this.ayah,
    required this.text,
  });

  final int surah;
  final String surahName;
  final int ayah;
  final String text;
}
