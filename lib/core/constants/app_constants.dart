import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';

abstract class AppConstants {
  // App Info
  static final String appName = appL10n.appConstantsMessage1;
  static const String appVersion = '1.0.0';

  // Sizes
  static const double kButtonHeight = 48.0;
  static const double kTextFieldHeight = 56.0;
  static const double kIconSizeSmall = 16.0;
  static const double kIconSizeMedium = 24.0;
  static const double kIconSizeLarge = 32.0;

  // Durations
  static const Duration kAnimationDuration = Duration(milliseconds: 300);
  static const Duration kSplashDuration = Duration(seconds: 2);

  // Assets
  static const String assetPath = 'assets';
  static const String imagesPath = '$assetPath/images';

  // Animation Curves
  static const Curve kAnimationCurve = Curves.easeInOut;
}
