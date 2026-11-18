import 'package:sakina_app/features/practice_log/domain/weekly_reflection.dart';
import 'package:sakina_app/features/settings/presentation/providers/simple_mode_controller.dart';
import 'package:sakina_app/features/prayers/presentation/widgets/iqama_sheet.dart';
import 'package:sakina_app/features/prayers/domain/entities/adhan_settings.dart';
import 'package:sakina_app/features/prayers/presentation/prayer_labels.dart';
import 'package:sakina_app/features/prayers/domain/prayer_time_adjustments.dart';
import 'package:sakina_app/features/prayers/presentation/widgets/prayer_calculation_sheets.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/core/theme/app_radius.dart';
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
import '../../../../core/services/notification_permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      // After a refusal the system may not ask again; settings always can.
      action: SnackBarAction(
        label: l10nOf(context).permissionIntroOpenSettings,
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await NotificationPermissionService(prefs: prefs).openSettings();
        },
      ),
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
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.hijriAdjustmentTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.hijriAdjustmentSubtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
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
    final l10n = l10nOf(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.settingsScreenMessage2,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<ThemeMode>(
            key: ValueKey('theme-mode-${theme.design.name}'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l10n.settingsScreenMessage3),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(l10n.settingsScreenMessage4),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(l10n.settingsScreenMessage5),
              ),
            ],
            selected: {locked ? ThemeMode.dark : theme.themeMode},
            onSelectionChanged: locked
                ? null
                : (selection) {
                    playFeedback(context, FeedbackEvent.selection);
                    theme.setThemeMode(selection.single);
                  },
          ),
          if (locked) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.designNightAlwaysDark,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
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
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => showPrayerLocationDialog(context, prayer),
        ),
        ListTile(
          leading: const Icon(Icons.tune_rounded),
          title: Text(l10nOf(context).prayerAdjustmentsTitle),
          subtitle: Text(
            prayer.adjustments.isEmpty
                ? l10nOf(context).prayerAdjustmentsSubtitle
                : [
                    for (final kind in PrayerTimeKind.values)
                      if (prayer.adjustments.of(kind) != 0)
                        '${prayerTimeKindName(l10nOf(context), kind)} '
                            '${formatAdjustment(context, prayer.adjustments.of(kind))}',
                  ].join(l10nOf(context).listSeparator),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => showPrayerAdjustmentsSheet(context, prayer),
        ),
        ListTile(
          leading: const Icon(Icons.mosque_outlined),
          title: Text(l10nOf(context).iqamaTitle),
          subtitle: Text(
            prayer.iqama.isEmpty
                ? l10nOf(context).iqamaSubtitle
                : [
                    for (final p in DailyPrayer.values)
                      if (prayer.iqama.of(p) != 0)
                        '${l10nOf(context).prayerName(p)} '
                            '${context.digits('+${prayer.iqama.of(p)}')}',
                  ].join(l10nOf(context).listSeparator),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => showIqamaSheet(context, prayer),
        ),
        SwitchListTile(
          title: Text(l10nOf(context).settingsScreenMessage7),
          subtitle: Text(l10nOf(context).settingsScreenMessage8),
          value: settings.prefs.getBool('prayer_notifications_enabled') ?? true,
          onChanged: (enabled) async {
            playFeedback(context, FeedbackEvent.toggle);
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
              await NotificationService.instance.prayers
                  .cancelAllPrayerNotifications();
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
              playFeedback(context, FeedbackEvent.toggle);
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
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

/// Simple mode, with larger text turned on the first time.
class SimpleModePreference extends StatelessWidget {
  const SimpleModePreference({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final simple = context.watch<SimpleModeController?>();
    if (simple == null) return const SizedBox.shrink();
    return SwitchListTile(
      key: const Key('simple-mode'),
      secondary: const Icon(Icons.grid_view_rounded),
      title: Text(l10n.simpleModeTitle),
      subtitle: Text(l10n.simpleModeHelp),
      isThreeLine: true,
      value: simple.enabled,
      onChanged: (on) async {
        playFeedback(context, FeedbackEvent.toggle);
        final text = context.read<TextSizeController?>();
        await simple.setEnabled(on);
        if (on && text != null && text.size == AppTextSize.normal) {
          await text.setSize(AppTextSize.large);
        }
      },
    );
  }
}

/// The Friday "your week" card on Home; off until the user turns it on.
class WeeklyReflectionPreference extends StatefulWidget {
  const WeeklyReflectionPreference({super.key});

  @override
  State<WeeklyReflectionPreference> createState() =>
      _WeeklyReflectionPreferenceState();
}

class _WeeklyReflectionPreferenceState
    extends State<WeeklyReflectionPreference> {
  @override
  Widget build(BuildContext context) {
    final prefs = context.read<SharedPreferences?>();
    if (prefs == null) return const SizedBox.shrink();
    final l10n = l10nOf(context);
    return SwitchListTile(
      key: const Key('weekly-reflection-setting'),
      secondary: const Icon(Icons.auto_awesome_outlined),
      title: Text(l10n.weeklySettingTitle),
      subtitle: Text(l10n.weeklySettingHelp),
      isThreeLine: true,
      value: prefs.getBool(WeeklyReflection.enabledKey) ?? false,
      onChanged: (on) async {
        playFeedback(context, FeedbackEvent.toggle);
        await prefs.setBool(WeeklyReflection.enabledKey, on);
        if (mounted) setState(() {});
      },
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
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.digitStyle, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<DigitStyle>(
            key: const Key('digit-style'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: DigitStyle.western,
                label: Text(l10n.digitStyleWestern),
              ),
              ButtonSegment(
                value: DigitStyle.arabic,
                label: Text(l10n.digitStyleArabic),
              ),
            ],
            selected: {controller.style},
            onSelectionChanged: (selection) {
              playFeedback(context, FeedbackEvent.selection);
              controller.setStyle(selection.single);
            },
          ),
        ],
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
          onChanged: (value) async {
            await feedback.setHapticsEnabled(value);
            // Confirms the choice by feel when it was just turned on.
            feedback.play(FeedbackEvent.toggle);
          },
        ),
        SwitchListTile(
          key: const Key('feedback-sounds'),
          secondary: const Icon(Icons.volume_up_outlined),
          title: Text(l10n.feedbackSounds),
          subtitle: Text(l10n.feedbackSoundsHint),
          value: feedback.soundsEnabled,
          onChanged: (value) async {
            await feedback.setSoundsEnabled(value);
            // Turning sounds on plays one, so the choice is heard.
            feedback.play(value ? FeedbackEvent.success : FeedbackEvent.toggle);
          },
        ),
      ],
    );
  }
}

/// Lets the user switch between the app's three visual directions.
class DesignPreference extends StatelessWidget {
  const DesignPreference({super.key});

  /// Primary, page and accent of each design, read from its palette so the
  /// preview can never drift from the real theme.
  static List<Color> _preview(AppPalette p) => [
    p.primary,
    p.background,
    p.decor.accent,
  ];

  static final _swatches = {
    AppDesign.warm: _preview(AppPalette.warmLight),
    AppDesign.sage: _preview(AppPalette.sageLight),
    // Night's primary is its accent, so show its two surfaces instead.
    AppDesign.night: [
      AppPalette.night.background,
      AppPalette.night.decor.card,
      AppPalette.night.decor.accent,
    ],
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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.designTitle, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          for (final design in AppDesign.values)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Semantics(
                inMutuallyExclusiveGroup: true,
                checked: provider.design == design,
                child: Material(
                  color: provider.design == design
                      ? scheme.primary.withValues(alpha: 0.10)
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.card,
                    side: BorderSide(
                      color: provider.design == design
                          ? scheme.primary
                          : scheme.outline.withValues(alpha: 0.5),
                      width: provider.design == design ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    key: Key('design-${design.name}'),
                    borderRadius: AppRadius.card,
                    onTap: () {
                      if (provider.design != design) {
                        playFeedback(context, FeedbackEvent.selection);
                      }
                      provider.setDesign(design);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.ms),
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
                                      end: AppSpacing.xs,
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
                          const SizedBox(width: AppSpacing.ms),
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
                            Icon(
                              Icons.check_circle_rounded,
                              color: scheme.primary,
                            ),
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
