import 'package:sakina_app/core/theme/app_design.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'dart:async';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pulse_loader.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../prayers/presentation/providers/prayer_times_provider.dart';

class PrayerTimesWidget extends StatefulWidget {
  const PrayerTimesWidget({super.key});

  @override
  State<PrayerTimesWidget> createState() => _PrayerTimesWidgetState();
}

class _PrayerTimesWidgetState extends State<PrayerTimesWidget> {
  late Timer _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Initialize with a default location (Cairo coordinates)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prayerProvider = Provider.of<PrayerTimesProvider>(
        context,
        listen: false,
      );
      prayerProvider.fetchTodayForCurrentLocation();
    });

    // Update countdown every second
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerTimesProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: PulseLoader(lines: 4),
            ),
          );
        }

        if (provider.needsLocation) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.ms),
                Text(
                  l10nOf(context).choosePrayerLocation,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.tonal(
                  onPressed: () => context.push('/prayers'),
                  child: Text(l10nOf(context).prayerTimesWidgetMessage2),
                ),
              ],
            ),
          );
        }

        if (provider.hasError) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10nOf(context).prayerTimesWidgetMessage1,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/prayers'),
                  child: Text(l10nOf(context).prayerTimesWidgetMessage2),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  provider.errorMessage ??
                      l10nOf(context).prayerTimesWidgetMessage3,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (provider.hasData) {
          return _buildPrayerTimesContent(provider);
        }

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            l10nOf(context).prayerTimesWidgetMessage4,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrayerTimesContent(PrayerTimesProvider provider) {
    final prayerTimes = provider.getMainPrayerTimes();
    // Filter out Sunrise as it's not a prayer
    final mainPrayers = Map<String, String>.fromEntries(
      prayerTimes.entries.where((e) => e.key != 'Sunrise'),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Next Prayer Card
          _buildNextPrayerCard(mainPrayers),
          SectionHeader(
            title: appL10n.prayerTimesWidgetMessage5,
            padding: const EdgeInsets.only(
              top: AppSpacing.lg,
              bottom: AppSpacing.ms,
            ),
          ),
          // Prayer Times List
          _buildPrayerTimesList(mainPrayers),
        ],
      ),
    );
  }

  Widget _buildNextPrayerCard(Map<String, String> prayerTimes) {
    final nextPrayerInfo = _getNextPrayer(prayerTimes);
    final nextPrayerName = nextPrayerInfo['name'] as String;
    final nextPrayerTime = context.digits(nextPrayerInfo['time'] as String);
    final timeRemaining = context.digits(nextPrayerInfo['remaining'] as String);

    final decor = SakinaDecor.of(context);
    final text = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: AppRadius.hero,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: decor.heroColors,
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Next Prayer Label
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                appL10n.prayerTimesWidgetMessage6,
                style: text.labelLarge?.copyWith(color: decor.onFeatureMuted),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Prayer Name
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                nextPrayerName,
                style: text.displaySmall?.copyWith(
                  color: decor.onFeature,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Prayer Time and Remaining Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appL10n.prayerTimesWidgetMessage7,
                      style: text.labelMedium?.copyWith(
                        color: decor.onFeatureMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      timeRemaining,
                      style: text.titleSmall?.copyWith(color: decor.onFeature),
                    ),
                  ],
                ),
                Text(
                  nextPrayerTime,
                  style: AppTypography.numeral.copyWith(
                    fontSize: 36,
                    color: decor.onFeature,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimesList(Map<String, String> prayerTimes) {
    final arabicNames = {
      'Fajr': appL10n.prayerTimesWidgetMessage8,
      'Dhuhr': appL10n.prayerTimesWidgetMessage9,
      'Asr': appL10n.prayerTimesWidgetMessage10,
      'Maghrib': appL10n.prayerTimesWidgetMessage11,
      'Isha': appL10n.prayerTimesWidgetMessage12,
    };

    final nextPrayerInfo = _getNextPrayer(prayerTimes);
    final currentPrayerName = nextPrayerInfo['name'] as String;

    return Column(
      children: prayerTimes.entries.map((entry) {
        final arabicName = arabicNames[entry.key] ?? entry.key;
        final isCurrentPrayer = arabicName == currentPrayerName;

        return _prayerTimeTile(
          prayerName: arabicName,
          prayerTime: context.digits(entry.value),
          isNext: isCurrentPrayer,
        );
      }).toList(),
    );
  }

  Widget _prayerTimeTile({
    required String prayerName,
    required String prayerTime,
    required bool isNext,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Semantics(
      selected: isNext,
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.base),
        curve: AppMotion.standard,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.ms,
        ),
        decoration: BoxDecoration(
          color: isNext ? scheme.secondary : SakinaDecor.of(context).card,
          borderRadius: AppRadius.controls,
          border: Border.all(
            color: isNext ? scheme.primary : scheme.outlineVariant,
            width: isNext ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // The next prayer is marked by a dot as well as by colour.
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isNext ? scheme.primary : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.ms),
            Expanded(
              child: Text(
                prayerName,
                style: text.titleMedium?.copyWith(
                  color: isNext ? scheme.onSecondary : scheme.onSurface,
                  fontWeight: isNext ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
            Text(
              prayerTime,
              style: text.titleMedium?.copyWith(
                color: isNext ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get next prayer information
  Map<String, dynamic> _getNextPrayer(Map<String, String> prayerTimes) {
    final next = context.read<PrayerTimesProvider>().nextPrayer;
    if (next == null) {
      return {
        'name': appL10n.prayerTimesWidgetMessage13,
        'time': '--:--',
        'remaining': appL10n.prayerTimesWidgetMessage14,
      };
    }

    final timeRemaining = next.remaining.isNegative
        ? Duration.zero
        : next.remaining;
    final hoursStr = timeRemaining.inHours.toString();
    final minutesStr = (timeRemaining.inMinutes % 60).toString();

    final String remainingText = timeRemaining.inHours > 0
        ? appL10n.prayerTimesWidgetMessage15(hoursStr, minutesStr)
        : appL10n.prayerTimesWidgetMessage16(minutesStr);

    return {
      'name': next.name,
      'time': _formatTimeForDisplay(next.wallTime),
      'remaining': remainingText,
    };
  }

  /// Format time for display
  String _formatTimeForDisplay(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
