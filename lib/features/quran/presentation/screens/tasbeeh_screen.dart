import 'package:sakina_app/core/widgets/sakina_hero_app_bar.dart';
import 'package:sakina_app/core/theme/app_design.dart';
import 'package:sakina_app/core/feedback/feedback_service.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pressable.dart';
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

    return SakinaHeroScaffold(
      title: l10n.tasbeehScreenMessage5,
      actions: [
        IconButton(
          tooltip: l10n.tasbeehScreenMessage7,
          icon: const Icon(Icons.add_rounded),
          onPressed: _showAddTasbeehDialog,
        ),
        IconButton(
          tooltip: l10n.tasbeehScreenMessage8,
          icon: Icon(Icons.refresh, color: scheme.error),
          onPressed: _resetCounters,
        ),
      ],
      // A fixed tool: the tap area and the phrase list share the space under
      // the header, so the header stays open here.
      slivers: [
        SliverFillRemaining(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
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
                        borderRadius: AppRadius.hero,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: const Key('tasbih-tap-area'),
                          onTap: selected == null ? null : _incrementCounter,
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _CounterRing(
                                    progress: target > 0
                                        ? (count / target).clamp(0.0, 1.0)
                                        : null,
                                    complete: target > 0 && count >= target,
                                    // The number gives a small bump on each
                                    // count, so a tap is seen as well as felt.
                                    child: TweenAnimationBuilder<double>(
                                      key: ValueKey<int>(count),
                                      tween: Tween<double>(begin: 1.1, end: 1),
                                      duration: AppMotion.of(
                                        context,
                                        AppMotion.base,
                                      ),
                                      curve: AppMotion.enter,
                                      builder: (context, scale, child) =>
                                          Transform.scale(
                                            scale: scale,
                                            child: child,
                                          ),
                                      child: Text(
                                        context.digits(
                                          count.toString().padLeft(2, '0'),
                                        ),
                                        style: AppTypography.numeral.copyWith(
                                          fontSize: 56,
                                          color: scheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    phraseText,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.script.copyWith(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w400,
                                      color: scheme.onSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  if (target > 0) ...[
                                    Text(
                                      l10n.adhkarProgress(
                                        context.digits(count),
                                        context.digits(target),
                                      ),
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                  const SizedBox(height: AppSpacing.xs),
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
                  const SizedBox(height: AppSpacing.sm),
                  // Phrases: tap to choose, swipe to delete (with undo).
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: scheme.secondary,
                        borderRadius: AppRadius.hero,
                      ),
                      padding: const EdgeInsets.all(AppSpacing.sm),
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
      ],
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
            content: Text(appL10n.tasbeehScreenMessage12((title).toString())),
            action: SnackBarAction(
              label: appL10n.currentWirdWidgetMessage13,
              onPressed: () => _controller.restore(removed),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      },
      background: Container(
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.lg),
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: AppRadius.controls,
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: Theme.of(context).colorScheme.onError,
          size: 24,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Semantics(
          button: true,
          selected: isSelected,
          child: Pressable(
            onTap: () => _controller.select(index),
            feedback: isSelected ? null : FeedbackEvent.selection,
            scale: false,
            borderRadius: AppRadius.controls,
            child: AnimatedContainer(
              duration: AppMotion.of(context, AppMotion.base),
              curve: AppMotion.standard,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.ms,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                borderRadius: AppRadius.controls,
                color: isSelected
                    ? Theme.of(context).colorScheme.surface
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  // Finished phrases get a tick, not only a colour.
                  Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 18,
                    color: isCompleted
                        ? SakinaDecor.of(context).success
                        : Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    constraints: const BoxConstraints(minWidth: 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: AppRadius.pill,
                    ),
                    child: Text(
                      counter,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The count inside a ring that fills towards the phrase's target.
class _CounterRing extends StatelessWidget {
  const _CounterRing({
    required this.child,
    required this.progress,
    required this.complete,
  });

  final Widget child;

  /// 0..1, or null when the phrase has no target (the ring stays empty).
  final double? progress;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final decor = SakinaDecor.of(context);
    return SizedBox.square(
      dimension: 168,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: progress ?? 0),
                duration: AppMotion.of(context, AppMotion.base),
                curve: AppMotion.enter,
                builder: (context, value, _) => CircularProgressIndicator(
                  value: value,
                  strokeWidth: 6,
                  strokeCap: StrokeCap.round,
                  backgroundColor: scheme.surface,
                  color: complete ? decor.success : scheme.primary,
                ),
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: child,
            ),
          ),
        ],
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
      title: Text(l10nOf(context).tasbeehScreenMessage9),
      content: TextField(
        controller: controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) Navigator.of(context).pop(value);
        },
        decoration: InputDecoration(
          hintText: l10nOf(context).tasbeehScreenMessage10,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(l10nOf(context).appStringsMessage9),
        ),
        FilledButton(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              Navigator.of(context).pop(controller.text);
            }
          },
          child: Text(l10nOf(context).tasbeehScreenMessage11),
        ),
      ],
    );
  }
}
