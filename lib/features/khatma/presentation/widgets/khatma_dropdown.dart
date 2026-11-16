import 'package:flutter/material.dart';

import '../../../../core/feedback/feedback_service.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// The dropdown used by the khatma setup forms: a card-coloured field with
/// the app's control radius and outline.
class KhatmaDropdown<T> extends StatelessWidget {
  const KhatmaDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: AppSpacing.touchTarget),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: SakinaDecor.of(context).card,
        borderRadius: AppRadius.controls,
        border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          borderRadius: AppRadius.card,
          dropdownColor: SakinaDecor.of(context).card,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: scheme.onSurfaceVariant,
          ),
          style: theme.textTheme.titleSmall,
          items: items,
          onChanged: (T? next) {
            if (next == null || next == value) return;
            playFeedback(context, FeedbackEvent.selection);
            onChanged(next);
          },
        ),
      ),
    );
  }
}
