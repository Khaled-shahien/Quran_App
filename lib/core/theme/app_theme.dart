import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_design.dart';
import 'app_motion.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Builds every theme from an [AppPalette], so the three designs differ in
/// colour only and share one set of component styles.
class AppTheme {
  static ThemeData get lightTheme => _fromPalette(AppPalette.warmLight);

  static ThemeData get darkTheme => _fromPalette(AppPalette.warmDark);

  /// Warm, low-blue palette for reading the Quran at night. Text on page
  /// contrast is about 12:1 (WCAG AAA).
  static const Color nightPaper = Color(0xFF17120D);
  static const Color nightPage = Color(0xFF221A12);
  static const Color nightText = Color(0xFFE9D8B9);

  static ThemeData get nightReadingTheme {
    final base = darkTheme;
    return base.copyWith(
      scaffoldBackgroundColor: nightPaper,
      colorScheme: base.colorScheme.copyWith(
        primary: nightText,
        onPrimary: nightPaper,
        surface: nightPaper,
        onSurface: nightText,
        surfaceContainerHigh: nightPage,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: nightPaper,
        foregroundColor: nightText,
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: nightPage,
      ),
    );
  }

  /// Light theme for [design]. Night is dark-only, so it returns its dark
  /// theme here too.
  static ThemeData light(AppDesign design) => switch (design) {
    AppDesign.warm => lightTheme,
    AppDesign.sage => _fromPalette(AppPalette.sageLight),
    AppDesign.night => _fromPalette(AppPalette.night),
  };

  static ThemeData dark(AppDesign design) => switch (design) {
    AppDesign.warm => darkTheme,
    AppDesign.sage => _fromPalette(AppPalette.sageDark),
    AppDesign.night => _fromPalette(AppPalette.night),
  };

  static ColorScheme _scheme(AppPalette p) {
    final bool dark = p.brightness == Brightness.dark;
    final Color error = dark
        ? const Color(0xFFF2A6A0)
        : const Color(0xFFB3261E);
    return ColorScheme.fromSeed(
      seedColor: p.primary,
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: p.secondary,
      onPrimaryContainer: p.onSecondary,
      secondary: p.secondary,
      onSecondary: p.onSecondary,
      secondaryContainer: p.secondary,
      onSecondaryContainer: p.onSecondary,
      tertiary: p.decor.accent,
      onTertiary: p.decor.onAccent,
      surface: p.background,
      onSurface: p.text,
      onSurfaceVariant: p.caption,
      // Material surfaces step from the page to the tile colour, so menus,
      // sheets and cards stay inside the palette.
      surfaceContainerLowest: p.decor.card,
      surfaceContainerLow: p.decor.card,
      surfaceContainer: Color.lerp(p.background, p.secondary, 0.5)!,
      surfaceContainerHigh: p.secondary,
      surfaceContainerHighest: Color.lerp(p.secondary, p.outline, 0.18)!,
      surfaceTint: Colors.transparent,
      error: error,
      onError: dark ? const Color(0xFF3B0D0A) : AppColors.white,
      errorContainer: Color.alphaBlend(
        error.withValues(alpha: 0.16),
        p.background,
      ),
      onErrorContainer: p.text,
      outline: p.outline,
      outlineVariant: Color.alphaBlend(
        p.outline.withValues(alpha: 0.28),
        p.background,
      ),
      shadow: const Color(0xFF2A1F1A),
      scrim: Colors.black,
      inverseSurface: p.decor.featureCard,
      onInverseSurface: p.decor.onFeature,
      inversePrimary: p.decor.accent,
    );
  }

