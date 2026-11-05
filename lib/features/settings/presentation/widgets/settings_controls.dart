import 'package:sakina_app/core/feedback/feedback_service.dart';
import 'package:sakina_app/core/theme/app_design.dart';
import 'package:flutter/material.dart';
import '../providers/text_size_controller.dart';
import '../providers/digit_style_controller.dart';
import '../../../../core/accessibility/digit_style.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/l10n/localization.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/monitoring_service.dart';
import '../../../prayers/domain/prayer_calculation_policy.dart';
import '../../../prayers/presentation/providers/prayer_times_provider.dart';
import '../../../prayers/presentation/screens/prayer_location_dialog.dart';

/// Enabling a reminder asks for permission. A refusal is explained, because
/// the switch stays on but the reminder could not be delivered.
Future<void> requestNotificationPermissionWithFeedback(
  BuildContext context, {
  Future<bool> Function()? request,
}) async {
  final granted =
      await (request ?? NotificationService.instance.requestPermissions)();
  if (granted || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(l10nOf(context).notificationPermissionDeniedMessage),
    ),
  );
}

/// -1 / 0 / +1 day correction of the Hijri date.
class HijriAdjustmentPreference extends StatelessWidget {
  const HijriAdjustmentPreference({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final l10n = l10nOf(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.hijriAdjustmentTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.hijriAdjustmentSubtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: -1,
                label: Text(l10n.hijriAdjustmentMinusOne),
              ),
              ButtonSegment(value: 0, label: Text(l10n.hijriAdjustmentNone)),
              ButtonSegment(value: 1, label: Text(l10n.hijriAdjustmentPlusOne)),
            ],
            selected: {settings.hijriOffsetDays},
            onSelectionChanged: (selection) =>
                settings.setHijriOffsetDays(selection.single),
          ),
        ],
      ),
    );
  }
}

class ThemePreference extends StatelessWidget {
  const ThemePreference({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final locked = theme.design.alwaysDark;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: DropdownButtonFormField<ThemeMode>(
        key: ValueKey('theme-mode-${theme.design.name}'),
        isExpanded: true,
        initialValue: locked ? ThemeMode.dark : theme.themeMode,
        decoration: InputDecoration(
          labelText: l10nOf(context).settingsScreenMessage2,
          helperText: locked ? l10nOf(context).designNightAlwaysDark : null,
          helperMaxLines: 2,
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
        onChanged: locked
            ? null
            : (value) {
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
              if (context.mounted) {
                await requestNotificationPermissionWithFeedback(context);
              }
              await prayer.refresh();
            } else {
              await NotificationService.instance.cancelAllPrayerNotifications();
            }
          },
        ),
        RadioGroup<AsrMadhab>(
          groupValue: prayer.asrMadhab,
          onChanged: (value) {
            if (value != null) prayer.setAsrMadhab(value);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(title: Text(l10nOf(context).asrMadhabTitle)),
              RadioListTile<AsrMadhab>(
                value: AsrMadhab.standard,
                title: Text(l10nOf(context).asrMadhabStandard),
              ),
              RadioListTile<AsrMadhab>(
                value: AsrMadhab.hanafi,
                title: Text(l10nOf(context).asrMadhabHanafi),
              ),
            ],
          ),
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

class TextSizePreference extends StatelessWidget {
  const TextSizePreference({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final controller = context.watch<TextSizeController>();
    final labels = {
      AppTextSize.normal: l10n.appTextSizeNormal,
      AppTextSize.large: l10n.appTextSizeLarge,
      AppTextSize.larger: l10n.appTextSizeLarger,
      AppTextSize.largest: l10n.appTextSizeLargest,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<AppTextSize>(
        key: const Key('app-text-size'),
        isExpanded: true,
        initialValue: controller.size,
        decoration: InputDecoration(
          labelText: l10n.appTextSize,
          helperText: l10n.appTextSizeHint,
          helperMaxLines: 3,
        ),
        items: [
          for (final size in AppTextSize.values)
            DropdownMenuItem(value: size, child: Text(labels[size]!)),
        ],
        onChanged: (value) {
          if (value != null) controller.setSize(value);
        },
      ),
    );
  }
}

class DigitStylePreference extends StatelessWidget {
  const DigitStylePreference({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final controller = context.watch<DigitStyleController>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<DigitStyle>(
        key: const Key('digit-style'),
        isExpanded: true,
        initialValue: controller.style,
        decoration: InputDecoration(labelText: l10n.digitStyle),
        items: [
          DropdownMenuItem(
            value: DigitStyle.western,
            child: Text(l10n.digitStyleWestern),
          ),
          DropdownMenuItem(
            value: DigitStyle.arabic,
            child: Text(l10n.digitStyleArabic),
          ),
        ],
        onChanged: (value) {
          if (value != null) controller.setStyle(value);
        },
      ),
    );
  }
}

/// Touch and sound feedback. Vibration is on by default; sounds are off.
class FeedbackPreferences extends StatelessWidget {
  const FeedbackPreferences({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final feedback = context.watch<FeedbackService>();
    return Column(
      children: [
        SwitchListTile(
          key: const Key('feedback-haptics'),
          secondary: const Icon(Icons.vibration_rounded),
          title: Text(l10n.feedbackHaptics),
          subtitle: Text(l10n.feedbackHapticsHint),
          value: feedback.hapticsEnabled,
          onChanged: feedback.setHapticsEnabled,
        ),
        SwitchListTile(
          key: const Key('feedback-sounds'),
          secondary: const Icon(Icons.volume_up_outlined),
          title: Text(l10n.feedbackSounds),
          subtitle: Text(l10n.feedbackSoundsHint),
          value: feedback.soundsEnabled,
          onChanged: feedback.setSoundsEnabled,
        ),
      ],
    );
  }
}

/// Lets the user switch between the app's three visual directions.
class DesignPreference extends StatelessWidget {
  const DesignPreference({super.key});

  static const _swatches = {
    AppDesign.warm: [Color(0xFF795547), Color(0xFFFEFBF4), Color(0xFFCC9B76)],
    AppDesign.sage: [Color(0xFF1F5C4A), Color(0xFFF6F4EE), Color(0xFFC9A66B)],
    AppDesign.night: [Color(0xFF101826), Color(0xFF182235), Color(0xFFD4AF6A)],
  };

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final provider = context.watch<ThemeProvider>();
    final scheme = Theme.of(context).colorScheme;
    final names = {
      AppDesign.warm: (l10n.designWarm, l10n.designWarmHint),
      AppDesign.sage: (l10n.designSage, l10n.designSageHint),
      AppDesign.night: (l10n.designNight, l10n.designNightHint),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.designTitle, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final design in AppDesign.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Semantics(
                inMutuallyExclusiveGroup: true,
                checked: provider.design == design,
                child: Material(
                  color: provider.design == design
                      ? scheme.primary.withValues(alpha: 0.10)
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: provider.design == design
                          ? scheme.primary
                          : scheme.outline.withValues(alpha: 0.5),
                      width: provider.design == design ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    key: Key('design-${design.name}'),
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => provider.setDesign(design),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ExcludeSemantics(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final color in _swatches[design]!)
                                  Container(
                                    width: 22,
                                    height: 22,
                                    margin: const EdgeInsetsDirectional.only(
                                      end: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: scheme.outline.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  names[design]!.$1,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  names[design]!.$2,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (provider.design == design)
                            Icon(Icons.check_circle, color: scheme.primary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
