import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/di/service_locator.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../duas/data/hisn_almuslim.dart';
import '../hadeath/domain/repositories/hadeath_repository.dart';
import '../islamic_guide/domain/repositories/islamic_guide_repository.dart';
import '../quran/data/data_sources/quran_master_asset.dart';
import '../quran/domain/repositories/ayah_repository.dart';
import 'unified_search.dart';

/// Reads every bundled source once. A source that fails is left out; the
/// others still search.
Future<UnifiedSearch> loadUnifiedSearch() async {
  final surahs = await QuranMasterAsset.load();
  final names = {
    for (final s in surahs) s['number'] as int: s['name'] as String,
  };
  final quran = await getIt<AyahRepository>().getAllAyahs();
  final hadith = await getIt<HadeathRepository>().getAllAhadeth();
  final guide = await getIt<IslamicGuideRepository>().getSections();
  List<HisnChapter> hisn = const [];
  try {
    hisn = await HisnAlMuslim.bundled.chapters();
  } catch (_) {
    // Searched without Hisn al-Muslim.
  }
  return UnifiedSearch.build(
    quran: quran.valueOrNull ?? const {},
    surahName: (n) => names[n] ?? '$n',
    hisn: hisn,
    hadith: hadith.valueOrNull ?? const [],
    guide: guide.valueOrNull ?? const [],
  );
}

/// One search box over the Quran, Hisn al-Muslim, the hadith and the
/// guide, results grouped by source with their references.
class UnifiedSearchScreen extends StatefulWidget {
  const UnifiedSearchScreen({super.key, this.load = loadUnifiedSearch});

  final Future<UnifiedSearch> Function() load;

  @override
  State<UnifiedSearchScreen> createState() => _UnifiedSearchScreenState();
}

class _UnifiedSearchScreenState extends State<UnifiedSearchScreen> {
  UnifiedSearch? _search;
  bool _failed = false;
  String _query = '';
  Map<SearchSource, List<SearchHit>> _hits = const {};
  final Set<SearchSource> _expanded = {};

  static const int _shown = 5;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final search = await widget.load();
      if (!mounted) return;
      setState(() {
        _search = search;
        _hits = search.search(_query);
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _onChanged(String value) => setState(() {
    _query = value;
    _expanded.clear();
    _hits = _search?.search(value) ?? const {};
  });

  String _sourceName(AppLocalizations l10n, SearchSource s) => switch (s) {
    SearchSource.quran => l10n.unifiedSearchQuran,
    SearchSource.hisn => l10n.unifiedSearchHisn,
    SearchSource.hadith => l10n.unifiedSearchHadith,
    SearchSource.guide => l10n.unifiedSearchGuide,
  };

  void _open(SearchHit hit) => switch (hit.target) {
    QuranVerseTarget(:final surah, :final ayah, :final page) => context.push(
      '/quran/surah/$surah',
      extra: {
        'initialSurahNumber': surah,
        'initialAyahNumber': ayah,
        'initialPageNumber': page,
      },
    ),
    HisnChapterTarget(:final chapterId) => context.push(
      '/duas/hisn/$chapterId',
    ),
    HadithTarget(:final index, :final hadeath) => context.push(
      '/hadeath/details/$index',
      extra: hadeath,
    ),
    GuideTarget(:final sectionId) => context.push(
      '/guide?section=${Uri.encodeQueryComponent(sectionId)}',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final theme = Theme.of(context);
    final highlight = TextStyle(
      backgroundColor: theme.colorScheme.secondaryContainer,
      color: theme.colorScheme.onSecondaryContainer,
      fontWeight: FontWeight.bold,
    );
    final children = <Widget>[];
    for (final source in SearchSource.values) {
      final hits = _hits[source];
      if (hits == null) continue;
      final open = _expanded.contains(source);
      children.add(
        Semantics(
          header: true,
          child: ListTile(
            title: Text(
              context.digits(
                l10n.unifiedSearchGroup(
                  _sourceName(l10n, source),
                  '${hits.length}',
                ),
              ),
              style: theme.textTheme.titleMedium,
            ),
          ),
        ),
      );
      for (final hit in open ? hits : hits.take(_shown)) {
        children.add(
          ListTile(
            title: Text(context.digits(hit.title)),
            subtitle: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: hit.snippet.substring(0, hit.matchStart)),
                  TextSpan(
                    text: hit.snippet.substring(hit.matchStart, hit.matchEnd),
                    style: highlight,
                  ),
                  TextSpan(text: hit.snippet.substring(hit.matchEnd)),
                ],
              ),
            ),
            onTap: () => _open(hit),
          ),
        );
      }
      if (!open && hits.length > _shown) {
        children.add(
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => setState(() => _expanded.add(source)),
              child: Text(l10n.unifiedSearchShowAll),
            ),
          ),
        );
      }
      children.add(const Divider());
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.unifiedSearchTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                key: const Key('unified-search'),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.unifiedSearchHint,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: _onChanged,
              ),
            ),
            Expanded(
              child: _failed
                  ? Center(child: Text(l10n.unifiedSearchFailed))
                  : _search == null
                  ? const Center(child: CircularProgressIndicator())
                  : _query.trim().isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          l10n.unifiedSearchIntro,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : children.isEmpty
                  ? Center(child: Text(l10n.searchEmpty))
                  : ListView(children: children),
            ),
          ],
        ),
      ),
    );
  }
}
