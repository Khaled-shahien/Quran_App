import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/providers/notification_provider.dart';
import '../../domain/first_run_state.dart';

/// Explains reminders once, when a saved prayer location first makes them
/// useful, instead of asking for permission during onboarding.
Future<void> promptForNotificationPermissionOnce(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  if ((prefs.getBool(notificationPromptSeenKey) ?? false) ||
      !(prefs.getBool('prayer_notifications_enabled') ?? true) ||
      !context.mounted) {
    return;
  }
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => NotificationPermissionDialog(
      onFinish: () => Navigator.of(dialogContext).pop(),
    ),
  );
}

class NotificationPermissionDialog extends StatelessWidget {
  final VoidCallback onFinish;

  const NotificationPermissionDialog({super.key, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        // Scrolls so large text cannot push the answers off a small screen.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10nOf(context).notificationPermissionDialogMessage1,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10nOf(context).notificationPermissionDialogMessage2,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: double.infinity,
                  minHeight: 56,
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    await _handlePermissionRequest(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10nOf(context).notificationPermissionDialogMessage3,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: double.infinity,
                  minHeight: 50,
                ),
                child: TextButton(
                  onPressed: () async {
                    await _handlePermissionRequest(context, false);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10nOf(context).notificationPermissionDialogMessage4,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePermissionRequest(
    BuildContext context,
    bool accept,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(notificationPromptSeenKey, true);

    if (accept) {
      if (context.mounted) {
        final provider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );
        await provider.requestPermissions();
      }
    }
    onFinish();
  }
}
