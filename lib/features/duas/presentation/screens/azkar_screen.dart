import 'package:sakina_app/core/widgets/sakina_hero_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../../../../core/theme/app_design.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/geometric_pattern.dart';
import '../../../../core/widgets/pressable.dart';

/// The adhkar categories: morning and evening first, then the rest.
class AzkarScreen extends StatelessWidget {
  const AzkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final categories = <(String, IconData)>[
      (l10n.azkarScreenMessage3, Icons.nights_stay_outlined),
      (l10n.azkarScreenMessage4, Icons.accessibility_new_rounded),
      (l10n.azkarScreenMessage5, Icons.wb_twilight_rounded),
      (l10n.azkarScreenMessage6, Icons.mosque_outlined),
      (l10n.azkarScreenMessage7, Icons.star_outline_rounded),
      (l10n.azkarScreenMessage8, Icons.menu_book_outlined),
      (l10n.azkarScreenMessage9, Icons.flight_takeoff_rounded),
      (l10n.azkarScreenMessage10, Icons.back_hand_outlined),
    ];
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return SakinaHeroScaffold(
      title: l10n.mainNavigationShellMessage2,
      slivers: [
        // The screen reads right-to-left wherever it is shown.
        Directionality(
          textDirection: TextDirection.rtl,
          child: SliverMainAxisGroup(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.sm,
                  AppSpacing.page,
                  AppSpacing.ms,
                ),
                sliver: SliverList.list(
                  children: [
                    _FeaturedCategory(
                      title: l10n.azkarScreenMessage1,
                      icon: Icons.wb_sunny_outlined,
                      night: false,
                    ),
                    const SizedBox(height: AppSpacing.ms),
                    _FeaturedCategory(
                      title: l10n.azkarScreenMessage2,
                      icon: Icons.nightlight_outlined,
                      night: true,
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  0,
                  AppSpacing.page,
                  AppSpacing.lg,
                ),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.ms,
                    crossAxisSpacing: AppSpacing.ms,
                    mainAxisExtent: 72 + 44 * textScale,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) => _CategoryCard(
                    title: categories[index].$1,
                    icon: categories[index].$2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void _open(BuildContext context, String title) {
  context.push('/azkar/details', extra: {'categoryName': title});
}

/// Morning and evening adhkar: the two most used, shown large.
class _FeaturedCategory extends StatelessWidget {
  const _FeaturedCategory({
    required this.title,
    required this.icon,
    required this.night,
  });

  final String title;
  final IconData icon;

  /// Evening uses the deeper feature colour; morning the lighter gradient.
  final bool night;

  @override
  Widget build(BuildContext context) {
    final decor = SakinaDecor.of(context);
    final theme = Theme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return ClipRRect(
      borderRadius: AppRadius.hero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: night ? decor.featureCard : null,
          gradient: night
              ? null
              : LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: decor.heroColors,
                ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: GeometricPattern(
                pattern: decor.pattern,
                color: decor.onFeature.withValues(alpha: 0.07),
              ),
            ),
            Pressable(
              onTap: () => _open(context, title),
              borderRadius: AppRadius.hero,
              semanticLabel: l10nOf(context).azkarScreenMessage11(title),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 96),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: decor.onFeature.withValues(alpha: 0.14),
                          borderRadius: AppRadius.card,
                        ),
                        child: Icon(icon, size: 28, color: decor.onFeature),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: textScale > 1.2 ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: decor.onFeature,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: decor.onFeatureMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return Pressable(
      onTap: () => _open(context, title),
      color: scheme.secondary,
      semanticLabel: l10nOf(context).azkarScreenMessage11(title),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.ms),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: AppRadius.controls,
              ),
              child: Icon(icon, size: 24, color: scheme.primary),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: textScale > 1.2 ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.onSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
