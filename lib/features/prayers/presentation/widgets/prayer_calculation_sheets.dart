import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter/material.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/feedback/feedback_service.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../../data/repositories/prayer_times_repository_impl.dart';
import '../../domain/entities/adhan_settings.dart';
import '../../domain/prayer_calculation_policy.dart';
import '../../domain/prayer_time_adjustments.dart';
import '../prayer_labels.dart';
import '../providers/prayer_times_provider.dart';

/// Display name of an adjustable time.
String prayerTimeKindName(AppLocalizations l10n, PrayerTimeKind kind) =>
    switch (kind) {
      PrayerTimeKind.fajr => l10n.prayerName(DailyPrayer.fajr),
      PrayerTimeKind.sunrise => l10n.prayerSunriseName,
      PrayerTimeKind.dhuhr => l10n.prayerName(DailyPrayer.dhuhr),
      PrayerTimeKind.asr => l10n.prayerName(DailyPrayer.asr),
      PrayerTimeKind.maghrib => l10n.prayerName(DailyPrayer.maghrib),
      PrayerTimeKind.isha => l10n.prayerName(DailyPrayer.isha),
    };

/// "+2 د", "−3 د", or "بلا تعديل".
String formatAdjustment(BuildContext context, int minutes) {
  final l10n = l10nOf(context);
  if (minutes == 0) return l10n.prayerAdjustmentsNone;
  // U+2212 MINUS SIGN reads clearly next to Arabic text.
  return l10n.prayerAdjustmentMinutes(
    minutes > 0 ? '+' : '−',
    context.digits(minutes.abs()),
  );
}

/// Lets the user shift each time by whole minutes (±30). Changes are saved
/// and alerts rescheduled as each step is tapped.
Future<void> showPrayerAdjustmentsSheet(
  BuildContext context,
  PrayerTimesProvider provider,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _AdjustmentsSheet(provider: provider),
);

class _AdjustmentsSheet extends StatelessWidget {
  const _AdjustmentsSheet({required this.provider});

  final PrayerTimesProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final ThemeData theme = Theme.of(context);
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final PrayerTimeAdjustments current = provider.adjustments;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.prayerAdjustmentsTitle,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.prayerAdjustmentsNote,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final PrayerTimeKind kind in PrayerTimeKind.values)
                  _AdjustmentRow(
                    name: prayerTimeKindName(l10n, kind),
                    minutes: current.of(kind),
                    onChanged: (value) {
                      playFeedback(context, FeedbackEvent.selection);
                      provider.setAdjustments(current.withMinutes(kind, value));
                    },
                  ),
                if (!current.isEmpty)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: Text(l10n.prayerAdjustmentsReset),
                      onPressed: () =>
                          provider.setAdjustments(PrayerTimeAdjustments.none),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdjustmentRow extends StatelessWidget {
  const _AdjustmentRow({
    required this.name,
    required this.minutes,
    required this.onChanged,
  });

  final String name;
  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final ThemeData theme = Theme.of(context);
    const int limit = PrayerTimeAdjustments.limit;
    return Row(
      children: [
        Expanded(child: Text(name, style: theme.textTheme.titleSmall)),
        IconButton(
          tooltip: l10n.prayerAdjustmentEarlier(name),
          icon: const Icon(Icons.remove_circle_outline_rounded),
          onPressed: minutes > -limit ? () => onChanged(minutes - 1) : null,
        ),
        SizedBox(
          width: 84,
          child: Text(
            formatAdjustment(context, minutes),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: minutes == 0 ? null : theme.colorScheme.primary,
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.prayerAdjustmentLater(name),
          icon: const Icon(Icons.add_circle_outline_rounded),
          onPressed: minutes < limit ? () => onChanged(minutes + 1) : null,
        ),
      ],
    );
  }
}

