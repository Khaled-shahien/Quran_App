import 'package:flutter/material.dart';

import '../theme/app_design.dart';
import 'geometric_pattern.dart';

/// A calm "nothing here yet" message: an icon on a small medallion of the
/// design's geometric ornament, then the message.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: SizedBox.square(
                dimension: 120,
                child: ClipOval(
                  child: ColoredBox(
                    color: scheme.primary.withValues(alpha: 0.08),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: GeometricPattern(
                            pattern: SakinaDecor.of(context).pattern,
                            color: scheme.primary.withValues(alpha: 0.18),
                          ),
                        ),
                        Center(
                          child: Icon(icon, size: 44, color: scheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
