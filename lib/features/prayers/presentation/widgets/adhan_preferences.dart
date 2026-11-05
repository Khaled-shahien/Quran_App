import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../../domain/entities/adhan_settings.dart';
import '../providers/adhan_settings_controller.dart';

extension AdhanLabels on AppLocalizations {
  String prayerName(DailyPrayer p) => switch (p) {
    DailyPrayer.fajr => prayerTimesWidgetMessage8,
    DailyPrayer.dhuhr => prayerTimesWidgetMessage9,
    DailyPrayer.asr => prayerTimesWidgetMessage10,
    DailyPrayer.maghrib => prayerTimesWidgetMessage11,
    DailyPrayer.isha => prayerTimesWidgetMessage12,
  };

  String alertMode(PrayerAlertMode m) => switch (m) {
    PrayerAlertMode.adhan => prayerAlertModeAdhan,
    PrayerAlertMode.sound => prayerAlertModeSound,
    PrayerAlertMode.notificationOnly => prayerAlertModeNotification,
    PrayerAlertMode.silent => prayerAlertModeSilent,
  };
}

/// Alert type per prayer, reminder before prayer, exact timing, battery
/// guidance and a test button, in plain Arabic.
class AdhanPreferences extends StatefulWidget {
  const AdhanPreferences({super.key});

  @override
  State<AdhanPreferences> createState() => _AdhanPreferencesState();
}

class _AdhanPreferencesState extends State<AdhanPreferences> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdhanSettingsController?>()?.refreshExactStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Optional so settings still render where the controller is absent.
    final c = context.watch<AdhanSettingsController?>();
    if (c == null) return const SizedBox.shrink();
    final l10n = l10nOf(context);
    final theme = Theme.of(context);
    final settings = c.settings;
    final usesAdhan = DailyPrayer.values.any(
      (p) => settings.modeFor(p) == PrayerAlertMode.adhan,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(title: Text(l10n.prayerAlertsTitle)),
        for (final prayer in DailyPrayer.values)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(child: Text(l10n.prayerName(prayer))),
                const SizedBox(width: 12),
                Flexible(
                  flex: 2,
                  child: DropdownButtonFormField<PrayerAlertMode>(
                    key: Key('adhan-mode-${prayer.name}'),
                    initialValue: settings.modeFor(prayer),
                    isExpanded: true,
                    items: [
                      for (final m in PrayerAlertMode.values)
                        DropdownMenuItem(
                          value: m,
                          child: Text(l10n.alertMode(m)),
                        ),
                    ],
                    onChanged: (m) {
                      if (m != null) c.setMode(prayer, m);
                    },
                  ),
                ),
              ],
            ),
          ),
        if (usesAdhan)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
            child: Text(
              l10n.adhanRecordingsPending,
              style: theme.textTheme.bodySmall,
            ),
          ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
          child: DropdownButtonFormField<int>(
            key: const Key('adhan-reminder'),
            initialValue: settings.reminderMinutes,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.prayerReminderTitle,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final m in AdhanSettings.reminderOptions)
                DropdownMenuItem(
                  value: m,
                  child: Text(
                    m == 0
                        ? l10n.prayerReminderOff
                        : l10n.prayerReminderMinutes('$m'),
                  ),
                ),
            ],
            onChanged: (m) {
              if (m != null) c.setReminderMinutes(m);
            },
          ),
        ),
        if (c.exactAllowed != null)
          ListTile(
            leading: Icon(
              c.exactAllowed! ? Icons.alarm_on_rounded : Icons.alarm_rounded,
            ),
            title: Text(l10n.exactAlarmTitle),
            subtitle: Text(
              c.exactAllowed!
                  ? l10n.exactAlarmAllowed
                  : l10n.exactAlarmNotAllowed,
            ),
            trailing: c.exactAllowed!
                ? null
                : TextButton(
                    onPressed: () => _explainExact(context, c),
                    child: Text(l10n.exactAlarmAllow),
                  ),
          ),
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          ListTile(
            leading: const Icon(Icons.battery_saver_rounded),
            title: Text(l10n.batteryTitle),
            subtitle: Text(l10n.batteryExplain),
            isThreeLine: true,
            trailing: IconButton(
              tooltip: l10n.batteryOpenSettings,
              icon: const Icon(Icons.open_in_new_rounded),
              onPressed: Geolocator.openAppSettings,
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.notifications_active_rounded),
            label: Text(l10n.testAdhanButton),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await c.scheduleTest();
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.testAdhanScheduled)),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _explainExact(
    BuildContext context,
    AdhanSettingsController c,
  ) async {
    final l10n = l10nOf(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.exactAlarmTitle),
        content: Text(l10n.exactAlarmExplain),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.appStringsMessage9),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.exactAlarmAllow),
          ),
        ],
      ),
    );
    if (ok == true) await c.requestExactAlarms();
  }
}
