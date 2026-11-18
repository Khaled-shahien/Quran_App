/// A hadith of the collection: its title, its text, and (when the study
/// source has it) the grade, who reported it, an explanation and its
/// lessons, all copied from that source.
class HadeathEntity {
  final String title;
  final List<String> content;
  final HadeathStudy? study;

  const HadeathEntity({required this.title, required this.content, this.study});
}

/// The study material for one hadith, from HadeethEnc.com.
class HadeathStudy {
  const HadeathStudy({
    required this.sourceId,
    required this.grade,
    required this.attribution,
    required this.explanation,
    required this.reference,
    this.hints = const [],
  });

  final String sourceId;
  final String grade;
  final String attribution;
  final String explanation;
  final String reference;
  final List<String> hints;

  /// The hadith's page on the source site.
  String get sourceUrl => 'https://hadeethenc.com/ar/browse/hadith/$sourceId';
}
