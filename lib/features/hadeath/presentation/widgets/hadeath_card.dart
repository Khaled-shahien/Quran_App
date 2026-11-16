import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// One hadith in the list: its title on a quiet tile.
class HadeathCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const HadeathCard({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondary,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: AppRadius.controls,
                ),
                child: Icon(Icons.menu_book, color: scheme.primary, size: 22),
              ),
              const SizedBox(width: AppSpacing.ms),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.script.copyWith(
                    fontSize: 20,
                    height: 1.6,
                    color: scheme.onSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right,
                color: scheme.onSurfaceVariant,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
