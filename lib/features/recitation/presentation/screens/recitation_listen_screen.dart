import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../providers/recitation_controller.dart';

/// Audio-first listening for blind and low-vision users: one large area
/// that says where playback is (announced as it changes), swipes or
/// screen-reader adjust gestures for the next and previous ayah, and three
/// large buttons. Works with downloaded recitations offline.
class RecitationListenScreen extends StatelessWidget {
  const RecitationListenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final theme = Theme.of(context);
    final c = context.watch<RecitationController>();
    final int? surah = c.surah;
    final int? ayah = c.currentAyah;
    final bool busy =
        c.status == RecitationStatus.loading ||
        c.status == RecitationStatus.buffering;
    final String where = surah == null
        ? l10n.listenModeNothing
        : context.digits(
            l10n.listenModeNowPlaying(c.surahName(surah), '${ayah ?? 1}'),
          );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.listenModeTitle)),
      // Fills the screen, and scrolls instead when large text needs more.
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 64,
                      child: FilledButton.tonalIcon(
                        key: const Key('listen-choose-surah'),
                        icon: const Icon(Icons.list_rounded, size: 28),
                        label: Text(
                          l10n.listenModeChooseSurah,
                          style: theme.textTheme.titleLarge,
                        ),
                        onPressed: () => _chooseSurah(context, c),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: Semantics(
                        liveRegion: true,
                        label: l10n.listenModeTitle,
                        value: busy
                            ? '$where${l10n.listSeparator}${l10n.listenModeLoading}'
                            : where,
                        increasedValue: l10n.listenModeNext,
                        decreasedValue: l10n.listenModePrevious,
                        onIncrease: surah == null ? null : c.nextAyah,
                        onDecrease: surah == null ? null : c.previousAyah,
                        excludeSemantics: true,
                        child: GestureDetector(
                          key: const Key('listen-swipe-area'),
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragEnd: surah == null
                              ? null
                              : (details) {
                                  final v = details.primaryVelocity ?? 0;
                                  if (v.abs() < 200) return;
                                  unawaited(
                                    v < 0 ? c.nextAyah() : c.previousAyah(),
                                  );
                                },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  where,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineMedium,
                                ),
                                if (busy) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  Text(l10n.listenModeLoading),
                                ],
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  l10n.listenModeHelp,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        _BigButton(
                          key: const Key('listen-previous'),
                          icon: Icons.skip_next_rounded,
                          label: l10n.listenModePrevious,
                          onPressed: surah == null ? null : c.previousAyah,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _BigButton(
                          key: const Key('listen-play'),
                          icon: c.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          label: c.isPlaying
                              ? l10n.listenModePause
                              : l10n.listenModePlay,
                          filled: true,
                          onPressed: surah == null && c.resumePoint == null
                              ? () => _chooseSurah(context, c)
                              : c.togglePlay,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _BigButton(
                          key: const Key('listen-next'),
                          icon: Icons.skip_previous_rounded,
                          label: l10n.listenModeNext,
                          onPressed: surah == null ? null : c.nextAyah,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseSurah(
    BuildContext context,
    RecitationController c,
  ) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.8,
          child: ListView.builder(
            itemCount: 114,
            itemBuilder: (context, i) => ListTile(
              minTileHeight: 56,
              title: Text(
                context.digits('${i + 1}. ${c.surahName(i + 1)}'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              onTap: () => Navigator.pop(context, i + 1),
            ),
          ),
        ),
      ),
    );
    if (picked != null) await c.playSurah(picked);
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 96)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 40),
        Text(label, textAlign: TextAlign.center),
      ],
    );
    // The button's own semantics carry the label (from the text) and the
    // enabled state, so screen readers can activate it.
    return Expanded(
      child: filled
          ? FilledButton(style: style, onPressed: onPressed, child: child)
          : OutlinedButton(style: style, onPressed: onPressed, child: child),
    );
  }
}
