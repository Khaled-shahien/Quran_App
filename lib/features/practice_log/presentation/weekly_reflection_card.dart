import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/database/app_database.dart';
import 'package:sakina_app/core/di/service_locator.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/core/widgets/sakina_card.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../khatma/domain/models/khatma_model.dart';
import '../data/practice_log_repository.dart';
import '../domain/weekly_reflection.dart';

/// "Your week": on Friday and Saturday, when turned on in Settings, what
/// the past seven days held. Only what was done is listed.
class WeeklyReflectionCard extends StatefulWidget {
  const WeeklyReflectionCard({super.key, this.log, this.clock});

  final PracticeLogRepository? log;
  final DateTime Function()? clock;

  @override
  State<WeeklyReflectionCard> createState() => _WeeklyReflectionCardState();
}

class _WeeklyReflectionCardState extends State<WeeklyReflectionCard> {
  WeekSummary? _week;

  DateTime get _now => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_load()));
  }

  Future<void> _load() async {
    if (!mounted) return;
    final prefs = context.read<SharedPreferences?>();
    if (prefs == null ||
        prefs.getBool(WeeklyReflection.enabledKey) != true ||
        !WeeklyReflection.isReflectionDay(_now)) {
      return;
    }
    final week = await WeeklyReflection.compute(
      prefs: prefs,
      log: widget.log ?? PracticeLogRepository(getIt.getAsync<PrivateDatabase>),
      now: _now,
    );
    if (mounted) setState(() => _week = week);
  }

  @override
  Widget build(BuildContext context) {
    final week = _week;
    if (week == null) return const SizedBox.shrink();
    final l10n = l10nOf(context);
    final theme = Theme.of(context);
    final unit = week.khatmaUnit;
    String amount(double v) =>
        v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);
    final lines = <(IconData, String)>[
      if (week.khatmaUnits > 0 && unit != null)
        (
          Icons.menu_book_rounded,
          l10n.weeklyKhatma(amount(week.khatmaUnits), unit.arabicLabel),
        ),
      if (week.adhkarSessions > 0)
        (Icons.spa_rounded, l10n.weeklyAdhkar('${week.adhkarSessions}')),
      if (week.prayersOnTime > 0)
        (
          Icons.check_circle_rounded,
          l10n.weeklyPrayers('${week.prayersOnTime}'),
        ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.page,
        vertical: AppSpacing.sm,
      ),
      child: SakinaCard(
        key: const Key('weekly-reflection'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.weeklyTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            for (final (icon, text) in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(context.digits(text))),
                  ],
                ),
              ),
            Text(
              lines.isEmpty ? l10n.weeklyFreshStart : l10n.weeklyClosing,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
