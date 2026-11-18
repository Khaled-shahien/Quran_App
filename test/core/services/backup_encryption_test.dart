import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/database/app_database.dart';
import 'package:sakina_app/core/services/backup_encryption.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const Argon2Cost _fast = (memoryKiB: 64, iterations: 1, parallelism: 1);

void main() {
  test('round trip; the file reveals nothing of the export', () async {
    const plain = '{"format":"sakina-backup","notes":"secret note"}';
    final locked = await BackupCipher.encrypt(
      plain,
      'passphrase!',
      cost: _fast,
    );
    expect(locked, isNot(contains('secret note')));
    expect(locked, isNot(contains('"sakina-backup"')));
    expect(BackupCipher.isEncrypted(locked), isTrue);
    expect(BackupCipher.isEncrypted(plain), isFalse);
    expect(await BackupCipher.decrypt(locked, 'passphrase!'), plain);
  });

  test('a wrong passphrase or a changed byte is refused', () async {
    final locked = await BackupCipher.encrypt('x', 'passphrase!', cost: _fast);
    await expectLater(
      BackupCipher.decrypt(locked, 'passphrase?'),
      throwsA(isA<BackupPassphraseException>()),
    );
    final map = jsonDecode(locked) as Map<String, dynamic>;
    final data = base64Decode(map['data'] as String);
    data[0] ^= 1;
    map['data'] = base64Encode(data);
    await expectLater(
      BackupCipher.decrypt(jsonEncode(map), 'passphrase!'),
      throwsA(isA<BackupPassphraseException>()),
    );
  });

  test('two exports of the same data never look alike', () async {
    final a = await BackupCipher.encrypt('same', 'passphrase!', cost: _fast);
    final b = await BackupCipher.encrypt('same', 'passphrase!', cost: _fast);
    expect(a, isNot(b));
  });

  test('the default cost meets the OWASP Argon2id minimum', () {
    expect(BackupCipher.defaultCost.memoryKiB, greaterThanOrEqualTo(19456));
    expect(BackupCipher.defaultCost.iterations, greaterThanOrEqualTo(2));
  });

  test('log rows of earlier builds move to the private database', () async {
    sqfliteFfiInit();
    // Two files: in-memory databases would be one shared instance.
    final dir = Directory.systemTemp.createTempSync('sakina_db');
    addTearDown(() => dir.deleteSync(recursive: true));
    final main = await AppDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: '${dir.path}/main.db',
    );
    final private = await PrivateDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: '${dir.path}/private.db',
    );
    addTearDown(() async {
      await main.close();
      await private.close();
    });
    await main.db.insert('prayer_log', {
      'day': '2026-11-18',
      'prayer': 'fajr',
      'status': 'onTime',
      'updated_at': 1,
    });
    await private.db.insert('fasting_log', {
      'day': '2026-11-17',
      'status': 'fasted',
      'updated_at': 2,
    });
    await main.db.insert('fasting_log', {
      'day': '2026-11-17',
      'status': 'missed',
      'updated_at': 1,
    });
    await private.adoptLegacyLog(main);
    expect(await main.db.query('prayer_log'), isEmpty);
    expect(await main.db.query('fasting_log'), isEmpty);
    expect((await private.db.query('prayer_log')).single['status'], 'onTime');
    // Rows already in the private database win.
    expect((await private.db.query('fasting_log')).single['status'], 'fasted');
    await private.adoptLegacyLog(main);
    expect(await private.db.query('prayer_log'), hasLength(1));
  });
}
