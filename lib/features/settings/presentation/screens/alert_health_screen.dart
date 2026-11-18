import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/services/alert_health.dart';
import 'package:sakina_app/core/services/notification_permission_service.dart';
import 'package:sakina_app/core/services/notification_service.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/core/widgets/sakina_hero_app_bar.dart';
import 'package:sakina_app/features/prayers/presentation/providers/adhan_settings_controller.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_times_provider.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "Will my adhan arrive?": reads, on this device and now, everything that
/// decides whether prayer alerts arrive on time, and offers the fix for
/// each problem. Re-checks when the user comes back from system settings.
class AlertHealthScreen extends StatefulWidget {
  const AlertHealthScreen({super.key, this.checker});

  /// Injected in tests; built from the app's services otherwise.
  final AlertHealthChecker? checker;

  @override
  State<AlertHealthScreen> createState() => _AlertHealthScreenState();
}

class _AlertHealthScreenState extends State<AlertHealthScreen>
    with WidgetsBindingObserver {
  late final AlertHealthChecker _checker;
  AlertHealthSnapshot? _snapshot;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final SharedPreferences prefs = context.read<SharedPreferences>();
    _checker =
        widget.checker ??
        AlertHealthChecker(
          prefs: prefs,
          notificationStatus: NotificationPermissionService(
            prefs: prefs,
          ).status,
          exactAlarms: NotificationService.instance.canScheduleExactAlarms,
          pendingIds: () async => [
            for (final p
                in await NotificationService.instance.getPendingNotifications())
              p.id,
          ],
        );
    unawaited(_check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_check());
  }

  Future<void> _check() async {
    final AlertHealthSnapshot snapshot = await _checker.check();
    if (mounted) setState(() => _snapshot = snapshot);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _check();
  }

  String _time(DateTime? at) {
    final l10n = l10nOf(context);
    if (at == null) return l10n.diagnosticsNever;
    final m = MaterialLocalizations.of(context);
    return context.digits(
      '${m.formatShortDate(at)} ${m.formatTimeOfDay(TimeOfDay.fromDateTime(at))}',
    );
  }

  ({String title, String detail, String? action, Future<void> Function()? fix})
  _describe(AlertHealthIssue issue) {
    final l10n = l10nOf(context);
    final SharedPreferences prefs = context.read<SharedPreferences>();
    final PrayerTimesProvider? prayer = context.read<PrayerTimesProvider?>();
    return switch (issue) {
      AlertHealthIssue.notificationsOff => (
        title: l10n.alertHealthNotificationsOff,
        detail: l10n.alertHealthNotificationsOffDetail,
        action: l10n.alertHealthOpenSettings,
        fix: () async {
          final service = NotificationPermissionService(prefs: prefs);
          final status = await service.request();
          if (status != NotificationPermissionStatus.granted) {
            await service.openSettings();
          }
        },
      ),
      AlertHealthIssue.prayerAlertsDisabled => (
        title: l10n.alertHealthAlertsDisabled,
        detail: l10n.alertHealthAlertsDisabledDetail,
        action: null,
        fix: null,
      ),
      AlertHealthIssue.noLocation => (
        title: l10n.alertHealthNoLocation,
        detail: l10n.alertHealthNoLocationDetail,
        action: null,
        fix: null,
      ),
      AlertHealthIssue.nothingScheduled => (
        title: l10n.alertHealthNothingScheduled,
        detail: l10n.alertHealthNothingScheduledDetail,
        action: l10n.alertHealthReschedule,
        fix: prayer?.refresh,
      ),
      AlertHealthIssue.exactAlarmsOff => (
        title: l10n.alertHealthExactOff,
        detail: l10n.alertHealthExactOffDetail,
        action: l10n.exactAlarmAllow,
        fix: () async {
          await NotificationService.instance.requestExactAlarmPermission();
        },
      ),
      AlertHealthIssue.batteryRestricted => (
        title: l10n.alertHealthBattery,
        detail: l10n.alertHealthBatteryDetail,
        action: l10n.batteryOpenSettings,
        fix: () async {
          await BatteryOptimization.openSettings();
        },
      ),
      AlertHealthIssue.backgroundFailing => (
        title: l10n.alertHealthBackgroundFailing,
        detail: l10n.alertHealthBackgroundFailingDetail,
        action: l10n.alertHealthReschedule,
        fix: prayer?.refresh,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final ThemeData theme = Theme.of(context);
    final AlertHealthSnapshot? snapshot = _snapshot;
    final AdhanSettingsController? adhan = context
        .watch<AdhanSettingsController?>();
    return SakinaHeroScaffold(
      title: l10n.alertHealthTitle,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverList.list(
            children: [
              if (snapshot == null)
                const Center(child: CircularProgressIndicator())
              else ...[
                Card(
                  color: snapshot.healthy
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.errorContainer,
                  child: ListTile(
                    leading: Icon(
                      snapshot.healthy
                          ? Icons.verified_rounded
                          : Icons.report_problem_rounded,
                    ),
                    title: Text(
                      snapshot.healthy
                          ? l10n.alertHealthAllGood
                          : l10n.alertHealthProblems(
                              context.digits(snapshot.issues.length),
                            ),
                    ),
                    subtitle: Text(
                      l10n.alertHealthScheduledCount(
                        context.digits(snapshot.pendingPrayerAlerts),
                      ),
                    ),
                  ),
                ),
                for (final AlertHealthIssue issue in snapshot.issues)
                  Builder(
                    builder: (context) {
                      final d = _describe(issue);
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(d.title, style: theme.textTheme.titleSmall),
                              const SizedBox(height: AppSpacing.xs),
                              Text(d.detail, style: theme.textTheme.bodySmall),
                              if (d.action != null && d.fix != null)
                                Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _run(d.fix!),
                                    child: Text(d.action!),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  leading: const Icon(Icons.history_rounded),
                  title: Text(l10n.alertHealthLastBackground),
                  subtitle: Text(_time(snapshot.lastBackgroundRun)),
                ),
                if (adhan != null)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.notifications_active_rounded),
                      label: Text(l10n.testAdhanButton),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final bool scheduled = await adhan.scheduleTest();
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
                Text(
                  l10n.alertHealthFootnote,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
