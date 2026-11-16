import 'package:flutter/material.dart';

import '../feedback/feedback_service.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';

/// A tappable surface with the app's press behaviour: an ink ripple, a
/// slight shrink while held, a focus ring, and optional feedback on tap.
///
/// Use this instead of a bare [InkWell] or [GestureDetector] so every
/// custom control responds the same way.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.borderRadius = AppRadius.card,
    this.color,
    this.feedback,
    this.semanticLabel,
    this.selected,
    this.scale = true,
    this.inkKey,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius borderRadius;

  /// Fill behind [child]; transparent when null.
  final Color? color;

  /// Played on tap, if given.
  final FeedbackEvent? feedback;

  /// When set, the control is announced as a button with this label and the
  /// semantics of [child] are hidden.
  final String? semanticLabel;
  final bool? selected;

  /// Whether the surface shrinks while pressed.
  final bool scale;

  /// Key for the inner [InkWell], for tests that tap it directly.
  final Key? inkKey;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  bool _focused = false;

  void _setDown(bool value) {
    if (_down != value && mounted) setState(() => _down = value);
  }

  void _handleTap() {
    final event = widget.feedback;
    if (event != null) playFeedback(context, event);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onTap != null;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool shrink = widget.scale && !AppMotion.reduced(context);

    Widget result = Material(
      color: widget.color ?? Colors.transparent,
      borderRadius: widget.borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: widget.inkKey,
        borderRadius: widget.borderRadius,
        onTap: enabled ? _handleTap : null,
        onLongPress: widget.onLongPress,
        onHighlightChanged: _setDown,
        onFocusChange: (value) {
          if (mounted) setState(() => _focused = value);
        },
        child: widget.child,
      ),
    );

    // Keyboard focus is shown by an outline, not by colour alone.
    result = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        border: _focused ? Border.all(color: scheme.primary, width: 2) : null,
      ),
      child: result,
    );

    if (shrink) {
      result = AnimatedScale(
        scale: _down ? AppMotion.pressedScale : 1,
        duration: AppMotion.fast,
        curve: AppMotion.enter,
        child: result,
      );
    }

    final String? label = widget.semanticLabel;
    if (label == null) return result;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: label,
      excludeSemantics: true,
      onTap: enabled ? _handleTap : null,
      child: result,
    );
  }
}
