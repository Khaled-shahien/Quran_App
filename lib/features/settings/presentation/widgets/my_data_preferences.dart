import 'package:sakina_app/features/quran/data/repositories/hifz_repository.dart';
import 'package:sakina_app/features/practice_log/data/practice_log_repository.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
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
  });

  final BackupFiles files;
  final UserDataBackup? backup;
  final Future<void> Function() restart;

  UserDataBackup _backup() =>
      backup ??
      UserDataBackup(
        prefs: GetIt.instance<SharedPreferences>(),
        library: VerseLibraryRepository(GetIt.instance.getAsync<AppDatabase>),
        otherTables: [
          PracticeLogRepository(GetIt.instance.getAsync<AppDatabase>),
          HifzRepository(GetIt.instance.getAsync<AppDatabase>),
        ],
      );

  void _snack(BuildContext context, String text) => ScaffoldMessenger.maybeOf(
    context,
  )?.showSnackBar(SnackBar(content: Text(text)));

  Future<void> _export(BuildContext context) async {
    final l10n = l10nOf(context);
    try {
      final String json = await _backup().export();
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
    final String? raw;
    try {
      raw = await files.pick();
    } catch (_) {
      if (context.mounted) _snack(context, l10n.myDataFailed);
      return;
    }
    if (raw == null || !context.mounted) return;
    final UserDataBackup backup = _backup();
    final BackupSummary summary;
    try {
      summary = backup.inspect(raw);
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
      await backup.restore(raw);
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
