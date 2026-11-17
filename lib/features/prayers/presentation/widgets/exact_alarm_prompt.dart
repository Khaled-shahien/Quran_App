import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../../domain/entities/adhan_settings.dart';
import '../providers/adhan_settings_controller.dart';

/// Android 14+ denies "Alarms & reminders" (exact alarms) by default for new
/// installs. Without it prayer alerts are inexact, and Doze holds inexact
/// alarms while the phone is locked, so alerts arrive only when the screen
/// is turned on. These helpers ask for it at the right moment and keep a
/// warning visible while it is missing.

/// Preference: the explanatory dialog was shown once.
const String exactAlarmPromptSeenKey = 'exact_alarm_prompt_seen';

/// True when prayer alerts are on, some prayer alerts, and exact alarms are
/// known to be denied. Null [exactAllowed] (iOS, older Android, unknown)
/// never needs the permission.
bool needsExactAlarms({
  required AdhanSettings settings,
  required bool? exactAllowed,
  required bool prayerAlertsEnabled,
}) =>
    exactAllowed == false &&
    prayerAlertsEnabled &&
    DailyPrayer.values.any(
      (p) => settings.modeFor(p) != PrayerAlertMode.silent,
    );

bool _prayerAlertsEnabled(SharedPreferences prefs) =>
    prefs.getBool('prayer_notifications_enabled') ?? true;

/// Explains and asks for exact alarms once, when they are needed. Opening
/// the system page is the user's choice; the warning card stays until the
/// permission is granted.
Future<void> promptForExactAlarmsOnce(BuildContext context) async {
  final controller = context.read<AdhanSettingsController?>();
  if (controller == null) return;
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(exactAlarmPromptSeenKey) ?? false) return;
  await controller.refreshExactStatus();
  if (!context.mounted ||
      !needsExactAlarms(
        settings: controller.settings,
        exactAllowed: controller.exactAllowed,
        prayerAlertsEnabled: _prayerAlertsEnabled(prefs),
      )) {
    return;
  }
  await prefs.setBool(exactAlarmPromptSeenKey, true);
  if (!context.mounted) return;
  final l10n = l10nOf(context);
  final allow = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.alarm_rounded),
      title: Text(l10n.exactAlarmPromptTitle),
      content: Text(l10n.exactAlarmPromptBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.exactAlarmLater),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.exactAlarmAllow),
        ),
      ],
    ),
  );
  if (allow == true) await controller.requestExactAlarms();
}

/// A warning shown while prayer alerts would be held until the phone is
/// unlocked, with the way to fix it.
class ExactAlarmWarningCard extends StatefulWidget {
  const ExactAlarmWarningCard({super.key});

  @override
  State<ExactAlarmWarningCard> createState() => _ExactAlarmWarningCardState();
}

class _ExactAlarmWarningCardState extends State<ExactAlarmWarningCard> {
  bool _alertsEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() => _alertsEnabled = _prayerAlertsEnabled(prefs));
      await context.read<AdhanSettingsController?>()?.refreshExactStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdhanSettingsController?>();
    if (controller == null ||
        !needsExactAlarms(
          settings: controller.settings,
          exactAllowed: controller.exactAllowed,
          prayerAlertsEnabled: _alertsEnabled,
        )) {
      return const SizedBox.shrink();
    }
    final l10n = l10nOf(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.md,
        AppSpacing.page,
        0,
      ),
      child: Card(
        color: scheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.alarm_off_rounded, color: scheme.onErrorContainer),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.exactAlarmLateWarning,
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton(
                  onPressed: controller.requestExactAlarms,
                  child: Text(l10n.exactAlarmAllow),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
