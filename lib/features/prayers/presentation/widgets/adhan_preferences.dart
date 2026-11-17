import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../../../recitation/presentation/providers/recitation_controller.dart';
import '../../domain/adhan_voices.dart';
import '../../domain/entities/adhan_settings.dart';
import '../adhan_preview_player.dart';
import '../adhan_voice_labels.dart';
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
  const AdhanPreferences({super.key, this.previewPlayer});

  /// Replaces the audio player, for tests. The widget owns the default one.
  final AdhanPreviewPlayer? previewPlayer;

  @override
  State<AdhanPreferences> createState() => _AdhanPreferencesState();
}

class _AdhanPreferencesState extends State<AdhanPreferences> {
  late final AdhanPreviewPlayer _preview =
      widget.previewPlayer ?? JustAudioAdhanPreviewPlayer();

  /// Full adhan recordings play through Android notification channels.
  /// iOS notification sounds are limited to 30 seconds, so there the adhan
  /// option keeps the alert sound and says so.
  static bool get _adhanSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void dispose() {
    if (widget.previewPlayer == null) {
      _preview.dispose();
    } else {
      _preview.stop();
    }
    super.dispose();
  }

  Future<void> _togglePreview(AdhanVoice voice) async {
    if (_preview.playing.value == voice.id) {
      await _preview.stop();
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failed = l10nOf(context).adhanPreviewFailed;
    // Never play over recitation.
    await context.read<RecitationController?>()?.pauseForInterruption();
    try {
      await _preview.play(voice);
    } catch (_) {
      messenger?.showSnackBar(SnackBar(content: Text(failed)));
    }
  }

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
        for (final prayer in DailyPrayer.values) ...[
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(child: Text(l10n.prayerName(prayer))),
                const SizedBox(width: AppSpacing.ms),
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
          if (_adhanSupported &&
              settings.modeFor(prayer) == PrayerAlertMode.adhan)
            _voiceRow(context, c, prayer),
        ],
        if (usesAdhan)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(
              _adhanSupported ? l10n.adhanStopHint : l10n.adhanNotSupported,
              style: theme.textTheme.bodySmall,
            ),
          ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
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
          padding: const EdgeInsets.all(AppSpacing.md),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.notifications_active_rounded),
            label: Text(l10n.testAdhanButton),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final scheduled = await c.scheduleTest();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    scheduled
                        ? l10n.testAdhanScheduled
                        : l10n.notificationPermissionDeniedMessage,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// The recording [prayer] plays, with a button to listen to it.
  Widget _voiceRow(
    BuildContext context,
    AdhanSettingsController c,
    DailyPrayer prayer,
  ) {
    final l10n = l10nOf(context);
    const options = AdhanVoices.all;
    final selected = c.settings.voiceFor(prayer);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: options.length > 1
                ? DropdownButtonFormField<String>(
                    key: Key('adhan-voice-${prayer.name}'),
                    initialValue: selected.id,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.adhanVoiceTitle,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final v in options)
                        DropdownMenuItem(
                          value: v.id,
                          child: Text(l10n.adhanVoiceName(v)),
                        ),
                    ],
                    onChanged: (id) {
                      if (id == null) return;
                      _preview.stop();
                      c.setVoice(prayer, id);
                    },
                  )
                : InputDecorator(
                    key: Key('adhan-voice-${prayer.name}'),
                    decoration: InputDecoration(
                      labelText: l10n.adhanVoiceTitle,
                      border: const OutlineInputBorder(),
                    ),
                    child: Text(l10n.adhanVoiceName(selected)),
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ValueListenableBuilder<String?>(
            valueListenable: _preview.playing,
            builder: (context, playing, _) {
              final isPlaying = playing == selected.id;
              return IconButton(
                key: Key('adhan-preview-${prayer.name}'),
                tooltip: isPlaying
                    ? l10n.adhanPreviewStop
                    : l10n.adhanPreviewPlay,
                icon: Icon(
                  isPlaying
                      ? Icons.stop_circle_rounded
                      : Icons.play_circle_rounded,
                ),
                onPressed: () => _togglePreview(selected),
              );
            },
          ),
        ],
      ),
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
