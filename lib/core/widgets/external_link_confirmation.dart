import 'package:flutter/material.dart';
import 'package:sakina_app/core/utils/external_links.dart';
import 'package:sakina_app/l10n/localization.dart';

/// What happened when the user tried to open an external link.
enum ExternalLinkOutcome { opened, cancelled, failed }

/// Asks before leaving the app. Returns true only on an explicit "continue";
/// dismissing the dialog counts as "no".
Future<bool> confirmLeavingApp(BuildContext context) async {
  final l10n = l10nOf(context);
  final bool? accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.externalLinkTitle),
      content: Text(l10n.externalLinkMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.appStringsMessage9),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.externalLinkContinue),
        ),
      ],
    ),
  );
  return accepted ?? false;
}

/// Confirms with the user, then opens [url] outside the app.
///
/// Only http/https URLs are ever launched (see [openWebUrl]).
Future<ExternalLinkOutcome> openExternalLinkWithConsent(
  BuildContext context,
  String url, {
  Future<bool> Function(Uri uri)? launcher,
}) async {
  if (parseWebUrl(url) == null) return ExternalLinkOutcome.failed;
  if (!await confirmLeavingApp(context)) return ExternalLinkOutcome.cancelled;
  final opened = await openWebUrl(url, launcher: launcher);
  return opened ? ExternalLinkOutcome.opened : ExternalLinkOutcome.failed;
}
