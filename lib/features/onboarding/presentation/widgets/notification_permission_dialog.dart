import 'package:sakina_app/core/theme/app_spacing.dart';
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        // Scrolls so large text cannot push the answers off a small screen.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.secondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_active_outlined,
                  size: 38,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10nOf(context).notificationPermissionDialogMessage1,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10nOf(context).notificationPermissionDialogMessage2,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              // The buttons take their colours and shape from the theme.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _handlePermissionRequest(context, true);
                  },
                  child: Text(
                    l10nOf(context).notificationPermissionDialogMessage3,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    await _handlePermissionRequest(context, false);
                  },
                  child: Text(
                    l10nOf(context).notificationPermissionDialogMessage4,
                    textAlign: TextAlign.center,
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
