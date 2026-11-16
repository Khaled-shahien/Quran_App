import 'package:flutter/material.dart';

import '../feedback/feedback_service.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

/// A two-or-more way switch with a thumb that slides to the chosen segment.
/// Used wherever one of a few views or options is chosen.
class SakinaSegmented extends StatelessWidget {
  const SakinaSegmented({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.margin = EdgeInsets.zero,
    this.semanticLabelFor,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final EdgeInsetsGeometry margin;

  /// Screen-reader label for a segment; the visible label when null.
  final String Function(String label)? semanticLabelFor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool dark = theme.brightness == Brightness.dark;
    final int count = labels.length;
    // -1 is the first segment's side, +1 the last; flips with direction.
    final double x = count == 1 ? 0 : -1 + 2 * selectedIndex / (count - 1);

    return Padding(
      padding: margin,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: scheme.secondary,
          borderRadius: AppRadius.card,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedAlign(
                alignment: AlignmentDirectional(x, 0),
                duration: AppMotion.of(context, AppMotion.base),
                curve: AppMotion.standard,
                child: FractionallySizedBox(
                  widthFactor: 1 / count,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: AppRadius.controls,
                      boxShadow: dark ? null : AppShadows.subtle,
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < count; i++)
                  Expanded(
                    child: _Segment(
                      label: labels[i],
                      semanticLabel: semanticLabelFor?.call(labels[i]),
                      selected: i == selectedIndex,
                      onTap: () {
                        if (i == selectedIndex) return;
                        playFeedback(context, FeedbackEvent.selection);
                        onChanged(i);
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
    this.semanticLabel,
  });

  final String label;
  final String? semanticLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      onTap: semanticLabel != null ? onTap : null,
      child: InkWell(
        borderRadius: AppRadius.controls,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: AnimatedDefaultTextStyle(
                duration: AppMotion.of(context, AppMotion.base),
                style: theme.textTheme.labelLarge!.copyWith(
                  color: selected ? scheme.onPrimary : scheme.onSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                child: Text(label),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
