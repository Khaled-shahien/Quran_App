import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/providers/settings_provider.dart';
import 'package:sakina_app/core/services/anchored_reminders.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_times_provider.dart';
import 'package:sakina_app/l10n/localization.dart';

/// Chooses whether the morning (or evening) adhkar reminder rings at its
/// clock time or a number of minutes after Fajr (or Asr).
class AnchoredReminderTile extends StatefulWidget {
  const AnchoredReminderTile({super.key, required this.morning});

  final bool morning;

  @override
  State<AnchoredReminderTile> createState() => _AnchoredReminderTileState();
}

class _AnchoredReminderTileState extends State<AnchoredReminderTile> {
  static const int _clock = -1;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final int current =
        (widget.morning
            ? AnchoredReminders.morning(settings.prefs)
            : AnchoredReminders.evening(settings.prefs)) ??
        _clock;
    final String prayer = widget.morning
        ? l10n.prayerTimesWidgetMessage8
        : l10n.prayerTimesWidgetMessage10;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 56, end: 16, bottom: 8),
      child: DropdownButtonFormField<int>(
        key: ValueKey('anchor-${widget.morning}'),
        initialValue: current,
        isExpanded: true,
        decoration: InputDecoration(labelText: l10n.anchoredReminderLabel),
        items: [
          DropdownMenuItem(value: _clock, child: Text(l10n.anchoredClockTime)),
          for (final int m in AnchoredReminders.options)
            DropdownMenuItem(
              value: m,
              child: Text(
                m == 0
                    ? l10n.anchoredAtPrayer(prayer)
                    : l10n.anchoredAfterPrayer(context.digits(m), prayer),
              ),
            ),
        ],
        onChanged: (value) async {
          if (value == null) return;
          final int? minutes = value == _clock ? null : value;
          widget.morning
              ? await AnchoredReminders.setMorning(settings.prefs, minutes)
              : await AnchoredReminders.setEvening(settings.prefs, minutes);
          if (!context.mounted) return;
          final PrayerTimesProvider? prayerTimes = context
              .read<PrayerTimesProvider?>();
          await settings.resyncAlarms();
          // Anchored reminders are planned with the prayer alerts.
          if (prayerTimes?.selectedCoordinates != null) {
            await prayerTimes!.refresh();
          }
          if (mounted) setState(() {});
        },
      ),
    );
  }
}
