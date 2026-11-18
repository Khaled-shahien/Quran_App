import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/providers/settings_provider.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/core/utils/hijri_calendar_data.dart';
import 'package:sakina_app/core/widgets/sakina_card.dart';
import 'package:sakina_app/features/prayers/data/services/local_prayer_notification_scheduler.dart';
import 'package:sakina_app/features/prayers/domain/entities/adhan_settings.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_times_provider.dart';
import 'package:sakina_app/l10n/localization.dart';

/// Minutes before Fajr shown as Imsak, as on common Ramadan timetables.
const int imsakMinutesBeforeFajr = 10;

/// What the Ramadan card shows at [now]: the day of Ramadan, Imsak and
/// Iftar (Maghrib), and the next of them still ahead. Null outside
/// Ramadan or without the day's times.
({int day, DateTime imsak, DateTime iftar, bool nextIsIftar})? ramadanState({
  required HijriDate? hijri,
  required Map<DailyPrayer, DateTime> today,
  required DateTime now,
}) {
  final DateTime? fajr = today[DailyPrayer.fajr];
  final DateTime? maghrib = today[DailyPrayer.maghrib];
  if (hijri == null || hijri.month != 9 || fajr == null || maghrib == null) {
    return null;
  }
  final DateTime imsak = fajr.subtract(
    const Duration(minutes: imsakMinutesBeforeFajr),
  );
  return (
    day: hijri.day,
    imsak: imsak,
    iftar: maghrib,
    nextIsIftar: !now.isBefore(imsak) && now.isBefore(maghrib),
  );
}

/// Home card for Ramadan: the day, Imsak and Iftar, and a countdown to the
/// next one. Hidden on every other day.
class RamadanCard extends StatefulWidget {
  const RamadanCard({super.key, this.now});

  final DateTime Function()? now;

  @override
  State<RamadanCard> createState() => _RamadanCardState();
}

class _RamadanCardState extends State<RamadanCard> {
  Timer? _tick;

  DateTime _now() => (widget.now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PrayerTimesProvider? provider = context.watch<PrayerTimesProvider?>();
    final entity = provider?.prayerTimes;
    if (provider == null || entity == null) return const SizedBox.shrink();
    final int offset = context.watch<SettingsProvider?>()?.hijriOffsetDays ?? 0;
    final DateTime wall = provider.locationNow;
    final DateTime day = DateTime(wall.year, wall.month, wall.day);
    final state = ramadanState(
      hijri: HijriConverter(offsetDays: offset).of(day),
      today: LocalPrayerNotificationScheduler.buildPrayerSchedule(
        prayerTimes: entity,
        date: day,
      ),
      now: _now(),
    );
    if (state == null) return const SizedBox.shrink();
    final l10n = l10nOf(context);
    final ThemeData theme = Theme.of(context);
    final DateTime target = state.nextIsIftar ? state.iftar : state.imsak;
    final Duration left = target.difference(_now());
    final String countdown = left.isNegative
        ? ''
        : l10n.ramadanCountdown(
            state.nextIsIftar ? l10n.ramadanIftar : l10n.ramadanImsak,
            context.digits(left.inHours),
            context.digits((left.inMinutes % 60).toString().padLeft(2, '0')),
          );
    // Wall clock of the prayer location: entity times are already there.
    final String imsakText = provider.prayerTimes?.fajr == null
        ? ''
        : _wall(context, entity.fajr!, -imsakMinutesBeforeFajr);
    final String iftarText = context.digits(entity.maghrib ?? '');
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: SakinaCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.ramadanDay(context.digits(state.day)),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _Time(label: l10n.ramadanImsak, time: imsakText),
                ),
                Expanded(
                  child: _Time(label: l10n.ramadanIftar, time: iftarText),
                ),
              ],
            ),
            if (countdown.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(countdown, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.ramadanImsakNote, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  /// "HH:mm" shifted by [minutes], in the same wall clock.
  String _wall(BuildContext context, String hhmm, int minutes) {
    final List<String> parts = hhmm.split(':');
    if (parts.length < 2) return '';
    final int? h = int.tryParse(parts[0]);
    final int? m = int.tryParse(parts[1].substring(0, 2));
    if (h == null || m == null) return '';
    final int total = (h * 60 + m + minutes) % (24 * 60);
    return context.digits(
      '${(total ~/ 60).toString().padLeft(2, '0')}:'
      '${(total % 60).toString().padLeft(2, '0')}',
    );
  }
}

class _Time extends StatelessWidget {
  const _Time({required this.label, required this.time});

  final String label;
  final String time;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        Text(
          time,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
