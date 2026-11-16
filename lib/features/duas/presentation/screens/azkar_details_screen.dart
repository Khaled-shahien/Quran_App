import 'package:sakina_app/core/widgets/sakina_hero_app_bar.dart';
import 'package:sakina_app/core/theme/app_design.dart';
import 'package:sakina_app/core/theme/app_motion.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/core/theme/app_radius.dart';
import 'package:sakina_app/core/feedback/feedback_service.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/azkar_model.dart';
import '../providers/adhkar_progress_controller.dart';
import '../widgets/dhikr_text_block.dart';

import 'package:provider/provider.dart';
import '../../../../core/widgets/pulse_loader.dart';
import '../providers/azkar_provider.dart';

class AzkarDetailsScreen extends StatelessWidget {
  final String categoryName;

  const AzkarDetailsScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return SakinaHeroScaffold(
      title: categoryName,
      slivers: [
        Directionality(
          textDirection: TextDirection.rtl,
          child: Consumer<AzkarProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: PulseLoader(lines: 6)),
                );
              }
              if (provider.errorMessage != null) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      l10nOf(context).azkarDetailsScreenMessage3,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                );
              }
              final category = provider.getCategoryByName(categoryName);
              if (category == null || category.items.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      l10nOf(context).azkarDetailsScreenMessage4,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                );
              }
              // Counting needs storage; without it the list is read-only.
              final prefs = Provider.of<SharedPreferences?>(
                context,
                listen: false,
              );
              if (prefs == null) {
                return _AdhkarList(items: category.items, progress: null);
              }
              return ChangeNotifierProvider<AdhkarProgressController>(
                key: ValueKey(categoryName),
                create: (_) => AdhkarProgressController(
                  preferences: prefs,
                  category: categoryName,
                  items: category.items,
                ),
                child: Consumer<AdhkarProgressController>(
                  builder: (context, progress, _) =>
                      _AdhkarList(items: category.items, progress: progress),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AdhkarList extends StatelessWidget {
  const _AdhkarList({required this.items, required this.progress});

  final List<AzkarItemModel> items;
  final AdhkarProgressController? progress;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final theme = Theme.of(context);
    final p = progress;
    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.md),
      sliver: SliverList.builder(
        itemCount: items.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            if (p == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.ms),
              // Wraps instead of overflowing with large system text.
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      p.allComplete
                          ? l10n.adhkarCompleted(p.category)
                          : l10n.adhkarTapToCount,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: p.allComplete
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: p.allComplete ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: p.completedItems == 0 && !_anyProgress(p)
                        ? null
                        : () => _reset(context, p),
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(l10n.adhkarReset),
                  ),
                ],
              ),
            );
          }
          final item = items[index - 1];
          return _AzkarItemCard(item: item, progress: p);
        },
      ),
    );
  }

  bool _anyProgress(AdhkarProgressController p) =>
      items.any((i) => p.countOf(i) > 0);

  void _reset(BuildContext context, AdhkarProgressController p) {
    final l10n = l10nOf(context);
    final before = p.reset();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.adhkarResetDone),
          action: SnackBarAction(
            label: l10n.currentWirdWidgetMessage13,
            onPressed: () => p.restore(before),
          ),
        ),
      );
  }
}

class _AzkarItemCard extends StatelessWidget {
  final AzkarItemModel item;
  final AdhkarProgressController? progress;

  const _AzkarItemCard({required this.item, required this.progress});

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final theme = Theme.of(context);
    final p = progress;
    final done = p?.countOf(item) ?? 0;
    final total = p?.targetOf(item) ?? item.repeat;
    final complete = p?.isComplete(item) ?? false;

    final Color success = SakinaDecor.of(context).success;
    // A finished dhikr settles into an outlined, tinted card.
    final card = AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.medium),
      curve: AppMotion.standard,
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: complete ? success : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (item.title.isNotEmpty)
              Text(
                item.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            if (item.repeat > 1 && p == null) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.azkarDetailsScreenMessage6(context.digits(item.repeat)),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),

            // Azkar Text, with source guidance set apart
            DhikrTextBlock(item: item),

            if (p != null) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: done / total),
                      duration: AppMotion.of(context, AppMotion.base),
                      curve: AppMotion.enter,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: theme.colorScheme.surface,
                        color: complete ? success : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.ms),
                  // Shape and text, not color alone, mark completion.
                  if (complete)
                    Icon(Icons.check_circle_rounded, color: success),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    complete
                        ? l10n.adhkarDone
                        : l10n.adhkarProgress(
                            context.digits(done),
                            context.digits(total),
                          ),
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
            ],

            if (item.reference.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(thickness: 0.5),
              const SizedBox(height: AppSpacing.sm),
              Text(
                item.reference,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.start,
              ),
            ],
          ],
        ),
      ),
    );

    if (p == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Semantics(
          container: true,
          label: l10n.azkarDetailsScreenMessage5(item.title),
          child: card,
        ),
      );
    }
    // The whole card is the tap target: easy for children and seniors.
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Semantics(
        button: true,
        label: l10n.adhkarItemSemantics(
          item.title,
          context.digits(done),
          context.digits(total),
        ),
        excludeSemantics: false,
        child: InkWell(
          borderRadius: AppRadius.card,
          onTap: complete
              ? null
              : () {
                  final finishedItem = p.increment(item);
                  playFeedback(
                    context,
                    finishedItem
                        ? FeedbackEvent.adhkarComplete
                        : FeedbackEvent.adhkarCount,
                  );
                  if (finishedItem && p.allComplete) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.adhkarCompleted(p.category))),
                    );
                  }
                },
          child: card,
        ),
      ),
    );
  }
}
