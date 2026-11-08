part of '../home_screen.dart';

class _PrayerTimeHeader extends StatelessWidget {
  const _PrayerTimeHeader();

  static String _clock(DateTime t) {
    final period = t.hour >= 12
        ? appL10n.alarmMenuItemMessage2
        : appL10n.alarmMenuItemMessage3;
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h:${t.minute.toString().padLeft(2, '0')} $period';
  }

  static String _duration(Duration d) {
    final minutes = d.inMinutes.clamp(0, 24 * 60);
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return h > 0
        ? appL10n.prayerTimesWidgetMessage15('$h', '$m')
        : appL10n.prayerTimesWidgetMessage16('$m');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = l10nOf(context);
    final onPrimary = theme.colorScheme.onPrimary;

    return Consumer<PrayerTimesProvider>(
      builder: (context, provider, child) {
        final next = provider.nextPrayer;
        final String title;
        final String? countdown;
        final String? at;
        if (next != null) {
          title = next.name;
          countdown = l10n.homeTimeLeft(
            context.digits(_duration(next.remaining)),
          );
          at = l10n.homeAtTime(context.digits(_clock(next.wallTime)));
        } else {
          title = provider.needsLocation
              ? l10n.choosePrayerLocation
              : l10n.prayerTimesWidgetMessage4;
          countdown = null;
          at = null;
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.72),
                theme.colorScheme.tertiary.withValues(alpha: 0.58),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Faint geometric ornament in the chosen design's style.
              Positioned.fill(
                child: GeometricPattern(
                  pattern: SakinaDecor.of(context).pattern,
                  color: onPrimary.withValues(alpha: 0.12),
                ),
              ),
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  // The whole header opens the full prayer times.
                  onTap: () => context.push('/prayers'),
                  child: Semantics(
                    button: true,
                    label: next == null
                        ? title
                        : l10n.homeNextPrayerSemantics(
                            next.name,
                            context.digits(_duration(next.remaining)),
                            context.digits(_clock(next.wallTime)),
                          ),
                    excludeSemantics: true,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        // Bottom space keeps clear of the collapsing app title.
                        padding: const EdgeInsets.fromLTRB(24, 56, 24, 52),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.homeNextPrayer,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: onPrimary.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: next == null ? 22 : 36,
                                fontWeight: FontWeight.w900,
                                color: onPrimary,
                                height: 1.15,
                              ),
                            ),
                            if (countdown != null)
                              Text(
                                countdown,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            if (at != null) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '$at • ${provider.locationLabel}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: onPrimary.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
