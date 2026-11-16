import 'package:flutter/material.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// One of the ninety-nine names: its number, the name, and its meaning.
class AsmaItemCard extends StatelessWidget {
  final String number;
  final String arabicName;
  final String meaning;

  const AsmaItemCard({
    super.key,
    required this.number,
    required this.arabicName,
    required this.meaning,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Card(
      color: scheme.secondary,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.ms),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // A small pill that hugs the number.
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: AppRadius.pill,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.ms,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  context.digits(number),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              arabicName,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: AppTypography.script.copyWith(
                fontSize: 22,
                height: 1.5,
                color: scheme.onSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              meaning,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