/// Shows exactly what the calculation uses today: method, twilight angles,
/// Isha interval (including the Umm al-Qura Ramadan rule), Asr rule,
/// high-latitude rule, time zone and every minute adjustment.
Future<void> showPrayerCalculationExplanation(
  BuildContext context,
  PrayerTimesProvider provider,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _ExplanationSheet(provider: provider),
);

class _ExplanationSheet extends StatelessWidget {
  const _ExplanationSheet({required this.provider});

  final PrayerTimesProvider provider;

  String _degrees(BuildContext context, double value) {
    final String text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
    return context.digits(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final ThemeData theme = Theme.of(context);
    final DateTime today = provider.locationNow;
    final coordinates = provider.selectedCoordinates;
    final int method = provider.selectedMethod;
    final adhan.CalculationParameters params =
        PrayerTimesRepositoryImpl.parametersFor(
          method,
          date: today,
          madhab: provider.asrMadhab,
          coordinates: coordinates == null
              ? null
              : adhan.Coordinates(coordinates.latitude, coordinates.longitude),
          adjustments: provider.adjustments,
        );
    final int ishaInterval = params.ishaInterval ?? 0;
    final bool ramadanRule =
        method == PrayerCalculationPolicy.ummAlQura &&
        PrayerTimesRepositoryImpl.isRamadan(today);
    final bool highLatitude = (coordinates?.latitude ?? 0) > 48;

    String adjustmentList(Map<PrayerTimeKind, int> shifts) => [
      for (final MapEntry(:key, :value) in shifts.entries)
        if (value != 0)
          '${prayerTimeKindName(l10n, key)} ${formatAdjustment(context, value)}',
    ].join(l10n.listSeparator);

    final Map<PrayerTimeKind, int> methodShifts = {
      for (final MapEntry(:key, :value) in params.methodAdjustments.entries)
        if (_kind(key) != null) _kind(key)!: value,
    };

    final List<(String, String)> rows = [
      (l10n.prayerExplainMethod, PrayerCalculationPolicy.methods[method] ?? ''),
      (
        l10n.prayerExplainFajr,
        l10n.prayerExplainAngle(_degrees(context, params.fajrAngle)),
      ),
      (
        l10n.prayerExplainIsha,
        ishaInterval > 0
            ? l10n.prayerExplainInterval(context.digits(ishaInterval))
            : l10n.prayerExplainAngle(_degrees(context, params.ishaAngle)),
      ),
      (
        l10n.prayerExplainAsr,
        provider.asrMadhab == AsrMadhab.hanafi
            ? l10n.asrMadhabHanafi
            : l10n.asrMadhabStandard,
      ),
      if (highLatitude)
        (l10n.prayerExplainHighLatitude, l10n.prayerExplainSeventh)
      else
        (l10n.prayerExplainHighLatitude, l10n.prayerExplainMiddle),
      if (provider.prayerTimes?.timezone case final String zone?)
        (l10n.prayerExplainTimeZone, zone),
      if (methodShifts.values.any((v) => v != 0))
        (l10n.prayerExplainMethodAdjustments, adjustmentList(methodShifts)),
      (
        l10n.prayerExplainYourAdjustments,
        provider.adjustments.isEmpty
            ? l10n.prayerAdjustmentsNone
            : adjustmentList(provider.adjustments.minutes),
      ),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.prayerExplainTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            for (final (String label, String value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(value, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            if (ramadanRule) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.prayerExplainRamadan, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(l10n.prayerExplainFootnote, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  static PrayerTimeKind? _kind(adhan.Prayer prayer) => switch (prayer) {
    adhan.Prayer.fajr => PrayerTimeKind.fajr,
    adhan.Prayer.sunrise => PrayerTimeKind.sunrise,
    adhan.Prayer.dhuhr => PrayerTimeKind.dhuhr,
    adhan.Prayer.asr => PrayerTimeKind.asr,
    adhan.Prayer.maghrib => PrayerTimeKind.maghrib,
    adhan.Prayer.isha => PrayerTimeKind.isha,
    _ => null,
  };
}
