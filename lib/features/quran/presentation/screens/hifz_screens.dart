import '../../domain/services/quran_divisions.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/database/app_database.dart';
import 'package:sakina_app/core/di/service_locator.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/core/theme/app_typography.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../../data/data_sources/quran_master_asset.dart';
import '../../data/repositories/hifz_repository.dart';
import '../../domain/services/basmala.dart';

/// One ayah as the review screen shows it.
typedef PageAyah = ({int surah, int ayah, String text, String surahName});

/// The ayahs on each mushaf page, read once from the bundled text.
Future<Map<int, List<PageAyah>>> loadMushafPages() async {
  final surahs = await QuranMasterAsset.load();
  final pages = <int, List<PageAyah>>{};
  for (final s in surahs) {
    final int number = s['number'] as int;
    for (final a in (s['ayahs'] as List).cast<Map<String, dynamic>>()) {
      final int ayah = a['numberInSurah'] as int;
      final split = splitLeadingBasmala(
        surahNumber: number,
        ayahNumber: ayah,
        text: a['text'] as String,
      );
      (pages[a['page'] as int] ??= []).add((
        surah: number,
        ayah: ayah,
        text: split.ayahText,
        surahName: s['name'] as String,
      ));
    }
  }
  return pages;
}

/// Memorised pages, what is due today, and adding pages.
class HifzScreen extends StatefulWidget {
  const HifzScreen({super.key, this.repository, this.pages});

  final HifzRepository? repository;

  /// The mushaf pages, for tests; otherwise loaded from the asset.
  final Map<int, List<PageAyah>>? pages;

  @override
  State<HifzScreen> createState() => _HifzScreenState();
}

class _HifzScreenState extends State<HifzScreen> {
  late final HifzRepository _repository =
      widget.repository ?? HifzRepository(getIt.getAsync<AppDatabase>);
  List<HifzPage>? _pages;
  Map<int, List<PageAyah>>? _mushaf;

  @override
  void initState() {
    super.initState();
    _mushaf = widget.pages;
    unawaited(_load());
  }

  Future<void> _load() async {
    final pages = await _repository.pages();
    final mushaf = _mushaf ?? await loadMushafPages();
    if (!mounted) return;
    setState(() {
      _pages = pages;
      _mushaf = mushaf;
    });
  }

  String _surahOf(int page) => _mushaf?[page]?.first.surahName ?? '';

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final theme = Theme.of(context);
    final pages = _pages;
    final today = DateTime.now();
    final due = [
      for (final p in pages ?? const <HifzPage>[])
        if (p.isDue(today)) p,
    ];
    final m = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.hifzTitle)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.hifzAdd),
        onPressed: pages == null ? null : _add,
      ),
      body: pages == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    context.digits(
                      l10n.hifzSummary('${pages.length}', '${due.length}'),
                    ),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text(
                    l10n.hifzExplain,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                if (pages.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(l10n.hifzEmpty, textAlign: TextAlign.center),
                  )
                else ...[
                  ListTile(title: Text(l10n.hifzDueTitle)),
                  if (due.isEmpty)
                    ListTile(
                      leading: const Icon(Icons.check_circle_outline_rounded),
                      title: Text(l10n.hifzNothingDue),
                    ),
                  for (final p in due)
                    ListTile(
                      key: Key('hifz-due-${p.page}'),
                      leading: const Icon(Icons.replay_rounded),
                      title: Text(
                        context.digits(
                          l10n.hifzPageLine('${p.page}', _surahOf(p.page)),
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_left_rounded),
                      onTap: () => _review(p.page),
                    ),
                  const Divider(),
                  ListTile(title: Text(l10n.hifzAllTitle)),
                  for (final p in pages)
                    ListTile(
                      dense: true,
                      title: Text(
                        context.digits(
                          l10n.hifzPageLine('${p.page}', _surahOf(p.page)),
                        ),
                      ),
                      subtitle: Text(
                        context.digits(
                          l10n.hifzNextReview(m.formatMediumDate(p.due)),
                        ),
                      ),
                      trailing: IconButton(
                        tooltip: l10n.hifzRemove,
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () async {
                          await _repository.remove(p.page);
                          await _load();
                        },
                      ),
                    ),
                ],
              ],
            ),
    );
  }

  Future<void> _review(int page) async {
    final ayahs = _mushaf?[page];
    if (ayahs == null) return;
    final bool? remembered = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => HifzReviewScreen(page: page, ayahs: ayahs),
      ),
    );
    if (remembered == null) return;
    await _repository.review(page, remembered: remembered);
    await _load();
  }

  Future<void> _add() async {
    final range = await showDialog<(int, int)>(
      context: context,
      builder: (_) => const _AddPagesDialog(),
    );
    if (range == null) return;
    await _repository.addPages(range.$1, range.$2);
    await _load();
  }
}

