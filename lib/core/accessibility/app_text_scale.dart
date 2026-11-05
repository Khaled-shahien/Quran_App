import 'package:flutter/widgets.dart';

/// The system text scaler multiplied by the app's own text-size choice.
///
/// Keeps the system's (possibly non-linear) scaling and applies the app
/// factor on top, so an enlarged phone setting is never reduced.
class AppTextScaler extends TextScaler {
  const AppTextScaler(this.system, this.factor);

  final TextScaler system;
  final double factor;

  @override
  double scale(double fontSize) => system.scale(fontSize) * factor;

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => system.textScaleFactor * factor;

  @override
  bool operator ==(Object other) =>
      other is AppTextScaler &&
      other.system == system &&
      other.factor == factor;

  @override
  int get hashCode => Object.hash(system, factor);
}

/// Applies the app text size to everything below it.
class AppTextScale extends StatelessWidget {
  const AppTextScale({super.key, required this.factor, required this.child});

  final double factor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (factor == 1.0) return child;
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(textScaler: AppTextScaler(media.textScaler, factor)),
      child: child,
    );
  }
}

/// Restores the system text scale for content that has its own size
/// control, such as the Quran page.
class SystemTextScale extends StatelessWidget {
  const SystemTextScale({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scaler = media.textScaler;
    if (scaler is! AppTextScaler) return child;
    return MediaQuery(
      data: media.copyWith(textScaler: scaler.system),
      child: child,
    );
  }
}
