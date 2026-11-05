import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/pulse_loader.dart';
import '../../domain/entities/guide_entities.dart';
import '../providers/islamic_guide_provider.dart';
import '../widgets/guide_item_card.dart';

/// "دليل المسلم": prophets, prayer description, special prayers and pillars.
///
/// Expects an [IslamicGuideProvider] above it (route-scoped).
class IslamicGuideScreen extends StatelessWidget {
  const IslamicGuideScreen({super.key, this.initialSectionId});

  final String? initialSectionId;

  @override
  Widget build(BuildContext context) {
    final IslamicGuideProvider provider = context.watch<IslamicGuideProvider>();
    final ThemeData theme = Theme.of(context);

    if (provider.sections.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10nOf(context).guideTitle)),
        body: provider.hasError
            ? _ErrorView(onRetry: provider.load)
            : const Center(child: PulseLoader(lines: 6)),
      );
    }

    final List<GuideSection> sections = provider.sections;
    final int initialIndex = sections
        .indexWhere((s) => s.id == initialSectionId)
        .clamp(0, sections.length - 1);

    return DefaultTabController(
      length: sections.length,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10nOf(context).guideTitle),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
            ),
            unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
              fontFamily: 'Cairo',
            ),
            tabs: <Widget>[
              for (final GuideSection section in sections)
                Tab(text: section.title),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            for (final GuideSection section in sections)
              _SectionView(key: PageStorageKey(section.id), section: section),
          ],
        ),
      ),
    );
  }
}

class _SectionView extends StatelessWidget {
  const _SectionView({super.key, required this.section});

  final GuideSection section;

  @override
  Widget build(BuildContext context) {
    // Short sections read like an article, so open their cards by default.
    final bool expandAll = section.items.length <= 3;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      itemCount: section.items.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _SectionIntro(section: section);
        return GuideItemCard(
          item: section.items[index - 1],
          initiallyExpanded: expandAll && index == 1,
        );
      },
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({required this.section});

  final GuideSection section;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: AppRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (section.intro != null)
            Text(
              section.intro!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'Cairo',
                height: 1.7,
                color: scheme.onSurface,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.info_outline,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l10nOf(context).guideReviewNotice,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'Cairo',
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, size: 56, color: scheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10nOf(context).guideLoadError,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Cairo', color: scheme.error),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => onRetry(),
              child: Text(l10nOf(context).retry),
            ),
          ],
        ),
      ),
    );
  }
}