/// Reads digits typed in Western or Arabic-Indic form.
int? _readNumber(String text) => int.tryParse(westernDigits(text).trim());

class _AddPagesDialog extends StatefulWidget {
  const _AddPagesDialog();

  @override
  State<_AddPagesDialog> createState() => _AddPagesDialogState();
}

class _AddPagesDialogState extends State<_AddPagesDialog> {
  final _from = TextEditingController();
  final _to = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  void _submit() {
    final from = _readNumber(_from.text);
    final to = _readNumber(_to.text.isEmpty ? _from.text : _to.text);
    if (from == null || to == null || from < 1 || to > 604 || from > to) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.pop(context, (from, to));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return AlertDialog(
      title: Text(l10n.hifzAdd),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('hifz-from'),
            controller: _from,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.hifzAddFrom),
          ),
          TextField(
            key: const Key('hifz-to'),
            controller: _to,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.hifzAddTo,
              errorText: _invalid ? l10n.hifzAddInvalid : null,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.hifzAddConfirm)),
      ],
    );
  }
}

/// A page with every ayah hidden until tapped; the user then says whether
/// they remembered it. Pops true (remembered) or false (stumbled).
class HifzReviewScreen extends StatefulWidget {
  const HifzReviewScreen({super.key, required this.page, required this.ayahs});

  final int page;
  final List<PageAyah> ayahs;

  @override
  State<HifzReviewScreen> createState() => _HifzReviewScreenState();
}

class _HifzReviewScreenState extends State<HifzReviewScreen> {
  final Set<int> _shown = {};

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final theme = Theme.of(context);
    final first = widget.ayahs.first;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.digits(l10n.hifzReviewTitle('${widget.page}'))),
        actions: [
          IconButton(
            tooltip: l10n.hifzOpenInMushaf,
            icon: const Icon(Icons.menu_book_rounded),
            onPressed: () => context.push(
              '/quran/surah/${first.surah}',
              extra: {
                'initialSurahNumber': first.surah,
                'initialPageNumber': widget.page,
              },
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              icon: const Icon(Icons.visibility_outlined),
              label: Text(l10n.hifzRevealAll),
              onPressed: () => setState(
                () =>
                    _shown.addAll(List.generate(widget.ayahs.length, (i) => i)),
              ),
            ),
          ),
          for (final (i, a) in widget.ayahs.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _shown.contains(i)
                  ? Text(
                      '${a.text} ${context.digits('﴿${a.ayah}﴾')}',
                      textAlign: TextAlign.justify,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontFamily: quranFontFamily,
                        height: 2,
                      ),
                    )
                  : OutlinedButton(
                      key: Key('hifz-ayah-$i'),
                      onPressed: () => setState(() => _shown.add(i)),
                      child: Text(
                        context.digits(l10n.hifzRevealAyah('${a.ayah}')),
                      ),
                    ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('hifz-stumbled'),
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(l10n.hifzStumbled),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton.icon(
                  key: const Key('hifz-remembered'),
                  icon: const Icon(Icons.check_rounded),
                  label: Text(l10n.hifzRemembered),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
