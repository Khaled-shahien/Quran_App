import 'package:flutter/material.dart';

/// Formerly painted a noise texture behind the app. The texture sat under
/// opaque screens, so it was never visible while costing a large path on
/// every resize. Kept as a pass-through so existing imports keep working.
class NoiseBackground extends StatelessWidget {
  const NoiseBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
