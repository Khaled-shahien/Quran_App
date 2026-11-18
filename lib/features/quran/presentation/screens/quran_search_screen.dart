import '../../domain/services/quran_divisions.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/l10n/localization.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_ar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../data/data_sources/quran_master_asset.dart';
import '../../domain/entities/ayah_entity.dart';
import '../../domain/repositories/ayah_repository.dart';
import '../../domain/services/quran_search.dart';

class QuranSearchScreen extends StatefulWidget {
  const QuranSearchScreen({super.key, this.repository});
  final AyahRepository? repository;
  @override
  State<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends State<QuranSearchScreen> {
  Map<int, List<AyahEntity>>? _source;

  /// Built once when the text loads; every keystroke searches it.
  QuranSearchIndex? _index;
  List<QuranSearchResult> _results = [];
  List<Map<String, dynamic>> _surahs = [];
  List<Map<String, dynamic>> get _matchingSurahs {
    final query = normalizeArabicSearch(_query).trim().replaceAllMapped(
      RegExp('[٠-٩]'),
      (m) => (m[0]!.codeUnitAt(0) - 0x660).toString(),
    );
    if (query.isEmpty) return [];
    return _surahs
        .where(
          (surah) =>
              surah['number'].toString() == query ||
              normalizeArabicSearch(surah['name'] as String).contains(query) ||
              normalizeArabicSearch(
                surah['englishName'] as String,
              ).contains(query),
        )
        .toList();
  }

  String _query = '';
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
    _loadSurahNames();
  }

  Future<void> _loadSurahNames() async {
    try {
      final data = (await QuranMasterAsset.load())
          .where(
            (surah) =>
                surah['number'] != null &&
                surah['name'] is String &&
                surah['englishName'] is String,
          )
          .toList();
      if (mounted) setState(() => _surahs = data);
    } catch (error) {
      debugPrint('Surah metadata load failed: $error');
    }
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    final result = await (widget.repository ?? getIt<AyahRepository>())
        .getAllAyahs();
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        final index = QuranSearchIndex(value);
        setState(() {
          _source = value;
          _index = index;
          _results = index.search(_query);
        });
      case Err():
        setState(() => _failed = true);
    }
  }

  /// "2:255" (or ٢:٢٥٥) typed as a verse reference.
  QuranGoToVerse? get _verseReference {
    if (_surahs.isEmpty) return null;
    final goTo = parseQuranGoTo(_query, (surah) {
      for (final s in _surahs) {
        if (s['number'] == surah) {
          final ayahs = s['ayahs'];
          return ayahs is List ? ayahs.length : 0;
        }
      }
      return 0;
    });
    return goTo is QuranGoToVerse ? goTo : null;
  }

  Widget _verseTile(BuildContext context, QuranGoToVerse verse) {
    final name =
        _surahs.firstWhere((s) => s['number'] == verse.surah)['name'] as String;
    return ListTile(
      key: const Key('search-go-to-verse'),
      leading: const Icon(Icons.subdirectory_arrow_left_rounded),
      title: Text(context.digits(l10n.searchGoToVerse(name, '${verse.ayah}'))),
      onTap: () => context.push(
        '/quran/surah/${verse.surah}',
        extra: {
          'initialSurahNumber': verse.surah,
          'initialAyahNumber': verse.ayah,
        },
      ),
    );
  }

  AppLocalizations get l10n =>
      AppLocalizations.of(context) ?? AppLocalizationsAr();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(l10n.searchQuran)),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.searchAyah,
                hintText: l10nOf(context).quranSearchScreenMessage1,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) => setState(() {
                _query = value;
                _results = _index?.search(value) ?? const [];
              }),
            ),
          ),
          Expanded(
            child: _failed
                ? Center(
                    child: TextButton(
                      onPressed: _load,
                      child: Text(l10nOf(context).quranSearchScreenMessage2),
                    ),
                  )
                : _source == null
                ? const Center(child: CircularProgressIndicator())
                : _query.trim().isEmpty
                ? Center(child: Text(l10nOf(context).quranSearchScreenMessage3))
                : _results.isEmpty &&
                      _matchingSurahs.isEmpty &&
                      _verseReference == null
                ? Center(child: Text(l10n.searchEmpty))
                : ListView.builder(
                    itemCount:
                        (_verseReference == null ? 0 : 1) +
                        _matchingSurahs.length +
                        _results.length,
                    itemBuilder: (context, index) {
                      final verse = _verseReference;
                      if (verse != null) {
                        if (index == 0) return _verseTile(context, verse);
                        index--;
                      }
                      final surahs = _matchingSurahs;
                      if (index < surahs.length) {
                        final surah = surahs[index];
                        return ListTile(
                          leading: const Icon(Icons.menu_book),
                          title: Text(surah['name'] as String),
                          subtitle: Text(
                            l10nOf(context).surahAudioModelMessage1(
                              context.digits('${surah['number']}'),
                            ),
                          ),
                          onTap: () =>
                              context.push('/quran/surah/${surah['number']}'),
                        );
                      }
                      final result = _results[index - surahs.length];
                      final text = result.ayah.text;
                      return ListTile(
                        title: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: text.substring(0, result.start)),
                              TextSpan(
                                text: text.substring(result.start, result.end),
                                style: TextStyle(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(text: text.substring(result.end)),
                            ],
                          ),
                        ),
                        subtitle: Text(
                          l10nOf(context).quranSearchScreenMessage4(
                            context.digits(result.surahNumber),
                            context.digits(result.ayah.numberInSurah),
                          ),
                        ),
                        onTap: () => context.push(
                          '/quran/surah/${result.surahNumber}',
                          extra: {
                            'initialSurahNumber': result.surahNumber,
                            'initialAyahNumber': result.ayah.numberInSurah,
                            'initialPageNumber': result.ayah.page,
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}
