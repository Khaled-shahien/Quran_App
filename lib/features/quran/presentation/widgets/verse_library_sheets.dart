import 'package:flutter/material.dart';
import 'package:sakina_app/core/feedback/feedback_service.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../../data/repositories/verse_library_repository.dart';
import '../providers/verse_library_controller.dart';

/// The colours a saved verse can carry, chosen to read on light and dark
/// backgrounds. The index is what is stored.
const List<Color> savedVerseColors = [
  Color(0xFF2E7D5B), // green
  Color(0xFFC9962B), // gold
  Color(0xFF2F6FB0), // blue
  Color(0xFFB0465E), // rose
  Color(0xFF7A55A8), // violet
];

String savedVerseColorName(AppLocalizations l10n, int index) => switch (index) {
  0 => l10n.savedColorGreen,
  1 => l10n.savedColorGold,
  2 => l10n.savedColorBlue,
  3 => l10n.savedColorRose,
  _ => l10n.savedColorViolet,
};

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
    ?..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Saves the verse with a colour and an optional label, or removes it.
Future<void> showSaveVerseSheet(
  BuildContext context, {
  required VerseLibraryController library,
  required int surah,
  required int ayah,
  required String title,
}) async {
  await library.ensureLoaded();
  if (!context.mounted) return;
  final SavedVerse? existing = library.savedAt(surah, ayah);
  final TextEditingController label = TextEditingController(
    text: existing?.label ?? '',
  );
  int color = existing?.color ?? 0;
  final l10n = l10nOf(context);
  final String? outcome = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setState) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(sheetContext).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (int i = 0; i < savedVerseColors.length; i++)
                  Semantics(
                    button: true,
                    selected: i == color,
                    label: savedVerseColorName(l10n, i),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => color = i),
                      child: SizedBox.square(
                        dimension: 48,
                        child: Center(
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: savedVerseColors[i],
                            child: i == color
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            TextField(
              controller: label,
              maxLength: 40,
              decoration: InputDecoration(labelText: l10n.savedVerseLabel),
            ),
            Row(
              children: [
                if (existing != null)
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(l10n.savedVerseRemove),
                    onPressed: () => Navigator.pop(sheetContext, 'remove'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetContext, 'save'),
                  child: Text(l10n.savedVerseSave),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  final String text = label.text;
  label.dispose();
  if (outcome == null || !context.mounted) return;
  final bool ok = outcome == 'remove'
      ? await library.removeVerse(surah, ayah)
      : await library.saveVerse(surah, ayah, color: color, label: text);
  if (!context.mounted) return;
  playFeedback(context, FeedbackEvent.bookmark);
  _snack(
    context,
    !ok
        ? l10n.savedVerseFailed
        : outcome == 'remove'
        ? l10n.savedVerseRemoved
        : l10n.savedVerseSaved,
  );
}

/// Writes, edits or clears the private note of a verse.
Future<void> showVerseNoteEditor(
  BuildContext context, {
  required VerseLibraryController library,
  required int surah,
  required int ayah,
  required String title,
}) async {
  await library.ensureLoaded();
  if (!context.mounted) return;
  final l10n = l10nOf(context);
  final TextEditingController body = TextEditingController(
    text: library.noteAt(surah, ayah)?.body ?? '',
  );
  final bool? save = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: body,
        autofocus: true,
        minLines: 4,
        maxLines: 10,
        maxLength: VerseNote.maxLength,
        decoration: InputDecoration(
          hintText: l10n.verseNoteHint,
          helperText: l10n.verseNotePrivacy,
          helperMaxLines: 2,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.appStringsMessage9),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.verseNoteSave),
        ),
      ],
    ),
  );
  final String text = body.text;
  body.dispose();
  if (save != true || !context.mounted) return;
  final bool ok = await library.saveNote(surah, ayah, text);
  if (!context.mounted) return;
  _snack(
    context,
    !ok
        ? l10n.savedVerseFailed
        : text.trim().isEmpty
        ? l10n.verseNoteDeleted
        : l10n.verseNoteSaved,
  );
}
