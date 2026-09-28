import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/monitoring_service.dart';
import '../../../prayers/presentation/providers/prayer_times_provider.dart';
import '../../../prayers/presentation/screens/prayer_location_dialog.dart';
import '../../../onboarding/presentation/widgets/alarms/alarm_menu_item.dart';
import '../widgets/reading_preferences.dart';

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
    final theme = context.watch<ThemeProvider>();
    final prayer = context.watch<PrayerTimesProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(l10nOf(context).appStringsMessage16)),
      body: SafeArea(
        child: ListView(
          children: [
            _SectionTitle(l10nOf(context).settingsScreenMessage1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<ThemeMode>(
                isExpanded: true,
                initialValue: theme.themeMode,
                decoration: InputDecoration(
                  labelText: l10nOf(context).settingsScreenMessage2,
                ),
                items: [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text(l10nOf(context).settingsScreenMessage3),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text(l10nOf(context).settingsScreenMessage4),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text(l10nOf(context).settingsScreenMessage5),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) theme.setThemeMode(value);
                },
              ),
            ),
            ReadingPreferencesPanel(preferences: settings.prefs),
            _SectionTitle(l10nOf(context).mainNavigationShellMessage1),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(l10nOf(context).settingsScreenMessage6),
              subtitle: Text(prayer.locationLabel),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => showPrayerLocationDialog(context, prayer),
            ),
            SwitchListTile(
              title: Text(l10nOf(context).settingsScreenMessage7),
              subtitle: Text(l10nOf(context).settingsScreenMessage8),
              value:
                  settings.prefs.getBool('prayer_notifications_enabled') ??
                  true,
              onChanged: (enabled) async {
                await settings.prefs.setBool(
                  'prayer_notifications_enabled',
                  enabled,
                );
                if (mounted) setState(() {});
                if (enabled) {
                  await NotificationService.instance.requestPermissions();
                  await prayer.refresh();
                } else {
                  await NotificationService.instance
                      .cancelAllPrayerNotifications();
                }
              },
            ),
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
            if (MonitoringService.instance.available)
              ListenableBuilder(
                listenable: MonitoringService.instance,
                builder: (context, _) => SwitchListTile(
                  title: Text(l10nOf(context).settingsScreenMessage13),
                  subtitle: Text(l10nOf(context).settingsScreenMessage14),
                  value: MonitoringService.instance.enabled,
                  onChanged: (value) async {
                    try {
                      await MonitoringService.instance.setEnabled(value);
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10nOf(context).settingsScreenMessage15,
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(l10nOf(context).homeScreenMessage25),
              onTap: () => context.push('/settings/data-sources'),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10nOf(context).settingsScreenMessage16),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: l10nOf(context).appConstantsMessage1,
                children: [Text(l10nOf(context).settingsScreenMessage17)],
              ),
            ),
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
