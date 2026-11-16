import 'package:sakina_app/core/theme/app_design.dart';
import 'package:sakina_app/core/theme/app_motion.dart';
import 'package:sakina_app/core/theme/app_radius.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../providers/recitation_controller.dart';
import '../recitation_labels.dart';
import 'recitation_player_sheet.dart';

/// Compact player shown at the bottom of every screen while a surah is
/// loaded, so recitation stays in reach while the user moves around.
///
/// [sheetContext] must be below the app's Navigator (the bar itself sits
/// above it), so the full controls can open as a bottom sheet.
class RecitationMiniPlayer extends StatelessWidget {
  const RecitationMiniPlayer({super.key, required this.sheetContext});

  final BuildContext? Function() sheetContext;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<RecitationController>();
    final surah = c.surah;
    if (surah == null || !c.isActive) return const SizedBox.shrink();
    final l10n = l10nOf(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final busy =
        c.status == RecitationStatus.loading ||
        c.status == RecitationStatus.buffering;
    final error = c.status == RecitationStatus.error;
    final title = l10n.recitationNowPlaying(
      l10n.surahTitle(surah),
      context.digits(c.currentAyah ?? 1),
    );

    return Material(
      color: SakinaDecor.of(context).card,
      // A hairline, not a shadow, separates the player from the screen.
      shape: Border(top: BorderSide(color: scheme.outlineVariant)),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: () {
            final ctx = sheetContext();
            if (ctx != null) showRecitationPlayerSheet(ctx);
          },
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.ms,
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.secondary,
                    borderRadius: AppRadius.controls,
                  ),
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    color: scheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.ms),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall,
                        maxLines: 2,
                      ),
                      Text(
                        error
                            ? l10n.recitationFailure(c.failure)
                            : busy
                            ? l10n.recitationLoading
                            : c.reciter?.name ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: error ? scheme.error : scheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                if (busy)
                  Semantics(
                    label: l10n.recitationLoading,
                    child: const SizedBox.square(
                      dimension: 48,
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  )
                else
                  IconButton(
                    tooltip: error
                        ? l10n.retry
                        : c.isPlaying
                        ? l10n.recitationPause
                        : l10n.recitationPlay,
                    onPressed: c.togglePlay,
                    icon: AnimatedSwitcher(
                      duration: AppMotion.of(context, AppMotion.base),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Icon(
                        error
                            ? Icons.refresh_rounded
                            : c.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: ValueKey<String>(
                          error ? 'retry' : (c.isPlaying ? 'pause' : 'play'),
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  tooltip: l10n.recitationStop,
                  onPressed: c.stop,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
