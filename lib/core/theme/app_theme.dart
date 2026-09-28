import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.lightPrimary,
      brightness: Brightness.light,
      primary: AppColors.lightPrimary,
      onPrimary: AppColors.white,
      secondary: AppColors.lightSecondary,
      onSecondary: AppColors.primaryText,
      surface: AppColors.lightBackground,
      onSurface: AppColors.primaryText,
      error: AppColors.error,
      onError: AppColors.black,
      outline: const Color(0xFF81756F),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: _buildLightTextTheme(),
      appBarTheme: _buildAppBarTheme(
        primaryColor: AppColors.lightPrimary,
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.primaryText,
      ),
      elevatedButtonTheme: _buildElevatedButtonTheme(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: AppColors.white,
        borderColor: AppColors.lightPrimary,
      ),
      outlinedButtonTheme: _buildOutlinedButtonTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightPrimary,
        borderColor: AppColors.lightPrimary,
      ),
      cardTheme: _buildCardThemeData(
        backgroundColor: AppColors.lightCardContent,
        surfaceTintColor: AppColors.lightCardContent,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      // Enhanced Material 3 features
      navigationBarTheme: _buildNavigationBarTheme(colorScheme),
      bottomSheetTheme: _buildBottomSheetTheme(colorScheme),
      dialogTheme: _buildDialogTheme(colorScheme),
      inputDecorationTheme: _buildInputDecorationTheme(colorScheme),
      // Accessibility improvements
      scrollbarTheme: _buildScrollbarTheme(),
      // System UI overlay styling
      extensions: [_buildThemeExtensions()],
    );
  }

  static ThemeData get darkTheme {
    ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.darkPrimary,
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.black,
      secondary: AppColors.darkSecondary,
      onSecondary: AppColors.white,
      surface: AppColors.darkBackground,
      onSurface: AppColors.white,
      error: AppColors.error,
      onError: AppColors.black,
      outline: const Color(0xFF93867F),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: _buildDarkTextTheme(),
      appBarTheme: _buildAppBarTheme(
        primaryColor: AppColors.darkPrimary,
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.white,
      ),
      elevatedButtonTheme: _buildElevatedButtonTheme(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.black,
        borderColor: AppColors.darkPrimary,
      ),
      outlinedButtonTheme: _buildOutlinedButtonTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkPrimary,
        borderColor: AppColors.darkPageAccent,
      ),
      cardTheme: _buildCardThemeData(
        backgroundColor: AppColors.darkCardContent,
        surfaceTintColor: AppColors.darkCardContent,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      navigationBarTheme: _buildNavigationBarTheme(colorScheme),
      bottomSheetTheme: _buildBottomSheetTheme(colorScheme),
      dialogTheme: _buildDialogTheme(colorScheme),
      inputDecorationTheme: _buildInputDecorationTheme(colorScheme),
      scrollbarTheme: _buildScrollbarTheme(),
      extensions: [_buildThemeExtensions()],
    );
  }

  static TextTheme _buildLightTextTheme() {
    return TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(
        color: AppColors.primaryText,
      ),
      displayMedium: AppTypography.displayMedium.copyWith(
        color: AppColors.primaryText,
      ),
      displaySmall: AppTypography.displaySmall.copyWith(
        color: AppColors.primaryText,
      ),
      headlineLarge: AppTypography.headlineLarge.copyWith(
        color: AppColors.primaryText,
      ),
      headlineMedium: AppTypography.headlineMedium.copyWith(
        color: AppColors.primaryText,
      ),
      headlineSmall: AppTypography.headlineSmall.copyWith(
        color: AppColors.primaryText,
      ),
      titleLarge: AppTypography.titleLarge.copyWith(
        color: AppColors.primaryText,
      ),
      titleMedium: AppTypography.titleMedium.copyWith(
        color: AppColors.primaryText,
      ),
      titleSmall: AppTypography.titleSmall.copyWith(
        color: AppColors.primaryText,
      ),
      bodyLarge: AppTypography.bodyLarge.copyWith(
        color: AppColors.secondaryText,
      ),
      bodyMedium: AppTypography.bodyMedium.copyWith(
        color: AppColors.secondaryText,
      ),
      bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.captions),
      labelLarge: AppTypography.labelLarge.copyWith(
        color: AppColors.primaryText,
      ),
      labelMedium: AppTypography.labelMedium.copyWith(
        color: AppColors.primaryText,
      ),
      labelSmall: AppTypography.labelSmall.copyWith(
        color: AppColors.primaryText,
      ),
    );
  }

  static TextTheme _buildDarkTextTheme() {
    return TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.white),
      displayMedium: AppTypography.displayMedium.copyWith(
        color: AppColors.white,
      ),
      displaySmall: AppTypography.displaySmall.copyWith(color: AppColors.white),
      headlineLarge: AppTypography.headlineLarge.copyWith(
        color: AppColors.white,
      ),
      headlineMedium: AppTypography.headlineMedium.copyWith(
        color: AppColors.white,
      ),
      headlineSmall: AppTypography.headlineSmall.copyWith(
        color: AppColors.white,
      ),
      titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.white),
      titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.white),
      titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.white),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.lightGray),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.lightGray),
      bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.darkCaption),
      labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.white),
      labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.white),
      labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.white),
    );
  }

  static AppBarTheme _buildAppBarTheme({
    required Color primaryColor,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      titleTextStyle: AppTypography.titleLarge.copyWith(color: foregroundColor),
      elevation: 0,
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme({
    required Color backgroundColor,
    required Color foregroundColor,
    required Color borderColor,
  }) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        textStyle: AppTypography.titleMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme({
    required Color backgroundColor,
    required Color foregroundColor,
    required Color borderColor,
  }) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        textStyle: AppTypography.titleMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static CardThemeData _buildCardThemeData({
    required Color backgroundColor,
    required Color surfaceTintColor,
  }) {
    return CardThemeData(
      color: backgroundColor,
      surfaceTintColor: surfaceTintColor,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
    );
  }

  // Material 3 Navigation Bar Theme
  static NavigationBarThemeData _buildNavigationBarTheme(
    ColorScheme colorScheme,
  ) {
    return NavigationBarThemeData(
      indicatorColor: colorScheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
        Set<WidgetState> states,
      ) {
        return AppTypography.labelMedium.copyWith(
          color: states.contains(WidgetState.selected)
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurface,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.bold
              : FontWeight.normal,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((
        Set<WidgetState> states,
      ) {
        return IconThemeData(
          color: states.contains(WidgetState.selected)
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurface.withValues(alpha: 0.60),
        );
      }),
    );
  }

  // Material 3 Bottom Sheet Theme
  static BottomSheetThemeData _buildBottomSheetTheme(ColorScheme colorScheme) {
    return BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      elevation: 1,
      modalBarrierColor: Colors.black.withValues(alpha: 0.32),
      dragHandleColor: colorScheme.onSurface.withValues(alpha: 0.40),
      dragHandleSize: const Size(32, 4),
    );
  }

  // Material 3 Dialog Theme
  static DialogThemeData _buildDialogTheme(ColorScheme colorScheme) {
    return DialogThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 6,
      titleTextStyle: AppTypography.titleLarge.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: AppTypography.bodyMedium.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  // Input Decoration Theme
  static InputDecorationTheme _buildInputDecorationTheme(
    ColorScheme colorScheme,
  ) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      focusColor: colorScheme.primary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      labelStyle: AppTypography.bodyMedium.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      errorStyle: AppTypography.bodySmall.copyWith(color: colorScheme.error),
    );
  }

  // Scrollbar Theme for better accessibility
  static ScrollbarThemeData _buildScrollbarTheme() {
    return ScrollbarThemeData(
      thickness: WidgetStateProperty.all<double>(6),
      radius: const Radius.circular(3),
      thumbVisibility: WidgetStateProperty.all<bool>(true),
      trackVisibility: WidgetStateProperty.all<bool>(false),
      interactive: true,
    );
  }

  // Custom Theme Extensions
  static ThemeExtension<_AppThemeExtensions> _buildThemeExtensions() {
    return const _AppThemeExtensions(
      successColor: Color(0xFF4CAF50),
      warningColor: Color(0xFFFF9800),
      infoColor: Color(0xFF2196F3),
      premiumGradient: LinearGradient(
        colors: [Color(0xFF795547), Color(0xFF5D4037)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }
}

// Theme Extension for custom design tokens
class _AppThemeExtensions extends ThemeExtension<_AppThemeExtensions> {
  const _AppThemeExtensions({
    required this.successColor,
    required this.warningColor,
    required this.infoColor,
    required this.premiumGradient,
  });

  final Color successColor;
  final Color warningColor;
  final Color infoColor;
  final LinearGradient premiumGradient;

  @override
  ThemeExtension<_AppThemeExtensions> copyWith({
    Color? successColor,
    Color? warningColor,
    Color? infoColor,
    LinearGradient? premiumGradient,
  }) {
    return _AppThemeExtensions(
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      infoColor: infoColor ?? this.infoColor,
      premiumGradient: premiumGradient ?? this.premiumGradient,
    );
  }

  @override
  ThemeExtension<_AppThemeExtensions> lerp(
    ThemeExtension<_AppThemeExtensions>? other,
    double t,
  ) {
    if (other is! _AppThemeExtensions) return this;
    return _AppThemeExtensions(
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      infoColor: Color.lerp(infoColor, other.infoColor, t)!,
      premiumGradient: premiumGradient,
    );
  }
}
