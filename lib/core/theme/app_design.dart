import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The app's three visual directions, chosen in Settings.
enum AppDesign {
  /// Warm paper: the original brown and cream identity (default).
  warm,

  /// Calm green with sand accents.
  sage,

  /// Navy and gold; always dark.
  night;

  /// Night is a dark-only design: it ignores the light/dark setting.
  bool get alwaysDark => this == AppDesign.night;
}

/// The geometric ornament drawn behind headers.
enum DecorPattern { star, rings }

/// Design colours that widgets need beyond [ColorScheme].
@immutable
class SakinaDecor extends ThemeExtension<SakinaDecor> {
  const SakinaDecor({
    required this.accent,
    required this.onAccent,
    required this.card,
    required this.featureCard,
    required this.pattern,
    this.heroColors = _warmHero,
  });

  static const List<Color> _warmHero = [Color(0xCCFFB300), Color(0xF23E2723)];

  /// Highlights: selected tabs, progress, undo actions.
  final Color accent;

  /// Text or icons placed on [accent].
  final Color onAccent;

  /// Plain content cards.
  final Color card;

  /// The deep card behind light text (daily verse, drawer header, toasts).
  final Color featureCard;

  final DecorPattern pattern;

  /// Background of the next-prayer cards; white text sits on it.
  final List<Color> heroColors;

  static const SakinaDecor warmLight = SakinaDecor(
    accent: AppColors.lightPageAccent,
    onAccent: AppColors.white,
    card: AppColors.white,
    featureCard: AppColors.darkCard,
    pattern: DecorPattern.star,
  );

  static const SakinaDecor warmDark = SakinaDecor(
    accent: AppColors.lightPageAccent,
    onAccent: AppColors.white,
    card: AppColors.darkCardContent,
    featureCard: AppColors.darkCard,
    pattern: DecorPattern.star,
  );

  /// Falls back to the original look where no app theme is installed.
  static SakinaDecor of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<SakinaDecor>() ??
        (theme.brightness == Brightness.dark ? warmDark : warmLight);
  }

  @override
  SakinaDecor copyWith({
    Color? accent,
    Color? onAccent,
    Color? card,
    Color? featureCard,
    DecorPattern? pattern,
    List<Color>? heroColors,
  }) => SakinaDecor(
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    card: card ?? this.card,
    featureCard: featureCard ?? this.featureCard,
    pattern: pattern ?? this.pattern,
    heroColors: heroColors ?? this.heroColors,
  );

  @override
  SakinaDecor lerp(ThemeExtension<SakinaDecor>? other, double t) {
    if (other is! SakinaDecor) return this;
    return SakinaDecor(
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      card: Color.lerp(card, other.card, t)!,
      featureCard: Color.lerp(featureCard, other.featureCard, t)!,
      pattern: t < 0.5 ? pattern : other.pattern,
      heroColors: t < 0.5 ? heroColors : other.heroColors,
    );
  }
}

/// Every colour one design needs in one brightness.
@immutable
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.background,
    required this.text,
    required this.body,
    required this.caption,
    required this.outline,
    required this.decor,
  });

  final Brightness brightness;
  final Color primary;
  final Color onPrimary;

  /// Tiles and chips.
  final Color secondary;
  final Color onSecondary;
  final Color background;

  /// Headings and strong text.
  final Color text;

  /// Body text.
  final Color body;

  /// Small captions; still at least 4.5:1 on [background].
  final Color caption;

  /// Borders of inputs and outlined controls (at least 3:1).
  final Color outline;
  final SakinaDecor decor;

  static const AppPalette sageLight = AppPalette(
    brightness: Brightness.light,
    primary: Color(0xFF1F5C4A),
    onPrimary: Color(0xFFF6F4EE),
    secondary: Color(0xFFE3EDE7),
    onSecondary: Color(0xFF1C2723),
    background: Color(0xFFF6F4EE),
    text: Color(0xFF1C2723),
    body: Color(0xFF3E4C46),
    caption: Color(0xFF4F5E57),
    outline: Color(0xFF6F7E77),
    decor: SakinaDecor(
      accent: Color(0xFF8A6A2E),
      onAccent: Color(0xFFFFFFFF),
      card: Color(0xFFFFFFFF),
      featureCard: Color(0xFF16463A),
      pattern: DecorPattern.rings,
      heroColors: [Color(0xFF2A7560), Color(0xFF16463A)],
    ),
  );

  static const AppPalette sageDark = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFF8FC7AE),
    onPrimary: Color(0xFF0F1714),
    secondary: Color(0xFF1E2C26),
    onSecondary: Color(0xFFE8EFEA),
    background: Color(0xFF0F1714),
    text: Color(0xFFE8EFEA),
    body: Color(0xFFC9D3CD),
    caption: Color(0xFFA3B1AA),
    outline: Color(0xFF7A8C84),
    decor: SakinaDecor(
      accent: Color(0xFFC9A66B),
      onAccent: Color(0xFF0F1714),
      card: Color(0xFF16211C),
      featureCard: Color(0xFF16463A),
      pattern: DecorPattern.rings,
      heroColors: [Color(0xFF1F5C4A), Color(0xFF0F2E25)],
    ),
  );

  static const AppPalette night = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFFD4AF6A),
    onPrimary: Color(0xFF101826),
    secondary: Color(0xFF22304A),
    onSecondary: Color(0xFFEDE3CF),
    background: Color(0xFF101826),
    text: Color(0xFFEDE3CF),
    body: Color(0xFFD5CCBA),
    caption: Color(0xFFA9B2C3),
    outline: Color(0xFF6B7A99),
    decor: SakinaDecor(
      accent: Color(0xFFD4AF6A),
      onAccent: Color(0xFF101826),
      card: Color(0xFF182235),
      featureCard: Color(0xFF0B1220),
      pattern: DecorPattern.star,
      heroColors: [Color(0xFF2A3A5C), Color(0xFF0B1220)],
    ),
  );
}
