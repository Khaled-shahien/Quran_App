import 'package:flutter/material.dart';

/// Corner radii. Pick by role, not by number.
abstract class AppRadius {
  static const double xs = 4;
  static const double sm = 8;

  /// Buttons, inputs, list tiles, small tiles.
  static const double control = 12;

  /// Cards and panels.
  static const double md = 16;

  /// Hero cards and large feature surfaces.
  static const double lg = 24;

  /// Sheets and dialogs.
  static const double xl = 28;

  static const BorderRadius chip = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius controls = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius hero = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius dialog = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
  static const BorderRadius pill = BorderRadius.all(Radius.circular(100));
}
