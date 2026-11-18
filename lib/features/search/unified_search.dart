import '../duas/data/hisn_almuslim.dart';
import '../hadeath/domain/entities/hadeath_entity.dart';
import '../islamic_guide/domain/entities/guide_entities.dart';
import '../quran/domain/entities/ayah_entity.dart';
import '../quran/domain/services/quran_search.dart';

/// The bundled sources one search box looks through, in the order shown.
enum SearchSource { quran, hisn, hadith, guide }

/// Where a hit opens.
sealed class SearchTarget {
  const SearchTarget();
}

final class QuranVerseTarget extends SearchTarget {
  const QuranVerseTarget(this.surah, this.ayah, this.page);
  final int surah;
  final int ayah;
  final int page;
}

final class HisnChapterTarget extends SearchTarget {
  const HisnChapterTarget(this.chapterId);
  final int chapterId;
}

final class HadithTarget extends SearchTarget {
  const HadithTarget(this.index, this.hadeath);
  final int index;
  final HadeathEntity hadeath;
}

final class GuideTarget extends SearchTarget {
  const GuideTarget(this.sectionId);
  final String sectionId;
}

/// One result: a title (the reference), a stretch of the original text
/// around the match, and the match within that stretch.
class SearchHit {
  const SearchHit({
    required this.source,
    required this.title,
    required this.snippet,
    required this.matchStart,
    required this.matchEnd,
    required this.target,
  });

  final SearchSource source;
  final String title;
  final String snippet;
  final int matchStart;
  final int matchEnd;
  final SearchTarget target;
}

class _Entry {
  _Entry(this.source, this.title, String text, this.target)
    : text = NormalizedText(text);

  final SearchSource source;
  final String title;
  final NormalizedText text;
  final SearchTarget target;
}

/// Searches the Quran, Hisn al-Muslim, the hadith and the guide together,
/// offline, with each source's own reference. Only bundled, verified texts
/// are searched; nothing is generated.
class UnifiedSearch {
  UnifiedSearch._(this._quran, this._entries, this._surahName);

  /// [surahName] names a surah for Quran results.
  factory UnifiedSearch.build({
    required Map<int, List<AyahEntity>> quran,
    required String Function(int surah) surahName,
    List<HisnChapter> hisn = const [],
    List<HadeathEntity> hadith = const [],
    List<GuideSection> guide = const [],
  }) {
    final entries = <_Entry>[
      for (final chapter in hisn)
        for (final entry in chapter.entries)
          _Entry(
            SearchSource.hisn,
            chapter.title,
            entry.text,
            HisnChapterTarget(chapter.id),
          ),
      for (final (i, h) in hadith.indexed)
        _Entry(
          SearchSource.hadith,
          h.title,
          '${h.content.join(' ')}\n${h.study?.explanation ?? ''}',
          HadithTarget(i, h),
        ),
      for (final section in guide)
        for (final item in section.items)
          _Entry(
            SearchSource.guide,
            item.title,
            [
              item.title,
              ?item.subtitle,
              for (final block in item.blocks) ...[
                block.label,
                ?block.text,
                ?block.dua,
                ...block.steps,
              ],
            ].join('\n'),
            GuideTarget(section.id),
          ),
    ];
    return UnifiedSearch._(QuranSearchIndex(quran), entries, surahName);
  }

  final QuranSearchIndex _quran;
  final List<_Entry> _entries;
  final String Function(int surah) _surahName;

  /// Characters of context kept on each side of a match.
  static const int context = 60;

  /// Results by source, at most [limit] each, best matches first.
  Map<SearchSource, List<SearchHit>> search(String query, {int limit = 30}) {
    final out = <SearchSource, List<SearchHit>>{};
    final needle = normalizeArabicSearch(query).trim();
    if (needle.isEmpty) return out;
    final bool shortQuery = needle.length < 4;
    for (final r in _quran.search(query).take(limit)) {
      (out[SearchSource.quran] ??= []).add(
        _hit(
          SearchSource.quran,
          '${_surahName(r.surahNumber)} ${r.ayah.numberInSurah}',
          r.ayah.text,
          r.start,
          r.end,
          QuranVerseTarget(r.surahNumber, r.ayah.numberInSurah, r.ayah.page),
        ),
      );
    }
    for (final e in _entries) {
      final list = out[e.source] ??= [];
      if (list.length >= limit) continue;
      final match = e.text.find(query);
      if (match == null) continue;
      // A short query inside a word is mostly noise in these longer texts;
      // longer ones still match after a prefix such as wa- (والحزن).
      if (match.rank == QuranMatchRank.inside && shortQuery) continue;
      list.add(
        _hit(
          e.source,
          e.title,
          e.text.original,
          match.start,
          match.end,
          e.target,
        ),
      );
    }
    out.removeWhere((_, hits) => hits.isEmpty);
    return out;
  }

  static SearchHit _hit(
    SearchSource source,
    String title,
    String text,
    int start,
    int end,
    SearchTarget target,
  ) {
    final from = (start - context).clamp(0, text.length);
    final to = (end + context).clamp(0, text.length);
    final lead = from > 0 ? '… ' : '';
    final tail = to < text.length ? ' …' : '';
    final snippet = '$lead${text.substring(from, to)}$tail'.replaceAll(
      '\n',
      ' ',
    );
    return SearchHit(
      source: source,
      title: title,
      snippet: snippet,
      matchStart: lead.length + start - from,
      matchEnd: lead.length + end - from,
      target: target,
    );
  }
}
