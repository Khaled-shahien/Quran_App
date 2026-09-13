import 'package:flutter/material.dart';

abstract class AppConstants {
  // App Info
  static const String appName = 'سكينة';
  static const String appVersion = '1.0.0';

  // Dimensions
  static const double kPaddingSmall = 8.0;
  static const double kPaddingMedium = 16.0;
  static const double kPaddingLarge = 24.0;
  static const double kPaddingExtraLarge = 32.0;

  static const double kBorderRadiusSmall = 4.0;
  static const double kBorderRadiusMedium = 8.0;
  static const double kBorderRadiusLarge = 12.0;
  static const double kBorderRadiusExtraLarge = 16.0;

  static const double kElevationSmall = 2.0;
  static const double kElevationMedium = 4.0;
  static const double kElevationLarge = 8.0;

  // Spacing
  static const EdgeInsets kPaddingAllMedium = EdgeInsets.all(kPaddingMedium);
  static const EdgeInsets kPaddingAllLarge = EdgeInsets.all(kPaddingLarge);
  static const EdgeInsets kPaddingSymmetricHMedium = EdgeInsets.symmetric(
    horizontal: kPaddingMedium,
  );
  static const EdgeInsets kPaddingSymmetricVMedium = EdgeInsets.symmetric(
    vertical: kPaddingMedium,
  );

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
