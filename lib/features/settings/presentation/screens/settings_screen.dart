import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/monitoring_service.dart';
import '../../../onboarding/presentation/widgets/alarms/alarm_menu_item.dart';
import '../widgets/reading_preferences.dart';
import '../widgets/settings_controls.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    MonitoringService.instance.event('settings_open');
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(l10nOf(context).appStringsMessage16)),
      body: SafeArea(
        child: ListView(
          children: [
            _SectionTitle(l10nOf(context).settingsScreenMessage1),
            const ThemePreference(),
            ReadingPreferencesPanel(preferences: settings.prefs),
            _SectionTitle(l10nOf(context).mainNavigationShellMessage1),
            const PrayerPreferences(),
            _SectionTitle(l10nOf(context).settingsScreenMessage9),
            for (final alarm in [
              (
                type: 'morning',
                title: l10nOf(context).azkarScreenMessage1,
                icon: Icons.wb_sunny_outlined,
                enabled: settings.isMorningAlarmEnabled,
                toggle: settings.toggleMorningAlarm,
              ),
              (
                type: 'evening',
                title: l10nOf(context).azkarScreenMessage2,
                icon: Icons.nights_stay_outlined,
                enabled: settings.isEveningAlarmEnabled,
                toggle: settings.toggleEveningAlarm,
              ),
              (
                type: 'mulk',
                title: l10nOf(context).homeScreenMessage31,
                icon: Icons.menu_book,
                enabled: settings.isMulkAlarmEnabled,
                toggle: settings.toggleMulkAlarm,
              ),
              (
                type: 'baqarah',
                title: l10nOf(context).homeScreenMessage32,
                icon: Icons.auto_stories,
                enabled: settings.isBaqarahAlarmEnabled,
                toggle: settings.toggleBaqarahAlarm,
              ),
            ]) ...[
              SwitchListTile(
                title: Text(
                  l10nOf(
                    context,
                  ).settingsScreenMessage10((alarm.title).toString()),
                ),
                value: alarm.enabled,
                onChanged: (enabled) async {
                  if (enabled) {
                    await NotificationService.instance.requestPermissions();
                  }
                  await alarm.toggle(enabled);
                },
              ),
              AlarmMenuItem(
                title: alarm.title,
                subtitle: l10nOf(context).settingsScreenMessage11,
                icon: alarm.icon,
                alarmType: alarm.type,
                isEnabled: alarm.enabled,
                onChanged: alarm.toggle,
              ),
            ],
            _SectionTitle(l10nOf(context).settingsScreenMessage12),
            const MonitoringPreference(),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(l10nOf(context).homeScreenMessage25),
              onTap: () => context.push('/settings/data-sources'),
            ),
            const AboutAppTile(),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
