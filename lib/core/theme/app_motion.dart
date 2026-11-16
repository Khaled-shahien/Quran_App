import 'package:flutter/widgets.dart';

/// The app's motion scale. Short and quiet: motion explains a change, it
/// never decorates.
abstract class AppMotion {
  /// Press states and small colour changes.
  static const Duration fast = Duration(milliseconds: 120);

  /// Selection changes, switches, chips.
  static const Duration base = Duration(milliseconds: 200);

  /// Entrances, expanding content, page transitions in.
  static const Duration medium = Duration(milliseconds: 320);

  /// Progress fills and the few larger moves.
  static const Duration slow = Duration(milliseconds: 480);

  /// Page transitions out.
  static const Duration exit = Duration(milliseconds: 220);

  /// Gap between items that enter one after another.
  static const Duration stagger = Duration(milliseconds: 40);

  /// Things arriving or settling.
  static const Curve enter = Curves.easeOutCubic;

  /// Things leaving.
  static const Curve leave = Curves.easeInCubic;

  /// Moves that stay on screen (sliding thumbs, resizing).
  static const Curve standard = Cubic(0.2, 0, 0, 1);

  /// How far a pressed surface shrinks.
  static const double pressedScale = 0.97;

  /// True when the system asks for reduced motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// [duration], or zero when motion is reduced.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}
