import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/database/app_database.dart';
import 'package:sakina_app/core/di/service_locator.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/core/utils/dual_date.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../prayers/domain/entities/adhan_settings.dart';
import '../../prayers/presentation/prayer_labels.dart';
import '../data/practice_log_repository.dart';
import 'practice_log_controller.dart';

extension PracticeLogLabels on AppLocalizations {
  String prayerStatus(PrayerLogStatus? s) => switch (s) {
    PrayerLogStatus.onTime => prayerLogOnTime,
    PrayerLogStatus.late => prayerLogLate,
    PrayerLogStatus.missed => prayerLogMissed,
    PrayerLogStatus.excused => prayerLogExcused,
    null => prayerLogNotLogged,
  };

  String fastStatus(FastLogStatus s) => switch (s) {
    FastLogStatus.fasted => fastFasted,
    FastLogStatus.qada => fastQada,
    FastLogStatus.excused => fastExcused,
    FastLogStatus.missed => fastMissed,
  };
}

/// Shape and colour together, so the state never rests on colour alone.
IconData prayerStatusIcon(PrayerLogStatus? s) => switch (s) {
  PrayerLogStatus.onTime => Icons.check_circle_rounded,
  PrayerLogStatus.late => Icons.schedule_rounded,
  PrayerLogStatus.missed => Icons.remove_circle_outline_rounded,
  PrayerLogStatus.excused => Icons.spa_outlined,
  null => Icons.radio_button_unchecked_rounded,
};

/// The private prayer and fasting log: one tap per prayer, a calm week
/// view without streaks, the fast of the day and make-up fasts owed.
class PracticeLogScreen extends StatelessWidget {
  const PracticeLogScreen({super.key, this.repository});

  /// Replaces the database-backed repository, for tests.
  final PracticeLogRepository? repository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PracticeLogController>(
      create: (context) => PracticeLogController(
        repository ?? PracticeLogRepository(getIt.getAsync<AppDatabase>),
        context.read<SharedPreferences>(),
      )..load(),
      child: const _PracticeLogView(),
    );
  }
}

class _PracticeLogView extends StatelessWidget {
  const _PracticeLogView();

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final c = context.watch<PracticeLogController>();
    final theme = Theme.of(context);
    final m = MaterialLocalizations.of(context);
    final logged = c.prayersOn(c.day);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.practiceLogTitle)),
      body: !c.loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    l10n.practiceLogPrivacy,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: l10n.practiceLogPreviousDay,
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: c.previousDay,
                    ),
                    Expanded(
                      child: Text(
                        c.isToday
                            ? l10n.practiceLogToday
                            : context.digits(m.formatFullDate(c.day)),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.practiceLogNextDay,
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: c.isToday ? null : c.nextDay,
                    ),
                  ],
                ),
                SwitchListTile(
                  key: const Key('practice-excused'),
                  title: Text(l10n.practiceExcusedTitle),
                  subtitle: Text(l10n.practiceExcusedHelp),
                  value: c.excusedMode,
                  onChanged: c.setExcusedMode,
                ),
                if (c.excusedMode && logged.length < DailyPrayer.values.length)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.spa_outlined),
                      label: Text(l10n.practiceMarkDayExcused),
                      onPressed: c.markDayExcused,
                    ),
                  ),
                for (final p in DailyPrayer.values)
                  ListTile(
                    key: Key('practice-prayer-${p.name}'),
                    leading: Icon(prayerStatusIcon(logged[p])),
                    title: Text(l10n.prayerName(p)),
                    trailing: Text(l10n.prayerStatus(logged[p])),
                    onTap: () => _choosePrayer(context, c, p, logged[p]),
                  ),
                const Divider(height: AppSpacing.xl),
                ListTile(title: Text(l10n.practiceWeekTitle)),
                _WeekStrip(controller: c),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    context.digits(_summary(l10n, c.weekCounts)),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const Divider(height: AppSpacing.xl),
                ListTile(title: Text(l10n.fastingTitle)),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final s in FastLogStatus.values)
                        ChoiceChip(
                          key: Key('practice-fast-${s.name}'),
                          label: Text(l10n.fastStatus(s)),
                          selected: c.fastOn(c.day) == s,
                          onSelected: (on) => c.setFast(on ? s : null),
                        ),
                    ],
                  ),
                ),
                ListTile(
                  title: Text(
                    l10n.qadaLeftTitle(context.digits('${c.qadaLeft}')),
                  ),
                  subtitle: Text(l10n.qadaHelp),
                  isThreeLine: true,
                ),
                Row(
                  children: [
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        l10n.qadaBaseLabel(context.digits('${c.qadaBase}')),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.qadaBaseDecrease,
                      icon: const Icon(Icons.remove_rounded),
                      onPressed: c.qadaBase > 0
                          ? () => c.changeQadaBase(-1)
                          : null,
                    ),
                    IconButton(
                      tooltip: l10n.qadaBaseIncrease,
                      icon: const Icon(Icons.add_rounded),
                      onPressed: () => c.changeQadaBase(1),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                ),
              ],
            ),
    );
  }

  static String _summary(AppLocalizations l10n, Map<PrayerLogStatus, int> n) =>
      l10n.practiceWeekSummary(
        '${n[PrayerLogStatus.onTime]}',
        '${n[PrayerLogStatus.late]}',
        '${n[PrayerLogStatus.missed]}',
        '${n[PrayerLogStatus.excused]}',
      );

  Future<void> _choosePrayer(
    BuildContext context,
    PracticeLogController c,
    DailyPrayer prayer,
    PrayerLogStatus? current,
  ) async {
    final l10n = l10nOf(context);
    final picked = await showModalBottomSheet<(PrayerLogStatus?,)>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                l10n.prayerName(prayer),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final s in PrayerLogStatus.values)
              ListTile(
                leading: Icon(prayerStatusIcon(s)),
                title: Text(l10n.prayerStatus(s)),
                selected: s == current,
                onTap: () => Navigator.pop(context, (s,)),
              ),
            if (current != null)
              ListTile(
                leading: const Icon(Icons.clear_rounded),
                title: Text(l10n.prayerLogClear),
                onTap: () => Navigator.pop(context, (null,)),
              ),
          ],
        ),
      ),
    );
    if (picked != null) await c.setPrayer(prayer, picked.$1);
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.controller});

  final PracticeLogController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final theme = Theme.of(context);
    final m = MaterialLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          for (final d in controller.week)
            Expanded(
              child: Semantics(
                label: context.digits(
                  l10n.practiceDaySemantics(
                    m.formatMediumDate(d),
                    [
                      for (final p in DailyPrayer.values)
                        '${l10n.prayerName(p)} '
                            '${l10n.prayerStatus(controller.prayersOn(d)[p])}',
                    ].join(l10n.listSeparator),
                  ),
                ),
                excludeSemantics: true,
                child: InkWell(
                  onTap: () => controller.showDay(d),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      children: [
                        Text(
                          weekdayInitials[d.weekday - 1],
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: d == controller.day
                                ? FontWeight.bold
                                : null,
                          ),
                        ),
                        for (final p in DailyPrayer.values)
                          Icon(
                            prayerStatusIcon(controller.prayersOn(d)[p]),
                            size: 16,
                            color: controller.prayersOn(d)[p] == null
                                ? theme.colorScheme.outline
                                : theme.colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
