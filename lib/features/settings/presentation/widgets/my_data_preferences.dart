import 'dart:async';

import 'package:sakina_app/core/services/backup_encryption.dart';
import 'package:sakina_app/features/quran/data/repositories/hifz_repository.dart';
import 'package:sakina_app/features/practice_log/data/practice_log_repository.dart';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/app/app_restart.dart';
import 'package:sakina_app/core/database/app_database.dart';
import 'package:sakina_app/core/services/user_data_backup.dart';
import 'package:sakina_app/features/quran/data/repositories/verse_library_repository.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Picks and saves files; injected in tests.
abstract class BackupFiles {
  Future<bool> save(String fileName, Uint8List bytes);
  Future<String?> pick();
}

class PlatformBackupFiles implements BackupFiles {
  const PlatformBackupFiles();

  @override
  Future<bool> save(String fileName, Uint8List bytes) async =>
      await FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/json',
      ) !=
      null;

  @override
  Future<String?> pick() async {
    final PlatformFile? file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return null;
    return utf8.decode(await file.readAsBytes(), allowMalformed: true);
  }
}

/// Settings rows to export the user's data to a file, restore it, or
/// erase it. Nothing is uploaded anywhere: the user chooses the file.
class MyDataPreferences extends StatelessWidget {
  const MyDataPreferences({
    super.key,
    this.files = const PlatformBackupFiles(),
    this.backup,
    this.restart = restartAfterDataChange,
    this.cipherCost = BackupCipher.defaultCost,
  });

  final BackupFiles files;
  final UserDataBackup? backup;
  final Future<void> Function() restart;

  /// Key-derivation cost for new encrypted files; lowered in tests.
  final Argon2Cost cipherCost;

  UserDataBackup _backup() =>
      backup ??
      UserDataBackup(
        prefs: GetIt.instance<SharedPreferences>(),
        library: VerseLibraryRepository(GetIt.instance.getAsync<AppDatabase>),
        otherTables: [
          PracticeLogRepository(GetIt.instance.getAsync<PrivateDatabase>),
          HifzRepository(GetIt.instance.getAsync<AppDatabase>),
        ],
      );

  /// Replaces any message still showing, so the latest outcome is seen.
  void _snack(BuildContext context, String text) =>
      ScaffoldMessenger.maybeOf(context)
        ?..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));

  /// Runs [work] in another isolate behind a "one moment" dialog, so key
  /// derivation never freezes the screen.
  Future<T> _busy<T>(BuildContext context, Future<T> work) async {
    final navigator = Navigator.of(context);
    final String working = l10nOf(context).myDataWorking;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(child: Text(working)),
            ],
          ),
        ),
      ),
    );
    try {
      return await work;
    } finally {
      navigator.pop();
    }
  }

  Future<void> _export(BuildContext context) async {
    final l10n = l10nOf(context);
    final String? passphrase = await showDialog<String>(
      context: context,
      builder: (_) => const _PassphraseDialog(forExport: true),
    );
    if (passphrase == null || !context.mounted) return;
    try {
      String json = await _backup().export();
      if (passphrase.isNotEmpty) {
        if (!context.mounted) return;
        final cost = cipherCost;
        final plain = json;
        json = await _busy(
          context,
          compute(_encryptJob, (plain, passphrase, cost)),
        );
      }
      final DateTime now = DateTime.now();
      final String name =
          'sakina-backup-${now.year}-${now.month.toString().padLeft(2, '0')}'
          '-${now.day.toString().padLeft(2, '0')}.json';
      final bool saved = await files.save(
        name,
        Uint8List.fromList(utf8.encode(json)),
      );
      if (context.mounted && saved) _snack(context, l10n.myDataExported);
    } catch (_) {
      if (context.mounted) _snack(context, l10n.myDataFailed);
    }
  }

  Future<void> _import(BuildContext context) async {
    final l10n = l10nOf(context);
    String? raw;
    try {
      raw = await files.pick();
    } catch (_) {
      if (context.mounted) _snack(context, l10n.myDataFailed);
      return;
    }
    if (raw == null || !context.mounted) return;
    if (BackupCipher.isEncrypted(raw)) {
      final String? passphrase = await showDialog<String>(
        context: context,
        builder: (_) => const _PassphraseDialog(forExport: false),
      );
      if (passphrase == null || !context.mounted) return;
      final String locked = raw;
      try {
        raw = await _busy(context, compute(_decryptJob, (locked, passphrase)));
      } on BackupPassphraseException {
        if (context.mounted) _snack(context, l10n.myDataWrongPassphrase);
        return;
      } on FormatException {
        if (context.mounted) _snack(context, l10n.myDataInvalidFile);
        return;
      }
      if (!context.mounted) return;
    }
    final String file = raw;
    final UserDataBackup backup = _backup();
    final BackupSummary summary;
    try {
      summary = backup.inspect(file);
    } on BackupFormatException {
      _snack(context, l10n.myDataInvalidFile);
      return;
    }
    final MaterialLocalizations m = MaterialLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.myDataImportTitle),
        content: Text(
          l10n.myDataImportSummary(
            summary.exportedAt == null
                ? '—'
                : context.digits(m.formatShortDate(summary.exportedAt!)),
            context.digits(summary.savedVerses),
            context.digits(summary.notes),
            context.digits(summary.preferenceCount),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.appStringsMessage9),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.myDataImportConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await backup.restore(file);
    } catch (_) {
      if (context.mounted) _snack(context, l10n.myDataFailed);
      return;
    }
    await restart();
  }

  Future<void> _reset(BuildContext context) async {
    final l10n = l10nOf(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.myDataResetTitle),
        content: Text(l10n.myDataResetBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.appStringsMessage9),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.myDataResetConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _backup().erase();
    } catch (_) {
      if (context.mounted) _snack(context, l10n.myDataFailed);
      return;
    }
    await restart();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.upload_file_rounded),
          title: Text(l10n.myDataExport),
          subtitle: Text(l10n.myDataExportSubtitle),
          onTap: () => _export(context),
        ),
        ListTile(
          leading: const Icon(Icons.download_rounded),
          title: Text(l10n.myDataImport),
          subtitle: Text(l10n.myDataImportSubtitle),
          onTap: () => _import(context),
        ),
        ListTile(
          leading: Icon(
            Icons.delete_forever_outlined,
            color: Theme.of(context).colorScheme.error,
          ),
          title: Text(l10n.myDataReset),
          subtitle: Text(l10n.myDataResetSubtitle),
          onTap: () => _reset(context),
        ),
      ],
    );
  }
}

