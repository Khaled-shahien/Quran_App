import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../prayers/presentation/providers/prayer_times_provider.dart';

class PrayerTimeHeader extends StatelessWidget {
  const PrayerTimeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<PrayerTimesProvider>(
      builder: (context, provider, child) {
        final prayerData = provider.getCurrentAndNextPrayer();
        final currentName = prayerData['currentName'] ?? '---';
        final currentTime = prayerData['currentTime'] ?? '--:--';
        final nextName = prayerData['nextName'] ?? '---';
        final nextTime = prayerData['nextTime'] ?? '--:--';

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
            fit: StackFit.expand,
            children: [
              PositionedDirectional(
                top: -50,
                end: -20,
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 170,
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.08),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 56, 24, 52),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        currentName,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.78,
                          ),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        currentTime,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onPrimary,
                          height: 1.05,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.13,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: theme.colorScheme.onPrimary.withValues(
                              alpha: 0.18,
                            ),
                          ),
                          boxShadow: AppShadows.subtle,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 18,
                              color: theme.colorScheme.onPrimary.withValues(
                                alpha: 0.84,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'الصلاة التالية: $nextName',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimary.withValues(
                                    alpha: 0.82,
                                  ),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              nextTime,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
