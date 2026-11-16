import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import '../widgets/dhikr_text_block.dart';

import 'package:provider/provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/pulse_loader.dart';
import '../../../../core/widgets/sakina_card.dart';
import '../../../../core/widgets/sakina_hero_app_bar.dart';
import '../../../../core/widgets/status_view.dart';
import '../providers/duas_provider.dart';

class DuasScreen extends StatelessWidget {
  const DuasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Consumer<DuasProvider>(
          builder: (context, provider, child) {
            // The header shrinks away as the supplications scroll up.
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SakinaHeroAppBar(title: l10nOf(context).appStringsMessage30),
                ..._content(context, provider),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, DuasProvider provider) {
    if (provider.isLoading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: PulseLoader(lines: 6)),
        ),
      ];
    }

    if (provider.errorMessage != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: StatusView.error(message: l10nOf(context).duasScreenMessage1),
        ),
      ];
    }

    // The JSON has one category ("أدعية قرآنية"), so take it directly.
    final category = provider.getCategoryByName('أدعية قرآنية');

    if (category == null || category.items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.menu_book_outlined,
            message: l10nOf(context).duasScreenMessage2,
          ),
        ),
      ];
    }

    return [
      SliverSafeArea(
        top: false,
        sliver: SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.page),
          sliver: SliverList.builder(
            itemCount: category.items.length,
            itemBuilder: (context, index) =>
                _DuasItemCard(item: category.items[index]),
          ),
        ),
      ),
    ];
  }
}

class _DuasItemCard extends StatelessWidget {
  final dynamic item;

  const _DuasItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: l10nOf(context).duasScreenMessage3((item.title).toString()),
      child: SakinaCard(
        tone: SakinaCardTone.tinted,
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              item.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Duas Text, with source guidance set apart
            DhikrTextBlock(item: item),

            // Reference if available
            if (item.reference != null && item.reference.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Text(
                item.reference,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.start,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
