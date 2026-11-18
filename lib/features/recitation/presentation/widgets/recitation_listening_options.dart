import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../providers/recitation_controller.dart';

/// Auto-next surah, repeat each ayah, and the sleep timer.
class RecitationListeningOptions extends StatelessWidget {
  const RecitationListeningOptions({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<RecitationController>();
    final l10n = l10nOf(context);
    final theme = Theme.of(context);
    final m = MaterialLocalizations.of(context);
    final DateTime? sleepAt = c.sleepAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.recitationListeningTitle, style: theme.textTheme.titleMedium),
        SwitchListTile(
          key: const Key('recitation-auto-next'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.recitationAutoNext),
          value: c.autoNext,
          onChanged: c.setAutoNext,
        ),
        DropdownButtonFormField<int>(
          key: const Key('recitation-ayah-repeat'),
          initialValue: c.ayahRepeat,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.recitationAyahRepeat,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final n in RecitationController.ayahRepeatOptions)
              DropdownMenuItem(
                value: n,
                child: Text(
                  n == 1
                      ? l10n.recitationAyahRepeatOnce
                      : l10n.recitationAyahRepeatTimes(context.digits('$n')),
                ),
              ),
          ],
          onChanged: (n) {
            if (n != null) c.setAyahRepeat(n);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.recitationSleepTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        if (sleepAt != null || c.sleepAtSurahEnd)
          Row(
            children: [
              Expanded(
                child: Text(
                  sleepAt != null
                      ? context.digits(
                          l10n.recitationSleepAt(
                            m.formatTimeOfDay(TimeOfDay.fromDateTime(sleepAt)),
                          ),
                        )
                      : l10n.recitationSleepAtSurahEnd,
                ),
              ),
              TextButton(
                onPressed: () => c.setSleepTimer(null),
                child: Text(l10n.recitationSleepCancel),
              ),
            ],
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final minutes in RecitationController.sleepOptions)
                ActionChip(
                  label: Text(
                    l10n.recitationSleepMinutes(context.digits('$minutes')),
                  ),
                  onPressed: () => c.setSleepTimer(minutes),
                ),
              ActionChip(
                label: Text(l10n.recitationSleepSurahEnd),
                onPressed: c.sleepAtEndOfSurah,
              ),
            ],
          ),
      ],
    );
  }
}
