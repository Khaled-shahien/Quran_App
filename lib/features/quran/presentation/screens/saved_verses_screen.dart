import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/core/theme/app_typography.dart';
import 'package:sakina_app/core/utils/surah_names.dart';
import 'package:sakina_app/core/widgets/empty_state.dart';
import 'package:sakina_app/core/widgets/sakina_card.dart';
import 'package:sakina_app/core/widgets/sakina_hero_app_bar.dart';
import 'package:sakina_app/core/widgets/sakina_segmented.dart';
import 'package:sakina_app/core/widgets/status_view.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../../data/data_sources/quran_master_asset.dart';
import '../providers/verse_library_controller.dart';
import '../widgets/verse_library_sheets.dart';

/// The verses the user saved (with their colours and labels) and their
/// private notes. Each opens the reader at the verse.
class SavedVersesScreen extends StatefulWidget {
  const SavedVersesScreen({super.key});

  @override
  State<SavedVersesScreen> createState() => _SavedVersesScreenState();
}

class _SavedVersesScreenState extends State<SavedVersesScreen> {
  int _view = 0;
  Map<VerseRef, String> _texts = {};

  @override
  void initState() {
    super.initState();
    unawaited(context.read<VerseLibraryController>().ensureLoaded());
    unawaited(_loadTexts());
  }

  Future<void> _loadTexts() async {
    try {
      final surahs = await QuranMasterAsset.load();
      final Map<VerseRef, String> texts = {};
      for (final surah in surahs) {
        final int number = (surah['number'] as num).toInt();
        for (final ayah in surah['ayahs'] as List<dynamic>) {
          final map = ayah as Map<String, dynamic>;
          texts[(surah: number, ayah: (map['numberInSurah'] as num).toInt())] =
              (map['text'] as String).replaceFirst('﻿', '');
        }
      }
      if (mounted) setState(() => _texts = texts);
    } catch (_) {
      // References are still listed without the verse text.
    }
  }

  String _title(BuildContext context, int surah, int ayah) =>
      l10nOf(context).savedVerseReference(
        surahNameAr(surah) ?? context.digits(surah),
        context.digits(ayah),
      );

  void _open(int surah, int ayah) => context.push(
    '/quran/surah/$surah',
    extra: <String, dynamic>{'initialAyahNumber': ayah},
  );

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final ThemeData theme = Theme.of(context);
    final VerseLibraryController library = context
        .watch<VerseLibraryController>();
    final Widget body;
    if (library.failed && !library.loaded) {
      body = StatusView.error(
        message: l10n.savedVerseFailed,
        actionLabel: l10n.retry,
        onAction: library.reload,
      );
    } else if (!library.loaded) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_view == 0) {
      final saved = library.savedVerses;
      body = saved.isEmpty
          ? EmptyState(
              icon: Icons.bookmarks_outlined,
              message: l10n.savedVersesEmpty,
            )
          : Column(
              children: [
                for (final v in saved)
                  _Entry(
                    color: savedVerseColors[v.color],
                    colorName: savedVerseColorName(l10n, v.color),
                    title: _title(context, v.surah, v.ayah),
                    detail: v.label,
                    verse: _texts[(surah: v.surah, ayah: v.ayah)],
                    onTap: () => _open(v.surah, v.ayah),
                    onEdit: () => showSaveVerseSheet(
                      context,
                      library: library,
                      surah: v.surah,
                      ayah: v.ayah,
                      title: _title(context, v.surah, v.ayah),
                    ),
                  ),
              ],
            );
    } else {
      final notes = library.notes;
      body = notes.isEmpty
          ? EmptyState(
              icon: Icons.sticky_note_2_outlined,
              message: l10n.verseNotesEmpty,
            )
          : Column(
              children: [
                for (final n in notes)
                  _Entry(
                    title: _title(context, n.surah, n.ayah),
                    detail: n.body,
                    verse: _texts[(surah: n.surah, ayah: n.ayah)],
                    onTap: () => _open(n.surah, n.ayah),
                    onEdit: () => showVerseNoteEditor(
                      context,
                      library: library,
                      surah: n.surah,
                      ayah: n.ayah,
                      title: _title(context, n.surah, n.ayah),
                    ),
                  ),
              ],
            );
    }
    return SakinaHeroScaffold(
      title: l10n.savedVersesTitle,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverList.list(
            children: [
              SakinaSegmented(
                labels: [l10n.savedVersesTab, l10n.verseNotesTab],
                selectedIndex: _view,
                onChanged: (i) => setState(() => _view = i),
              ),
              const SizedBox(height: AppSpacing.md),
              body,
              const SizedBox(height: AppSpacing.md),
              Text(l10n.verseNotePrivacy, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.title,
    required this.onTap,
    required this.onEdit,
    this.color,
    this.colorName,
    this.detail,
    this.verse,
  });

  final String title;
  final String? detail;
  final String? verse;
  final Color? color;
  final String? colorName;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.ms),
      child: SakinaCard(
        onTap: onTap,
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (color != null) ...[
                  Semantics(
                    label: colorName,
                    child: CircleAvatar(radius: 6, backgroundColor: color),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
                IconButton(
                  tooltip: l10nOf(context).savedVerseEdit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                ),
              ],
            ),
            if (verse != null)
              Text(
                verse!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.script.copyWith(fontSize: 18),
              ),
            if (detail != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(detail!, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
