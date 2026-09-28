part of 'surah_details_screen.dart';

class _BookmarkButton extends StatefulWidget {
  final Color color;
  final Future<void> Function() onTap;

  const _BookmarkButton({required this.color, required this.onTap});

  @override
  State<_BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<_BookmarkButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.85,
      upperBound: 1,
      value: 1,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    final bool disableAnimations = MediaQuery.of(context).disableAnimations;

    await widget.onTap();

    if (disableAnimations || !mounted) {
      return;
    }

    await _controller.animateTo(0.85, curve: Curves.easeIn);
    await _controller.animateTo(1, curve: Curves.elasticOut);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _controller,
      child: IconButton(
        tooltip: 'حفظ العلامة',
        style: IconButton.styleFrom(
          backgroundColor: widget.color.withValues(alpha: 0.1),
          side: BorderSide(color: widget.color.withValues(alpha: 0.18)),
        ),
        icon: Icon(Icons.bookmark, color: widget.color),
        onPressed: _handleTap,
      ),
    );
  }
}

class _ReaderNavButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _ReaderNavButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return IconButton(
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: color.withValues(
          alpha: onPressed == null ? 0.04 : 0.1,
        ),
        side: BorderSide(color: color.withValues(alpha: 0.14)),
      ),
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: onPressed == null ? color.withValues(alpha: 0.35) : color,
      ),
    );
  }
}
