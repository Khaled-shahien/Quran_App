import 'package:sakina_app/core/widgets/sakina_hero_app_bar.dart';
import 'package:sakina_app/core/theme/app_motion.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/core/theme/app_typography.dart';
import 'package:sakina_app/core/widgets/geometric_pattern.dart';
import 'package:sakina_app/core/widgets/section_header.dart';
import 'package:sakina_app/core/widgets/status_view.dart';
import 'package:sakina_app/core/theme/app_radius.dart';
import 'package:sakina_app/core/theme/app_design.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/l10n/localization.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_ar.dart';
import 'prayer_location_dialog.dart';
import '../../../onboarding/presentation/widgets/notification_permission_dialog.dart';
import '../../domain/prayer_calculation_policy.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'dart:async';
import '../../../../core/widgets/pulse_loader.dart';
import '../providers/prayer_times_provider.dart';
import '../widgets/exact_alarm_prompt.dart';

/// Prayer Times Screen
///
/// Displays prayer times for the current day with loading and error states
class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen>
    with WidgetsBindingObserver {
  late Timer _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load only the location explicitly configured by the user.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prayerProvider = Provider.of<PrayerTimesProvider>(
        context,
        listen: false,
      );
      unawaited(
        prayerProvider.fetchTodayForCurrentLocation().then((_) async {
          // Existing users who passed the notification prompt before the
          // exact-alarm request existed are asked here, once.
          if (mounted && prayerProvider.hasData) {
            await promptForExactAlarmsOnce(context);
          }
        }),
      );
    });

    // Update countdown every second
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      final provider = context.read<PrayerTimesProvider>();
      final loaded = provider.loadedDate;
      final now = context.read<PrayerTimesProvider>().locationNow;
      if (loaded != null &&
          (loaded.year != now.year ||
              loaded.month != now.month ||
              loaded.day != now.day)) {
        provider.refresh();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<PrayerTimesProvider>().refreshIfNeeded();
    }
  }

  AppLocalizations get l10n =>
      AppLocalizations.of(context) ?? AppLocalizationsAr();

  @override
  Widget build(BuildContext context) {
    return SakinaHeroScaffold(
      title: l10n.prayerTitle,
      actions: [
        IconButton(
          tooltip: l10nOf(context).prayerTimesScreenMessage1,
          icon: const Icon(Icons.edit_location_alt_outlined),
          onPressed: () => showPrayerLocationDialog(
            context,
            context.read<PrayerTimesProvider>(),
          ),
        ),
        IconButton(
          tooltip: l10nOf(context).prayerTimesScreenMessage2,
          icon: const Icon(Icons.my_location_rounded),
          onPressed: () async {
            final provider = context.read<PrayerTimesProvider>();
            await provider.useDeviceLocation();
            if (provider.hasData && context.mounted) {
              await promptForNotificationPermissionOnce(context);
            }
          },
        ),
      ],
      slivers: [
        // While Android would hold alerts until the screen is turned on.
        const SliverToBoxAdapter(child: ExactAlarmWarningCard()),
        Consumer<PrayerTimesProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: PulseLoader(lines: 6)),
              );
            }

            if (provider.hasError) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: StatusView.error(
                  message: l10n.prayerLoadError,
                  detail: l10nOf(context).prayerTimesWidgetMessage1,
                  footnote:
                      provider.errorMessage ??
                      l10nOf(context).prayerTimesWidgetMessage3,
                  actionLabel: l10n.retry,
                  actionSemanticLabel: l10nOf(
                    context,
                  ).prayerTimesScreenMessage3,
                  onAction: provider.fetchTodayForCurrentLocation,
                ),
              );
            }

            if (provider.hasData) {
              return SliverToBoxAdapter(
                child: _buildPrayerTimesContent(provider),
              );
            }

            return SliverFillRemaining(
              hasScrollBody: false,
              child: StatusView(
                icon: Icons.location_on_outlined,
                message: l10n.choosePrayerLocation,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPrayerTimesContent(PrayerTimesProvider provider) {
    final prayerTimes = provider.getMainPrayerTimes();
    final now = context.read<PrayerTimesProvider>().locationNow;
    final formattedDate = '${now.day}/${now.month}/${now.year}';
    final text = Theme.of(context).textTheme;

    // Scrolls with the page, under the collapsing header.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            AppSpacing.xs,
          ),
          child: Column(
            children: [
              Text(
                '${provider.locationLabel} • ${PrayerCalculationPolicy.methods[provider.selectedMethod]}',
                textAlign: TextAlign.center,
                style: text.titleSmall,
              ),
              Text(
                '${provider.prayerTimes?.timezone ?? ""} • ${provider.selectedCoordinates?.latitude.toStringAsFixed(4)}, ${provider.selectedCoordinates?.longitude.toStringAsFixed(4)}',
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: text.bodySmall,
              ),
            ],
          ),
        ),
        if (provider.prayerTimes?.isCached == true)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              appL10n.prayerTimesScreenMessage6(
                (provider.prayerTimes!.isStale
                        ? appL10n.prayerTimesScreenMessage5
                        : appL10n.prayerTimesScreenMessage4)
                    .toString(),
                (provider.prayerTimes!.fetchedAt).toString(),
              ),
              textAlign: TextAlign.center,
              style: text.bodySmall,
            ),
          ),
        Center(
          child: TextButton.icon(
            onPressed: provider.refresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(appL10n.prayerTimesScreenMessage7),
          ),
        ),
        // Next Prayer Card
        _buildNextPrayerCard(prayerTimes),
        SectionHeader(
          title: l10n.todayPrayerTimes,
          trailing: Text(context.digits(formattedDate), style: text.bodySmall),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appL10n.notificationServiceMessage5,
                style: text.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.ms),
              _buildPrayerTimesList(prayerTimes),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildNextPrayerCard(Map<String, String> prayerTimes) {
    final nextPrayerInfo = _getNextPrayer(prayerTimes);
    final nextPrayerName = nextPrayerInfo['name'] as String;
    final nextPrayerTime = context.digits(nextPrayerInfo['time'] as String);
    final timeRemaining = context.digits(nextPrayerInfo['remaining'] as String);

    final decor = SakinaDecor.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: ClipRRect(
        borderRadius: AppRadius.hero,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: decor.heroColors,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: GeometricPattern(
                  pattern: decor.pattern,
                  color: decor.onFeature.withValues(alpha: 0.07),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    // Next Prayer Label
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        appL10n.prayerTimesWidgetMessage6,
                        style: text.labelLarge?.copyWith(
                          color: decor.onFeatureMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Prayer Name and Time
                    Text(
                      appL10n.prayerTimesScreenMessage8(
                        (nextPrayerName).toString(),
                      ),
                      textAlign: TextAlign.center,
                      style: text.displayMedium?.copyWith(
                        color: decor.onFeature,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.ms),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.md,
                      children: [
                        Text(
                          nextPrayerTime,
                          style: AppTypography.numeral.copyWith(
                            color: decor.onFeature,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appL10n.prayerTimesWidgetMessage7,
                              style: text.labelMedium?.copyWith(
                                color: decor.onFeatureMuted,
                              ),
                            ),
                            Text(
                              timeRemaining,
                              style: text.titleMedium?.copyWith(
                                color: decor.onFeature,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerTimesList(Map<String, String> prayerTimes) {
    final arabicNames = {
      'Fajr': appL10n.prayerTimesWidgetMessage8,
      'Sunrise': appL10n.prayerTimesPerformanceProviderMessage1,
      'Dhuhr': appL10n.prayerTimesWidgetMessage9,
      'Asr': appL10n.prayerTimesWidgetMessage10,
      'Maghrib': appL10n.prayerTimesWidgetMessage11,
      'Isha': appL10n.prayerTimesWidgetMessage12,
    };

    final nextPrayerInfo = _getNextPrayer(prayerTimes);
    final currentPrayerName = nextPrayerInfo['name'] as String;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: prayerTimes.length,
      itemBuilder: (context, index) {
        final entry = prayerTimes.entries.elementAt(index);
        final arabicName = arabicNames[entry.key] ?? entry.key;
        final isCurrentPrayer = arabicName == currentPrayerName;

        return _prayerTimeTile(
          prayerName: arabicName,
          prayerTime: context.digits(entry.value),
          isNext: isCurrentPrayer,
        );
      },
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
        // Wraps the time under the name instead of overflowing at large text.
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
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
                Text(
                  prayerName,
                  style: text.titleMedium?.copyWith(
                    color: isNext ? scheme.onSecondary : scheme.onSurface,
                    fontWeight: isNext ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
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
        'remaining': appL10n.prayerTimesScreenMessage9,
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
