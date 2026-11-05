import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_design.dart';

/// A faint Islamic geometric ornament that fills its area. Purely
/// decorative: hidden from screen readers and never receives touches.
class GeometricPattern extends StatelessWidget {
  const GeometricPattern({
    super.key,
    required this.pattern,
    required this.color,
  });

  final DecorPattern pattern;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _PatternPainter(pattern, color),
          size: Size.infinite,
        ),
      ),
    ),
  );
}

class _PatternPainter extends CustomPainter {
  _PatternPainter(this.pattern, this.color);

  final DecorPattern pattern;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..isAntiAlias = true;
    canvas.clipRect(Offset.zero & size);
    switch (pattern) {
      case DecorPattern.star:
        _stars(canvas, size, paint);
      case DecorPattern.rings:
        _rings(canvas, size, paint);
    }
  }

  /// Eight-pointed stars: a square and the same square turned 45 degrees.
  void _stars(Canvas canvas, Size size, Paint paint) {
    const cell = 44.0;
    const half = 10.0;
    for (var y = 0.0; y < size.height + cell; y += cell) {
      for (var x = 0.0; x < size.width + cell; x += cell) {
        final center = Offset(x + cell / 2, y + cell / 2);
        final square = Rect.fromCenter(
          center: center,
          width: half * 2,
          height: half * 2,
        );
        canvas.drawRect(square, paint);
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(math.pi / 4);
        canvas.translate(-center.dx, -center.dy);
        canvas.drawRect(square, paint);
        canvas.restore();
      }
    }
  }

  /// Interlaced circles on a square grid.
  void _rings(Canvas canvas, Size size, Paint paint) {
    const cell = 36.0;
    const radius = 13.0;
    for (var y = 0.0; y < size.height + cell; y += cell / 2) {
      final shifted = ((y / (cell / 2)).round()).isOdd;
      for (var x = shifted ? cell / 2 : 0.0; x < size.width + cell; x += cell) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_PatternPainter old) =>
      old.pattern != pattern || old.color != color;
}
