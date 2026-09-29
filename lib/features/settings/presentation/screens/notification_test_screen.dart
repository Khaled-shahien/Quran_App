import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/notification_provider.dart';

/// Diagnostic screen for verifying notification permissions and scheduling.
class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialNotificationState();
    });
  }

  Future<void> _loadInitialNotificationState() async {
    final provider = context.read<NotificationProvider>();
    await provider.initialize();
    await provider.getPendingNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10nOf(context).notificationTestScreenMessage1),
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionCard(
                  title: l10nOf(context).notificationTestScreenMessage2,
                  icon: Icons.verified_user_outlined,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _requestPermissions(provider),
                      icon: const Icon(Icons.lock_open_outlined),
                      label: Text(
                        l10nOf(context).notificationTestScreenMessage13,
                      ),
                    ),
                    _InfoRow(
                      label: l10nOf(context).notificationTestScreenMessage5,
                      value: provider.isInitialized
                          ? l10nOf(context).notificationTestScreenMessage6
                          : l10nOf(context).notificationTestScreenMessage7,
                    ),
                  ],
                ),
                _SectionCard(
                  title: l10nOf(context).notificationTestScreenMessage8,
                  icon: Icons.notifications_active_outlined,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () => _showImmediateNotification(provider),
                          icon: const Icon(Icons.flash_on),
                          label: Text(
                            l10nOf(context).notificationTestScreenMessage9,
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () =>
                              _scheduleDelayedNotification(provider),
                          icon: const Icon(Icons.schedule),
                          label: Text(
                            l10nOf(context).notificationTestScreenMessage10,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _cancelAllNotifications(provider),
                          icon: const Icon(Icons.delete_sweep_outlined),
                          label: Text(
                            l10nOf(context).notificationTestScreenMessage11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                _SectionCard(
                  title: l10nOf(context).notificationTestScreenMessage17,
                  icon: Icons.pending_actions_outlined,
                  trailing: TextButton.icon(
                    onPressed: () => provider.getPendingNotifications(),
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      l10nOf(context).notificationTestScreenMessage15,
                    ),
                  ),
                  children: [
                    if (provider.pendingNotifications.isEmpty)
                      Text(
                        l10nOf(context).notificationTestScreenMessage18,
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    else
                      ...provider.pendingNotifications.map(
                        (notification) => _PendingNotificationTile(
                          notification: notification,
                          onCancel: () => _cancelNotification(
                            provider,
                            notification['id'] as int,
                          ),
                        ),
                      ),
                  ],
                ),
                _SectionCard(
                  title: l10nOf(context).notificationTestScreenMessage19,
                  icon: Icons.alarm_on_outlined,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _rescheduleAlarms(provider),
                      icon: const Icon(Icons.restart_alt),
                      label: Text(
                        l10nOf(context).notificationTestScreenMessage20,
                      ),
                    ),
                  ],
                ),
                _SectionCard(
                  title: l10nOf(context).notificationTestScreenMessage21,
                  icon: Icons.bug_report_outlined,
                  trailing: TextButton.icon(
                    onPressed: provider.clearLogs,
                    icon: const Icon(Icons.clear_all),
                    label: Text(
                      l10nOf(context).notificationTestScreenMessage22,
                    ),
                  ),
                  children: [
                    if (provider.debugLogs.isEmpty)
                      Text(
                        l10nOf(context).notificationTestScreenMessage23,
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    else
                      ...provider.debugLogs.map(
                        (log) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            log,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showImmediateNotification(NotificationProvider provider) async {
    try {
      await provider.scheduleTestNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: appL10n.notificationTestScreenMessage24,
        body: appL10n.notificationTestScreenMessage25,
      );
      if (!mounted) return;
      _showSnackBar(appL10n.notificationTestScreenMessage26);
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(
        appL10n.notificationTestScreenMessage27((error).toString()),
      );
    }
  }

  Future<void> _scheduleDelayedNotification(
    NotificationProvider provider,
  ) async {
    try {
      await provider.scheduleDelayedNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: appL10n.notificationTestScreenMessage10,
        body: appL10n.notificationTestScreenMessage28,
      );
      await provider.getPendingNotifications();
      if (!mounted) return;
      _showSnackBar(appL10n.notificationTestScreenMessage29);
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(
        appL10n.notificationTestScreenMessage30((error).toString()),
      );
    }
  }

  Future<void> _cancelAllNotifications(NotificationProvider provider) async {
    await provider.cancelAllNotifications();
    await provider.getPendingNotifications();
    if (!mounted) return;
    _showSnackBar(appL10n.notificationTestScreenMessage31);
  }

  Future<void> _requestPermissions(NotificationProvider provider) async {
    await provider.requestPermissions();
    if (!mounted) return;
    _showSnackBar(appL10n.notificationTestScreenMessage32);
  }

  Future<void> _cancelNotification(
    NotificationProvider provider,
    int id,
  ) async {
    await provider.cancelNotification(id);
    await provider.getPendingNotifications();
  }

  Future<void> _rescheduleAlarms(NotificationProvider provider) async {
    await provider.rescheduleAllAlarms();
    if (!mounted) return;
    _showSnackBar(appL10n.notificationTestScreenMessage35);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _PendingNotificationTile extends StatelessWidget {
  const _PendingNotificationTile({
    required this.notification,
    required this.onCancel,
  });

  final Map<String, dynamic> notification;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(notification['title']?.toString() ?? ''),
      subtitle: Text(notification['body']?.toString() ?? ''),
      trailing: IconButton(
        tooltip: l10nOf(context).appStringsMessage9,
        icon: const Icon(Icons.cancel),
        onPressed: onCancel,
      ),
    );
  }
}