  static ThemeData _fromPalette(AppPalette p) {
    final ColorScheme scheme = _scheme(p);
    final TextTheme text = _textTheme(p);
    const OutlinedBorder controlShape = RoundedRectangleBorder(
      borderRadius: AppRadius.controls,
    );
    const EdgeInsets buttonPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.ms,
    );
    const Size buttonMin = Size(64, AppSpacing.touchTarget);
    final TextStyle buttonText = AppTypography.labelLarge.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w700,
    );
    final Color focus = scheme.primary.withValues(alpha: 0.14);
    final Color press = scheme.primary.withValues(alpha: 0.10);
    final Color hover = scheme.primary.withValues(alpha: 0.06);

    Color? overlay(Set<WidgetState> states, Color base) {
      if (states.contains(WidgetState.pressed)) {
        return base.withValues(alpha: 0.12);
      }
      if (states.contains(WidgetState.focused)) {
        return base.withValues(alpha: 0.14);
      }
      if (states.contains(WidgetState.hovered)) {
        return base.withValues(alpha: 0.08);
      }
      return null;
    }

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      // One UI font for the whole app; Quran text sets its own font.
      fontFamily: AppTypography.uiFontFamily,
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      splashFactory: InkSparkle.splashFactory,
      splashColor: press,
      highlightColor: Colors.transparent,
      hoverColor: hover,
      focusColor: focus,
      dividerColor: scheme.outlineVariant,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      // Automatic back buttons use the same chevron as the screens that
      // set their own; it mirrors in right-to-left layouts.
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (_) => const Icon(Icons.arrow_back_ios),
      ),
      iconTheme: IconThemeData(color: p.text, size: 24),
      primaryIconTheme: IconThemeData(color: p.onPrimary, size: 24),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        // Stated outright: an app bar with a transparent background would
        // otherwise guess, and draw white status icons on light paper.
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: p.brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
          statusBarBrightness: p.brightness,
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(color: p.text),
        iconTheme: IconThemeData(color: p.text, size: 24),
        actionsIconTheme: IconThemeData(color: p.text, size: 24),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? p.text.withValues(alpha: 0.12)
                : p.primary,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? p.text.withValues(alpha: 0.38)
                : p.onPrimary,
          ),
          overlayColor: WidgetStateProperty.resolveWith(
            (s) => overlay(s, p.onPrimary),
          ),
          elevation: const WidgetStatePropertyAll(0),
          textStyle: WidgetStatePropertyAll(buttonText),
          padding: const WidgetStatePropertyAll(buttonPadding),
          minimumSize: const WidgetStatePropertyAll(buttonMin),
          shape: const WidgetStatePropertyAll(controlShape),
          animationDuration: AppMotion.fast,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: buttonText,
          padding: buttonPadding,
          minimumSize: buttonMin,
          shape: controlShape,
          animationDuration: AppMotion.fast,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? p.text.withValues(alpha: 0.38)
                : p.primary,
          ),
          overlayColor: WidgetStateProperty.resolveWith(
            (s) => overlay(s, p.primary),
          ),
          side: WidgetStateProperty.resolveWith(
            (s) => BorderSide(
              color: s.contains(WidgetState.disabled)
                  ? p.text.withValues(alpha: 0.16)
                  : s.contains(WidgetState.focused)
                  ? p.primary
                  : p.outline,
              width: s.contains(WidgetState.focused) ? 2 : 1,
            ),
          ),
          textStyle: WidgetStatePropertyAll(buttonText),
          padding: const WidgetStatePropertyAll(buttonPadding),
          minimumSize: const WidgetStatePropertyAll(buttonMin),
          shape: const WidgetStatePropertyAll(controlShape),
          animationDuration: AppMotion.fast,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: buttonText,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          minimumSize: const Size(AppSpacing.touchTarget, 44),
          shape: controlShape,
          animationDuration: AppMotion.fast,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppSpacing.touchTarget),
          shape: const CircleBorder(),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        elevation: 2,
        focusElevation: 3,
        highlightElevation: 1,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          // A locked control still shows its choice legibly: the selected
          // segment drops to the tile colour instead of fading its label.
          backgroundColor: WidgetStateProperty.resolveWith((s) {
            if (!s.contains(WidgetState.selected)) return Colors.transparent;
            return s.contains(WidgetState.disabled) ? p.secondary : p.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((s) {
            final bool selected = s.contains(WidgetState.selected);
            if (s.contains(WidgetState.disabled)) {
              return selected ? p.onSecondary : p.text.withValues(alpha: 0.38);
            }
            return selected ? p.onPrimary : p.text;
          }),
          side: WidgetStatePropertyAll(BorderSide(color: p.outline)),
          textStyle: WidgetStatePropertyAll(
            AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          shape: const WidgetStatePropertyAll(controlShape),
          minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
          animationDuration: AppMotion.base,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled)
              ? p.text.withValues(alpha: 0.38)
              : s.contains(WidgetState.selected)
              ? p.onPrimary
              : p.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled)
              ? p.text.withValues(alpha: 0.10)
              : s.contains(WidgetState.selected)
              ? p.primary
              : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? Colors.transparent : p.outline,
        ),
        overlayColor: WidgetStateProperty.resolveWith(
          (s) => overlay(s, p.primary),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.primary : null,
        ),
        checkColor: WidgetStatePropertyAll(p.onPrimary),
        side: BorderSide(color: p.outline, width: 1.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.xs)),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled)
              ? p.text.withValues(alpha: 0.38)
              : s.contains(WidgetState.selected)
              ? p.primary
              : p.outline,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: p.primary,
        overlayColor: press,
        trackHeight: 4,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
        linearMinHeight: 6,
        borderRadius: AppRadius.pill,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.secondary,
        selectedColor: p.primary,
        disabledColor: p.text.withValues(alpha: 0.08),
        labelStyle: AppTypography.labelMedium.copyWith(color: p.onSecondary),
        secondaryLabelStyle: AppTypography.labelMedium.copyWith(
          color: p.onPrimary,
        ),
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.ms,
          vertical: AppSpacing.xs,
        ),
        showCheckmark: false,
      ),
      cardTheme: CardThemeData(
        color: p.decor.card,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x1F2A1F1A),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.primary,
        textColor: p.text,
        titleTextStyle: AppTypography.titleMedium.copyWith(color: p.text),
        subtitleTextStyle: AppTypography.bodySmall.copyWith(color: p.caption),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        minVerticalPadding: AppSpacing.ms,
        horizontalTitleGap: AppSpacing.md,
        shape: controlShape,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.decor.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.secondary,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => AppTypography.labelMedium.copyWith(
            color: s.contains(WidgetState.selected) ? p.primary : p.caption,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w600,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? p.primary : p.caption,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.primary,
        unselectedLabelColor: p.caption,
        indicatorColor: p.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: scheme.outlineVariant,
        labelStyle: AppTypography.labelLarge.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: AppTypography.labelLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.background,
        modalBackgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
        elevation: 0,
        modalElevation: 0,
        modalBarrierColor: Colors.black.withValues(alpha: 0.45),
        showDragHandle: false,
        dragHandleColor: p.outline.withValues(alpha: 0.6),
        dragHandleSize: const Size(36, 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.decor.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.dialog),
        elevation: 0,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        titleTextStyle: AppTypography.titleLarge.copyWith(color: p.text),
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: p.body),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.decor.featureCard,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: p.decor.onFeature,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: p.decor.accent,
        closeIconColor: p.decor.onFeature,
        elevation: 4,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.controls),
      ),
      bannerTheme: MaterialBannerThemeData(
        backgroundColor: p.secondary,
        surfaceTintColor: Colors.transparent,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: p.onSecondary,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.ms,
          AppSpacing.sm,
          AppSpacing.xs,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.decor.card,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: scheme.outlineVariant),
        ),
        textStyle: AppTypography.bodyMedium.copyWith(color: p.text),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(p.decor.card),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: AppRadius.card,
              side: BorderSide(color: scheme.outlineVariant),
            ),
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.decor.featureCard,
          borderRadius: AppRadius.chip,
        ),
        textStyle: AppTypography.labelMedium.copyWith(color: p.decor.onFeature),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.ms,
          vertical: AppSpacing.sm,
        ),
        waitDuration: const Duration(milliseconds: 500),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        scrimColor: Colors.black.withValues(alpha: 0.45),
        elevation: 0,
      ),
      inputDecorationTheme: _inputTheme(p, scheme),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll<double>(4),
        radius: const Radius.circular(AppRadius.xs),
        thumbColor: WidgetStatePropertyAll(p.outline.withValues(alpha: 0.5)),
        interactive: true,
      ),
      extensions: [p.decor],
    );
  }

  static TextTheme _textTheme(AppPalette p) => TextTheme(
    displayLarge: AppTypography.displayLarge.copyWith(color: p.text),
    displayMedium: AppTypography.displayMedium.copyWith(color: p.text),
    displaySmall: AppTypography.displaySmall.copyWith(color: p.text),
    headlineLarge: AppTypography.headlineLarge.copyWith(color: p.text),
    headlineMedium: AppTypography.headlineMedium.copyWith(color: p.text),
    headlineSmall: AppTypography.headlineSmall.copyWith(color: p.text),
    titleLarge: AppTypography.titleLarge.copyWith(color: p.text),
    titleMedium: AppTypography.titleMedium.copyWith(color: p.text),
    titleSmall: AppTypography.titleSmall.copyWith(color: p.text),
    bodyLarge: AppTypography.bodyLarge.copyWith(color: p.body),
    bodyMedium: AppTypography.bodyMedium.copyWith(color: p.body),
    bodySmall: AppTypography.bodySmall.copyWith(color: p.caption),
    labelLarge: AppTypography.labelLarge.copyWith(color: p.text),
    labelMedium: AppTypography.labelMedium.copyWith(color: p.text),
    labelSmall: AppTypography.labelSmall.copyWith(color: p.caption),
  );

  static InputDecorationTheme _inputTheme(AppPalette p, ColorScheme scheme) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.controls,
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecorationTheme(
      filled: true,
      fillColor: p.decor.card,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.ms,
      ),
      border: border(p.outline),
      enabledBorder: border(p.outline.withValues(alpha: 0.6)),
      disabledBorder: border(p.outline.withValues(alpha: 0.25)),
      focusedBorder: border(p.primary, 2),
      errorBorder: border(scheme.error),
      focusedErrorBorder: border(scheme.error, 2),
      labelStyle: AppTypography.bodyMedium.copyWith(color: p.caption),
      floatingLabelStyle: AppTypography.labelLarge.copyWith(color: p.primary),
      hintStyle: AppTypography.bodyMedium.copyWith(color: p.caption),
      helperStyle: AppTypography.bodySmall.copyWith(color: p.caption),
      errorStyle: AppTypography.bodySmall.copyWith(color: scheme.error),
      prefixIconColor: p.caption,
      suffixIconColor: p.caption,
    );
  }
}
