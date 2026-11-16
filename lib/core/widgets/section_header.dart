import 'package:sakina_app/core/theme/app_radius.dart';
import 'package:flutter/material.dart';

import '../theme/app_design.dart';
import '../theme/app_spacing.dart';

/// The heading above a section: a small accent mark, the title, and an
/// optional trailing widget (a caption or an action).
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsetsDirectional.fromSTEB(
      AppSpacing.page,
      AppSpacing.lg,
      AppSpacing.page,
      AppSpacing.ms,
    ),
  });

  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: SakinaDecor.of(context).accent,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: theme.textTheme.titleMedium),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            // Pinned to the far edge, however short it is.
            Flexible(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: trailing!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
