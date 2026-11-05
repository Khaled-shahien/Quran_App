import 'package:sakina_app/core/theme/app_design.dart';
import 'package:sakina_app/core/feedback/feedback_service.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/tasbih_phrase.dart';
import '../providers/tasbih_controller.dart';

/// Display text for a phrase: built-ins come from l10n, custom ones as typed.
String tasbihPhraseText(TasbihPhrase phrase, AppLocalizations l10n) {
  if (phrase.customText case final text?) return text;
  return switch (phrase.id) {
    'builtin_subhan_allah' => l10n.tasbeehScreenMessage1,
    'builtin_alhamdulillah' => l10n.tasbeehScreenMessage2,
    'builtin_la_ilaha_illallah' => l10n.tasbeehScreenMessage3,
    'builtin_allahu_akbar' => l10n.tasbeehScreenMessage4,
    _ => '',
  };
}

class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> {
  TasbihController get _controller => context.read<TasbihController>();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TasbihController>();
    final l10n = l10nOf(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final phrases = controller.phrases;
    final selected = controller.selected;
    final count = controller.count;
    final target = selected?.target ?? 0;
    final phraseText = selected == null ? '' : tasbihPhraseText(selected, l10n);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: l10n.appStringsMessage13,
          icon: Icon(Icons.arrow_back_ios, color: scheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: l10n.tasbeehScreenMessage7,
            icon: Icon(Icons.add_rounded, color: scheme.primary),
            onPressed: _showAddTasbeehDialog,
          ),
          IconButton(
            tooltip: l10n.tasbeehScreenMessage8,
            icon: Icon(Icons.refresh, color: scheme.error),
            onPressed: _resetCounters,
          ),
        ],
        title: Text(
          l10n.tasbeehScreenMessage5,
          style: TextStyle(
            color: scheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.kPaddingMedium),
            child: Column(
              children: [
                // One large tap area: count without looking at the screen.
                Expanded(
                  flex: 3,
                  child: Semantics(
                    container: true,
                    button: true,
                    label: phraseText,
                    value: target > 0
                        ? l10n.adhkarProgress(
                            context.digits(count),
                            context.digits(target),
                          )
                        : '$count',
                    excludeSemantics: true,
                    child: Material(
                      color: scheme.secondary,
                      borderRadius: BorderRadius.circular(
                        AppConstants.kBorderRadiusLarge,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: const Key('tasbih-tap-area'),
                        onTap: selected == null ? null : _incrementCounter,
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(
                              AppConstants.kPaddingLarge,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  context.digits(
                                    count.toString().padLeft(2, '0'),
                                  ),
                                  style: TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.w800,
                                    color: scheme.primary,
                                    height: 1.1,
                                  ),
                                ),
                                Text(
                                  phraseText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 28,
                                    color: scheme.primary,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(
                                  height: AppConstants.kPaddingSmall,
                                ),
                                if (target > 0) ...[
                                  const SizedBox(
                                    height: AppConstants.kPaddingSmall,
                                  ),
                                  SizedBox(
                                    width: 160,
                                    child: LinearProgressIndicator(
                                      value: (count / target).clamp(0.0, 1.0),
                                      minHeight: 6,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.adhkarProgress(
                                      context.digits(count),
                                      context.digits(target),
                                    ),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  l10n.tasbihTapHint,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.kPaddingSmall),
                // Phrases: tap to choose, swipe to delete (with undo).
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.secondary,
                      borderRadius: BorderRadius.circular(
                        AppConstants.kBorderRadiusLarge,
                      ),
                    ),
                    padding: const EdgeInsets.all(AppConstants.kPaddingSmall),
                    child: ListView.builder(
                      itemCount: phrases.length,
                      itemBuilder: (context, index) {
                        final phrase = phrases[index];
                        return _tasbeehRow(
                          itemKey: phrase.id,
                          index: index,
                          title: tasbihPhraseText(phrase, l10n),
                          counter: context.digits(phrase.count),
                          isCompleted: phrase.isComplete,
                          isSelected: index == controller.selectedIndex,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _incrementCounter() {
    final setComplete = _controller.increment();
    playFeedback(
      context,
      setComplete ? FeedbackEvent.tasbihSetComplete : FeedbackEvent.tasbihCount,
    );
  }

  void _resetCounters() {
    final before = _controller.reset();
    playFeedback(context, FeedbackEvent.reset);
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10nOf(context).tasbihResetDone),
        action: SnackBarAction(
          label: l10nOf(context).currentWirdWidgetMessage13,
          onPressed: () => _controller.undoReset(before),
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  Future<void> _showAddTasbeehDialog() async {
    final String? text = await showDialog<String>(
      context: context,
      builder: (_) => const _AddPhraseDialog(),
    );
    if (text != null && mounted) _controller.add(text);
  }

  Widget _tasbeehRow({
    required Object itemKey,
    required int index,
    required String title,
    required String counter,
    required bool isCompleted,
    required bool isSelected,
  }) {
    return Dismissible(
      key: ObjectKey(itemKey),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        final removed = _controller.removeAt(index);
        if (removed == null) return;

        // Offer undo so a swipe never loses the phrase or its count.
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appL10n.tasbeehScreenMessage12((title).toString()),
              style: const TextStyle(),
            ),
            action: SnackBarAction(
              label: appL10n.currentWirdWidgetMessage13,
              textColor: SakinaDecor.of(context).accent,
              onPressed: () => _controller.restore(removed),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(AppConstants.kBorderRadiusMedium),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 24),
      ),
      child: Semantics(
        button: true,
        selected: isSelected,
        child: GestureDetector(
          onTap: () => _controller.select(index),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                AppConstants.kBorderRadiusMedium,
              ),
              color: isSelected
                  ? SakinaDecor.of(context).accent.withValues(alpha: 0.2)
                  : Theme.of(context).scaffoldBackgroundColor,
              border: Border.all(
                color: isCompleted
                    ? Theme.of(context).colorScheme.primary
                    : (isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: isCompleted
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(
                        AppConstants.kBorderRadiusSmall,
                      ),
                    ),
                    child: Text(
                      counter,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Owns its text controller so it is disposed with the dialog.
class _AddPhraseDialog extends StatefulWidget {
  const _AddPhraseDialog();

  @override
  State<_AddPhraseDialog> createState() => _AddPhraseDialogState();
}

class _AddPhraseDialogState extends State<_AddPhraseDialog> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog.adaptive(
      title: Text(
        l10nOf(context).tasbeehScreenMessage9,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          fontSize: 18,
        ),
      ),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: l10nOf(context).tasbeehScreenMessage10,
          hintStyle: const TextStyle(),
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.kBorderRadiusMedium,
            ),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.kBorderRadiusMedium,
            ),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
        ),
        textAlign: TextAlign.right,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            l10nOf(context).appStringsMessage9,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              Navigator.of(context).pop(controller.text);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: Text(l10nOf(context).tasbeehScreenMessage11),
        ),
      ],
    );
  }
}
