import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/l10n/localization.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/monitoring_service.dart';
import '../../../prayers/presentation/providers/prayer_times_provider.dart';
import '../../../prayers/presentation/screens/prayer_location_dialog.dart';

class ThemePreference extends StatelessWidget {
  const ThemePreference({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Padding(
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
    );
  }
}

class PrayerPreferences extends StatefulWidget {
  const PrayerPreferences({super.key});
  @override
  State<PrayerPreferences> createState() => _PrayerPreferencesState();
}

class _PrayerPreferencesState extends State<PrayerPreferences> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final prayer = context.watch<PrayerTimesProvider>();
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: Text(l10nOf(context).settingsScreenMessage6),
          subtitle: Text(prayer.locationLabel),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showPrayerLocationDialog(context, prayer),
        ),
        SwitchListTile(
          title: Text(l10nOf(context).settingsScreenMessage7),
          subtitle: Text(l10nOf(context).settingsScreenMessage8),
          value: settings.prefs.getBool('prayer_notifications_enabled') ?? true,
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
              await NotificationService.instance.cancelAllPrayerNotifications();
            }
          },
        ),
      ],
    );
  }
}

class MonitoringPreference extends StatelessWidget {
  const MonitoringPreference({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
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
                      content: Text(l10nOf(context).settingsScreenMessage15),
                    ),
                  );
                }
              }
            },
          ),
        ),
    ],
  );
}

class AboutAppTile extends StatelessWidget {
  const AboutAppTile({super.key});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.info_outline),
    title: Text(l10nOf(context).settingsScreenMessage16),
    onTap: () => showAboutDialog(
      context: context,
      applicationName: l10nOf(context).appConstantsMessage1,
      children: [Text(l10nOf(context).settingsScreenMessage17)],
    ),
  );
}
