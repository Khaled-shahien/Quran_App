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
      appBar: AppBar(title: const Text('الإعدادات')),
      body: SafeArea(
        child: ListView(
          children: [
            const _SectionTitle('المظهر والقراءة'),
            Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<ThemeMode>(
                isExpanded: true,
                initialValue: theme.themeMode,
                decoration: const InputDecoration(labelText: 'مظهر التطبيق'),
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('حسب الجهاز'),
                  ),
                  DropdownMenuItem(value: ThemeMode.light, child: Text('فاتح')),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('داكن')),
                ],
                onChanged: (value) {
                  if (value != null) theme.setThemeMode(value);
                },
              ),
            ),
            ReadingPreferencesPanel(preferences: settings.prefs),
            const _SectionTitle('الصلاة'),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('الموقع وطريقة الحساب'),
              subtitle: Text(prayer.locationLabel),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => showPrayerLocationDialog(context, prayer),
            ),
            SwitchListTile(
              title: const Text('تنبيهات الصلاة'),
              subtitle: const Text('تذكير بالمواقيت حسب الموقع المحدد'),
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
            const _SectionTitle('التذكيرات اليومية'),
            for (final alarm in [
              (
                type: 'morning',
                title: 'أذكار الصباح',
                icon: Icons.wb_sunny_outlined,
                enabled: settings.isMorningAlarmEnabled,
                toggle: settings.toggleMorningAlarm,
              ),
              (
                type: 'evening',
                title: 'أذكار المساء',
                icon: Icons.nights_stay_outlined,
                enabled: settings.isEveningAlarmEnabled,
                toggle: settings.toggleEveningAlarm,
              ),
              (
                type: 'mulk',
                title: 'سورة الملك',
                icon: Icons.menu_book,
                enabled: settings.isMulkAlarmEnabled,
                toggle: settings.toggleMulkAlarm,
              ),
              (
                type: 'baqarah',
                title: 'سورة البقرة',
                icon: Icons.auto_stories,
                enabled: settings.isBaqarahAlarmEnabled,
                toggle: settings.toggleBaqarahAlarm,
              ),
            ]) ...[
              SwitchListTile(
                title: Text('تذكير ${alarm.title}'),
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
                subtitle: 'وقت التذكير',
                icon: alarm.icon,
                alarmType: alarm.type,
                isEnabled: alarm.enabled,
                onChanged: alarm.toggle,
              ),
            ],
            const _SectionTitle('عن سكينة'),
            if (MonitoringService.instance.available)
              ListenableBuilder(
                listenable: MonitoringService.instance,
                builder: (context, _) => SwitchListTile(
                  title: const Text('إرسال تقارير الأعطال وبيانات الاستخدام'),
                  subtitle: const Text(
                    'اختياري. لا يشمل الموقع أو عمليات البحث أو سجل القراءة.',
                  ),
                  value: MonitoringService.instance.enabled,
                  onChanged: (value) async {
                    try {
                      await MonitoringService.instance.setEnabled(value);
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'تعذر تغيير إعداد مشاركة البيانات. أعد المحاولة.',
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
              title: const Text('الخصوصية ومصادر المحتوى'),
              onTap: () => context.push('/settings/data-sources'),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('عن التطبيق'),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'سكينة',
                children: const [
                  Text('رفيقك اليومي للقرآن والأذكار ومواقيت الصلاة.'),
                ],
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