/// Asks for a passphrase: on export optional (with a repeat field), on
/// import to open a protected file. Pops the passphrase, "" for no
/// passphrase, or null when cancelled.
class _PassphraseDialog extends StatefulWidget {
  const _PassphraseDialog({required this.forExport});

  final bool forExport;

  @override
  State<_PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<_PassphraseDialog> {
  final _first = TextEditingController();
  final _second = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = l10nOf(context);
    final String value = _first.text;
    if (widget.forExport) {
      if (value.length < BackupCipher.minPassphraseLength) {
        setState(() => _error = l10n.myDataPassphraseTooShort);
        return;
      }
      if (value != _second.text) {
        setState(() => _error = l10n.myDataPassphraseMismatch);
        return;
      }
    } else if (value.isEmpty) {
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return AlertDialog(
      title: Text(
        widget.forExport ? l10n.myDataPassphraseTitle : l10n.myDataUnlockTitle,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.forExport) Text(l10n.myDataPassphraseHelp),
            TextField(
              key: const Key('passphrase'),
              controller: _first,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(labelText: l10n.myDataPassphrase),
              onSubmitted: widget.forExport ? null : (_) => _submit(),
            ),
            if (widget.forExport)
              TextField(
                key: const Key('passphrase-repeat'),
                controller: _second,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: l10n.myDataPassphraseRepeat,
                  errorText: _error,
                ),
                onSubmitted: (_) => _submit(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('passphrase-skip'),
          onPressed: () => Navigator.pop(context, widget.forExport ? '' : null),
          child: Text(
            widget.forExport
                ? l10n.myDataWithoutPassphrase
                : MaterialLocalizations.of(context).cancelButtonLabel,
          ),
        ),
        FilledButton(
          key: const Key('passphrase-ok'),
          onPressed: _submit,
          child: Text(
            widget.forExport ? l10n.myDataEncryptAndSave : l10n.myDataUnlock,
          ),
        ),
      ],
    );
  }
}

// Run in another isolate (top-level, so nothing from the screen is sent).
Future<String> _encryptJob((String, String, Argon2Cost) job) =>
    BackupCipher.encrypt(job.$1, job.$2, cost: job.$3);

Future<String> _decryptJob((String, String) job) =>
    BackupCipher.decrypt(job.$1, job.$2);
