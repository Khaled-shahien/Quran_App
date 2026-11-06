import 'package:flutter/material.dart';

import '../../features/recitation/presentation/widgets/recitation_mini_player.dart';
import '../theme/noise_background.dart';

/// What surrounds every screen: the background and, below the screens, the
/// recitation mini player.
///
/// This sits in [MaterialApp.builder], above the Navigator and therefore
/// above the Navigator's Overlay.
class AppFrame extends StatelessWidget {
  const AppFrame({super.key, required this.child, required this.sheetContext});

  final Widget child;
  final BuildContext? Function() sheetContext;

  @override
  Widget build(BuildContext context) {
    // The mini player's buttons have tooltips, and tooltips need an Overlay.
    // The Navigator's Overlay is below this widget, so provide one here;
    // without it the app crashes with "No Overlay widget found".
    return Overlay.wrap(
      child: NoiseBackground(
        child: Column(
          children: [
            Expanded(child: child),
            // Stays visible on every screen while a surah is loaded.
            RecitationMiniPlayer(sheetContext: sheetContext),
          ],
        ),
      ),
    );
  }
}
