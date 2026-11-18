import 'package:sakina_app/core/widgets/sakina_hero_app_bar.dart';
import 'package:sakina_app/features/prayers/presentation/widgets/adhan_preferences.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../onboarding/presentation/widgets/alarms/alarm_menu_item.dart';
import '../../../../core/widgets/section_header.dart';
import '../widgets/diagnostics_tile.dart';
import '../widgets/reading_preferences.dart';
import '../widgets/settings_controls.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return SakinaHeroScaffold(
      title: l10nOf(context).appStringsMessage16,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          sliver: SliverList.list(
            children: [
              _SectionTitle(l10nOf(context).settingsScreenMessage1),
              _Group(
                children: [
                  const DesignPreference(),
                  const ThemePreference(),
                  const TextSizePreference(),
                  const DigitStylePreference(),
                  const HijriAdjustmentPreference(),
                  ReadingPreferencesPanel(preferences: settings.prefs),
                ],
              ),
              _SectionTitle(l10nOf(context).mainNavigationShellMessage1),
              _Group(
                children: [
                  ListTile(
                    leading: const Icon(Icons.health_and_safety_outlined),
                    title: Text(l10nOf(context).alertHealthTitle),
                    subtitle: Text(l10nOf(context).alertHealthEntrySubtitle),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/settings/alert-health'),
                  ),
                  const PrayerPreferences(),
                  const AdhanPreferences(),
                ],
              ),
              _SectionTitle(l10nOf(context).recitationSettings),
              _Group(
                children: [
                  ListTile(
                    leading: const Icon(Icons.headphones_rounded),
                    title: Text(l10nOf(context).recitationTitle),
                    subtitle: Text(l10nOf(context).recitationReciter),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/recitation'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.download_done_rounded),
                    title: Text(l10nOf(context).recitationManageDownloads),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/recitation/downloads'),
                  ),
                ],
              ),
              _SectionTitle(l10nOf(context).settingsScreenMessage9),
              _Group(
                children: [
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
                      icon: Icons.menu_book_outlined,
                      enabled: settings.isMulkAlarmEnabled,
                      toggle: settings.toggleMulkAlarm,
                    ),
                    (
                      type: 'baqarah',
                      title: l10nOf(context).homeScreenMessage32,
                      icon: Icons.auto_stories_outlined,
                      enabled: settings.isBaqarahAlarmEnabled,
                      toggle: settings.toggleBaqarahAlarm,
                    ),
                    (
                      type: 'verse',
                      title: l10nOf(context).notificationCategoryVerse,
                      icon: Icons.format_quote_rounded,
                      enabled: settings.isDailyVerseAlarmEnabled,
                      toggle: settings.toggleDailyVerseAlarm,
                    ),
                  ]) ...[
                    AlarmMenuItem(
                      title: alarm.title,
                      subtitle: l10nOf(context).settingsScreenMessage11,
                      icon: alarm.icon,
                      alarmType: alarm.type,
                      isEnabled: alarm.enabled,
                      // Turning a reminder on asks for permission first.
                      onChanged: (enabled) async {
                        if (enabled) {
                          await requestNotificationPermissionWithFeedback(
                            context,
                          );
                        }
                        await alarm.toggle(enabled);
                      },
                    ),
                  ],
                ],
              ),
              _SectionTitle(l10nOf(context).feedbackSection),
              const _Group(children: [FeedbackPreferences()]),
              _SectionTitle(l10nOf(context).settingsScreenMessage12),
              _Group(
                children: [
                  const MonitoringPreference(),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(l10nOf(context).homeScreenMessage25),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/settings/data-sources'),
                  ),
                  const DiagnosticsTile(),
                  const AboutAppTile(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => SectionHeader(title: text);
}

/// One section's controls on a single card.
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      // A Material, so rows inside keep their ripples and are clipped to
      // the card's corners.
      child: Material(
        color: SakinaDecor.of(context).card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}
