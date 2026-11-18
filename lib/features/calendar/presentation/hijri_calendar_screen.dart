import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/providers/settings_provider.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/core/utils/dual_date.dart';
import 'package:sakina_app/core/utils/hijri_calendar_data.dart';
import 'package:sakina_app/core/widgets/sakina_card.dart';
import 'package:sakina_app/core/widgets/sakina_hero_app_bar.dart';
import 'package:sakina_app/l10n/localization.dart';

/// A Hijri month (Umm al-Qura, with the user's offset): each day with its
/// civil date, today and the month's occasions marked, and the coming
/// occasions with the days left until them.
class HijriCalendarScreen extends StatefulWidget {
  const HijriCalendarScreen({super.key, this.today, this.occasions});

  final DateTime? today;
  final IslamicOccasions? occasions;

  @override
  State<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  late final Future<List<IslamicOccasion>> _occasions =
      (widget.occasions ?? IslamicOccasions.bundled).all();
  ({int year, int month})? _shown;

  DateTime get _today {
    final DateTime t = widget.today ?? DateTime.now();
    return DateTime(t.year, t.month, t.day);
  }

  void _move(int by, ({int year, int month}) from) {
    int m = from.month + by;
    int y = from.year;
    if (m < 1) {
      m = 12;
      y--;
    } else if (m > 12) {
      m = 1;
      y++;
    }
    if (y < 1357 || y > 1499) return;
    setState(() => _shown = (year: y, month: m));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final ThemeData theme = Theme.of(context);
    final int offset = context.watch<SettingsProvider?>()?.hijriOffsetDays ?? 0;
    final HijriConverter converter = HijriConverter(offsetDays: offset);
    final HijriDate? today = converter.of(_today);
    if (today == null) {
      return SakinaHeroScaffold(
        title: l10n.calendarTitle,
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(l10n.calendarUnavailable)),
          ),
        ],
      );
    }
    final ({int year, int month}) shown =
        _shown ?? (year: today.year, month: today.month);
    final days = converter.month(shown.year, shown.month);
    // Saturday-first weeks, as on Arab calendars.
    final int lead = (days.first.civil.weekday + 1) % 7;

    return SakinaHeroScaffold(
      title: l10n.calendarTitle,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverToBoxAdapter(
            child: FutureBuilder<List<IslamicOccasion>>(
              future: _occasions,
              builder: (context, snapshot) {
                final List<IslamicOccasion> occasions =
                    snapshot.data ?? const [];
                List<IslamicOccasion> on(int day) => [
                  for (final o in occasions)
                    if (o.covers(shown.month, day)) o,
                ];
                final List<IslamicOccasion> inMonth = [
                  for (final o in occasions)
                    if (o.month == null || o.month == shown.month) o,
                ];
                final upcoming = IslamicOccasions.upcoming(
                  occasions,
                  _today,
                  converter,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: l10n.calendarPrevious,
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: () => _move(-1, shown),
                        ),
                        Expanded(
                          child: Text(
                            l10n.calendarMonthTitle(
                              hijriMonthNames[shown.month - 1],
                              context.digits(shown.year),
                            ),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.calendarNext,
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: () => _move(1, shown),
                        ),
                      ],
                    ),
                    if (shown != (year: today.year, month: today.month))
                      Center(
                        child: TextButton(
                          onPressed: () => setState(() => _shown = null),
                          child: Text(l10n.calendarToday),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        for (final String w in weekdayInitials)
                          Expanded(
                            child: Text(
                              w,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                      ],
                    ),
                    GridView.count(
                      crossAxisCount: 7,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 0.9,
                      children: [
                        for (int i = 0; i < lead; i++) const SizedBox.shrink(),
                        for (final d in days)
                          _DayCell(
                            hijriDay: context.digits(d.day),
                            civilDay: context.digits(d.civil.day),
                            today: d.civil == _today,
                            marked: on(d.day).isNotEmpty,
                            label: [
                              '${context.digits(d.day)} ${hijriMonthNames[shown.month - 1]}',
                              for (final o in on(d.day)) o.name,
                            ].join(l10n.listSeparator),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (final o in inMonth)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.star_rounded, size: 18),
                        title: Text(o.name),
                        subtitle: o.note == null ? null : Text(o.note!),
                        trailing: Text(
                          context.digits(
                            o.from == o.to ? '${o.from}' : '${o.from}–${o.to}',
                          ),
                        ),
                      ),
                    if (upcoming.isNotEmpty) ...[
                      const Divider(),
                      Text(
                        l10n.calendarUpcoming,
                        style: theme.textTheme.titleSmall,
                      ),
                      for (final u in upcoming)
                        SakinaCard(
                          margin: const EdgeInsets.only(top: AppSpacing.sm),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              Expanded(child: Text(u.occasion.name)),
                              Text(
                                u.days == 0
                                    ? l10n.calendarNow
                                    : l10n.calendarInDays(
                                        context.digits(u.days),
                                      ),
                                style: theme.textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.calendarNote, style: theme.textTheme.bodySmall),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.hijriDay,
    required this.civilDay,
    required this.today,
    required this.marked,
    required this.label,
  });

  final String hijriDay;
  final String civilDay;
  final bool today;
  final bool marked;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      excludeSemantics: true,
      selected: today,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: today
              ? scheme.primary
              : marked
              ? scheme.primaryContainer
              : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              hijriDay,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: today ? scheme.onPrimary : null,
              ),
            ),
            Text(
              civilDay,
              style: TextStyle(
                fontSize: 10,
                color: today ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
