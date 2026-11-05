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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          categoryName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          button: true,
          label: l10nOf(context).azkarDetailsScreenMessage1,
          child: IconButton(
            tooltip: l10nOf(context).azkarDetailsScreenMessage2,
            icon: Icon(
              Icons.arrow_back_ios,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Consumer<AzkarProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: PulseLoader(lines: 6));
              }

              if (provider.errorMessage != null) {
                return Center(
                  child: Text(
                    l10nOf(context).azkarDetailsScreenMessage3,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 18,
                    ),
                  ),
                );
              }

              final category = provider.getCategoryByName(categoryName);

              if (category == null || category.items.isEmpty) {
                return Center(
                  child: Text(
                    l10nOf(context).azkarDetailsScreenMessage4,
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.primary,
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
      ),
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          if (p == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
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

    final card = Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: complete
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (item.title.isNotEmpty)
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            if (item.repeat > 1 && p == null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.azkarDetailsScreenMessage6((item.repeat).toString()),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Azkar Text, with source guidance set apart
            DhikrTextBlock(item: item),

            if (p != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: done / total,
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Shape and text, not color alone, mark completion.
                  if (complete)
                    Icon(
                      Icons.check_circle_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    complete
                        ? l10n.adhkarDone
                        : l10n.adhkarProgress('$done', '$total'),
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
            ],

            if (item.reference.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(thickness: 0.5),
              const SizedBox(height: 8),
              Text(
                item.reference,
                style: TextStyle(
                  fontSize: 13,
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
      return Semantics(
        container: true,
        label: l10n.azkarDetailsScreenMessage5(item.title),
        child: card,
      );
    }
    // The whole card is the tap target: easy for children and seniors.
    return Semantics(
      button: true,
      label: l10n.adhkarItemSemantics(item.title, '$done', '$total'),
      excludeSemantics: false,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: complete
            ? null
            : () {
                final finishedItem = p.increment(item);
                if (finishedItem && p.allComplete) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.adhkarCompleted(p.category))),
                  );
                }
              },
        child: card,
      ),
    );
  }
}
