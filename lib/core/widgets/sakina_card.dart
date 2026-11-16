import 'package:flutter/material.dart';

import '../theme/app_design.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// How a [SakinaCard] sits on the page.
enum SakinaCardTone {
  /// The design's card colour with a hairline border and a soft shadow.
  plain,

  /// The tile colour, flat: for grouped rows and quiet panels.
  tinted,

  /// The deep feature colour behind light text.
  feature,
}

/// The app's one card surface. Tappable when [onTap] is given.
class SakinaCard extends StatelessWidget {
  const SakinaCard({
    super.key,
    required this.child,
    this.tone = SakinaCardTone.plain,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin = EdgeInsets.zero,
    this.borderRadius = AppRadius.card,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final SakinaCardTone tone;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final SakinaDecor decor = SakinaDecor.of(context);
    final bool dark = theme.brightness == Brightness.dark;

    final Color color = switch (tone) {
      SakinaCardTone.plain => decor.card,
      SakinaCardTone.tinted => scheme.secondary,
      SakinaCardTone.feature => decor.featureCard,
    };
    final bool outlined = tone == SakinaCardTone.plain;

    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = Pressable(
        onTap: onTap,
        borderRadius: borderRadius,
        semanticLabel: semanticLabel,
        child: content,
      );
    }

    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
          border: outlined ? Border.all(color: scheme.outlineVariant) : null,
          // Dark themes separate surfaces by colour, not shadow.
          boxShadow: outlined && !dark ? AppShadows.subtle : null,
        ),
        child: ClipRRect(borderRadius: borderRadius, child: content),
      ),
    );
  }
}
