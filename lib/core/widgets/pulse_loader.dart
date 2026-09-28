import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class PulseLoader extends StatefulWidget {
  final int lines;
  final double lineHeight;
  final EdgeInsetsGeometry padding;

  const PulseLoader({
    super.key,
    this.lines = 6,
    this.lineHeight = 20,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
  });

  @override
  State<PulseLoader> createState() => _PulseLoaderState();
}

class _PulseLoaderState extends State<PulseLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = Tween<double>(
      begin: 0.32,
      end: 0.72,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget placeholders = _PulsePlaceholders(
      lines: widget.lines,
      lineHeight: widget.lineHeight,
      padding: widget.padding,
    );

    if (MediaQuery.of(context).disableAnimations) return placeholders;

    return FadeTransition(opacity: _opacity, child: placeholders);
  }
}

class _PulsePlaceholders extends StatelessWidget {
  final int lines;
  final double lineHeight;
  final EdgeInsetsGeometry padding;

  const _PulsePlaceholders({
    required this.lines,
    required this.lineHeight,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final Color fill = Theme.of(
      context,
    ).colorScheme.primary.withValues(alpha: 0.12);

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(lines, (index) {
          final bool shortLine = index.isOdd;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: shortLine ? 0.72 : 1,
              child: Container(
                height: lineHeight,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
