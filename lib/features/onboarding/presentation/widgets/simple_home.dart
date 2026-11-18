import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/l10n/localization.dart';

/// Simple mode's home: Quran, prayer times, adhkar and qibla as four large
/// tiles, two by two (one per row when large text needs the width).
class SimpleHomeTiles extends StatelessWidget {
  const SimpleHomeTiles({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final tiles = [
      (
        Icons.menu_book_rounded,
        l10n.simpleHomeQuran,
        () => context.go('/quran'),
      ),
      (
        Icons.access_time_rounded,
        l10n.simpleHomePrayers,
        () => context.go('/prayers'),
      ),
      (Icons.spa_rounded, l10n.simpleHomeAdhkar, () => context.go('/duas')),
      (
        Icons.explore_rounded,
        l10n.simpleHomeQibla,
        () => context.push('/qibla'),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.page),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool oneColumn =
              constraints.maxWidth < 360 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.4;
          final double width = oneColumn
              ? constraints.maxWidth
              : (constraints.maxWidth - AppSpacing.md) / 2;
          return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final (icon, label, onTap) in tiles)
                SizedBox(
                  width: width,
                  child: _Tile(icon: icon, label: label, onTap: onTap),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 140),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 56,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
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
