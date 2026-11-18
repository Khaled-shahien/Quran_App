import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/database/app_database.dart';
import 'package:sakina_app/core/services/user_data_backup.dart';
import 'package:sakina_app/features/quran/data/repositories/verse_library_repository.dart';
import 'package:sakina_app/features/settings/presentation/widgets/my_data_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _Files implements BackupFiles {
  String? picked;
  String? savedName;
  Uint8List? savedBytes;

  @override
  Future<bool> save(String fileName, Uint8List bytes) async {
    savedName = fileName;
    savedBytes = bytes;
    return true;
  }

  @override
  Future<String?> pick() async => picked;
}

void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late SharedPreferences prefs;
  late UserDataBackup backup;
  late _Files files;
  late int restarts;

  setUp(() async {
    database = await AppDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    prefs = await SharedPreferences.getInstance();
    backup = UserDataBackup(
      prefs: prefs,
      library: VerseLibraryRepository(() async => database),
    );
    files = _Files();
    restarts = 0;
  });
  tearDown(() => database.close());

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MyDataPreferences(
          files: files,
          backup: backup,
          restart: () async => restarts++,
        ),
      ),
    ),
  );

  testWidgets('export saves a backup file', (tester) async {
    await pump(tester);
    await tester.runAsync(() async {
      await tester.tap(find.text('حفظ نسخة من بياناتي'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(files.savedName, startsWith('sakina-backup-'));
    final decoded = jsonDecode(utf8.decode(files.savedBytes!)) as Map;
    expect((decoded['preferences'] as Map)['theme_mode'], 'dark');
  });

  testWidgets('a foreign file is refused without changes', (tester) async {
    files.picked = '{"format":"other"}';
    await pump(tester);
    await tester.tap(find.text('استعادة بياناتي من ملف'));
    await tester.pumpAndSettle();
    expect(
      find.text('هذا الملف ليس نسخة من بيانات سكينة، أو أنه من إصدار أحدث.'),
      findsOneWidget,
    );
    expect(restarts, 0);
  });

  testWidgets('a backup is restored after confirmation', (tester) async {
    files.picked = jsonEncode({
      'format': 'sakina-backup',
      'version': 1,
      'preferences': {'theme_mode': 'light'},
      'database': {},
    });
    await pump(tester);
    await tester.tap(find.text('استعادة بياناتي من ملف'));
    await tester.pumpAndSettle();
    expect(find.text('استعادة هذه النسخة؟'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('استعادة'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(prefs.getString('theme_mode'), 'light');
    expect(restarts, 1);
  });

  testWidgets('erase asks first, then clears and restarts', (tester) async {
    await pump(tester);
    await tester.tap(find.text('مسح كل بياناتي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(prefs.getString('theme_mode'), 'dark');

    await tester.tap(find.text('مسح كل بياناتي'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('مسح البيانات'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(prefs.containsKey('theme_mode'), isFalse);
    expect(restarts, 1);
  });
}
