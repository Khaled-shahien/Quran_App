import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// A centred message for a screen that could not show its content: what
/// happened, in plain words, and one way forward.
class StatusView extends StatelessWidget {
  const StatusView({
    super.key,
    required this.icon,
    required this.message,
    this.detail,
    this.footnote,
    this.actionLabel,
    this.onAction,
    this.actionSemanticLabel,
  });

  /// A load failure with a retry button.
  const StatusView.error({
    super.key,
    required this.message,
    this.detail,
    this.footnote,
    this.actionLabel,
    this.onAction,
    this.actionSemanticLabel,
  }) : icon = Icons.error_outline;

  final IconData icon;
  final String message;
  final String? detail;

  /// A third, quieter line: the specific cause, when there is one.
  final String? footnote;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? actionSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.secondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: scheme.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (detail != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (footnote != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                footnote!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.md),
              Semantics(
                button: true,
                label: actionSemanticLabel,
                child: FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
