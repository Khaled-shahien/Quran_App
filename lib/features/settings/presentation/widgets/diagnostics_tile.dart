import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina_app/core/services/diagnostics_log.dart';
import 'package:sakina_app/core/services/workmanager_service.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/l10n/localization.dart';

/// Settings row for the on-device diagnostics log: when background alert
/// rescheduling last succeeded or failed, and recent error types. Lets a
/// user copy the log into a support message; nothing is sent by the app.
class DiagnosticsTile extends StatelessWidget {
  const DiagnosticsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return ListTile(
      leading: const Icon(Icons.monitor_heart_outlined),
      title: Text(l10n.diagnosticsTitle),
      subtitle: Text(l10n.diagnosticsSubtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) =>
            DiagnosticsDialog(preferences: context.read<SharedPreferences>()),
      ),
    );
  }
}

class DiagnosticsDialog extends StatefulWidget {
  const DiagnosticsDialog({super.key, required this.preferences});

  final SharedPreferences preferences;

  @override
  State<DiagnosticsDialog> createState() => _DiagnosticsDialogState();
}

class _DiagnosticsDialogState extends State<DiagnosticsDialog> {
  SharedPreferences get _prefs => widget.preferences;

  String _time(DateTime? at) {
    if (at == null) return l10nOf(context).diagnosticsNever;
    final local = at.toLocal();
    final m = MaterialLocalizations.of(context);
    return '${m.formatShortDate(local)} '
        '${m.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
  }

  List<String> _lines() {
    final l10n = l10nOf(context);
    final okMs = _prefs.getInt(kLastBackgroundRescheduleAtMsKey);
    final errorAt = DateTime.tryParse(
      _prefs.getString(DiagnosticsLog.backgroundErrorAtKey) ?? '',
    );
    return [
      l10n.diagnosticsLastBackgroundOk(
        _time(okMs == null ? null : DateTime.fromMillisecondsSinceEpoch(okMs)),
      ),
      if (errorAt != null)
        l10n.diagnosticsLastBackgroundError(
          _time(errorAt),
          _prefs.getString(DiagnosticsLog.backgroundErrorTypeKey) ?? '',
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final entries = DiagnosticsLog.entries(_prefs).reversed.toList();
    final summary = _lines();
    return AlertDialog(
      title: Text(l10n.diagnosticsTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final line in summary)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(line),
              ),
            const Divider(),
            if (entries.isEmpty)
              Text(l10n.diagnosticsEmpty)
            else
              for (final entry in entries)
                // Technical text: error type names are English identifiers.
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    entry.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: entries.isEmpty
              ? null
              : () async {
                  await DiagnosticsLog.clear(_prefs);
                  if (mounted) setState(() {});
                },
          child: Text(l10n.diagnosticsClear),
        ),
        TextButton(
          onPressed: () async {
            final messenger = ScaffoldMessenger.maybeOf(context);
            await Clipboard.setData(
              ClipboardData(
                text: [...summary, ...entries.map((e) => '$e')].join('\n'),
              ),
            );
            messenger?.showSnackBar(
              SnackBar(content: Text(l10n.diagnosticsCopied)),
            );
          },
          child: Text(l10n.diagnosticsCopy),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }
}
