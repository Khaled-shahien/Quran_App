import 'package:flutter/material.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../../domain/entities/adhan_settings.dart';
import '../../domain/iqama.dart';
import '../prayer_labels.dart';
import '../providers/prayer_times_provider.dart';

/// "Iqama times at my mosque": minutes after the adhan per prayer and an
/// optional alert before the iqama.
Future<void> showIqamaSheet(
  BuildContext context,
  PrayerTimesProvider provider,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => ListenableBuilder(
    listenable: provider,
    builder: (context, _) {
      final l10n = l10nOf(context);
      final theme = Theme.of(context);
      final IqamaSettings current = provider.iqama;
      String minutesLabel(int m) => m == 0
          ? l10n.iqamaNone
          : l10n.iqamaAfterMinutes(context.digits('$m'));
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
              Text(l10n.iqamaTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.iqamaPrivacy, style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              for (final p in DailyPrayer.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: DropdownButtonFormField<int>(
                    key: Key('iqama-${p.name}'),
                    initialValue: current.of(p),
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.prayerName(p),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final m in IqamaSettings.options)
                        DropdownMenuItem(
                          value: m,
                          child: Text(minutesLabel(m)),
                        ),
                    ],
                    onChanged: (m) {
                      if (m != null) {
                        provider.setIqama(current.withMinutes(p, m));
                      }
                    },
                  ),
                ),
              DropdownButtonFormField<int>(
                key: const Key('iqama-alert'),
                initialValue: current.alertMinutes,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.iqamaAlertTitle,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final m in IqamaSettings.alertOptions)
                    DropdownMenuItem(
                      value: m,
                      child: Text(
                        m == 0
                            ? l10n.iqamaAlertOff
                            : l10n.iqamaAlertMinutes(context.digits('$m')),
                      ),
                    ),
                ],
                onChanged: current.isEmpty
                    ? null
                    : (m) {
                        if (m != null) provider.setIqama(current.withAlert(m));
                      },
              ),
            ],
          ),
        ),
      );
    },
  ),
);

/// Adds [minutes] to a displayed "HH:mm" time; null when it cannot be read.
String? addMinutesToClock(String clock, int minutes) {
  final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(clock);
  if (match == null) return null;
  final total =
      (int.parse(match[1]!) * 60 + int.parse(match[2]!) + minutes) % (24 * 60);
  return '${(total ~/ 60).toString().padLeft(2, '0')}:'
      '${(total % 60).toString().padLeft(2, '0')}';
}
