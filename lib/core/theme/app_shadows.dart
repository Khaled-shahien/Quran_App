import 'package:flutter/material.dart';

/// Soft, warm-tinted elevation. Dark themes separate surfaces by colour,
/// so shadows there are barely visible by design.
abstract class AppShadows {
  static const Color _tint = Color(0xFF2A1F1A);

  /// Resting cards.
  static List<BoxShadow> get subtle => [
    BoxShadow(
      color: _tint.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  /// Raised cards.
  static List<BoxShadow> get card => [
    BoxShadow(
      color: _tint.withValues(alpha: 0.07),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  /// Floating surfaces: toasts, the selected segment, hero cards.
  static List<BoxShadow> get floating => [
    BoxShadow(
      color: _tint.withValues(alpha: 0.14),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];
}
