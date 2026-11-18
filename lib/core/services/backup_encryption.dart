import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// The passphrase did not open the file (wrong, or the file was changed).
class BackupPassphraseException implements Exception {
  const BackupPassphraseException();
}

/// Cost of turning a passphrase into a key; stored in each file so it can
/// be raised later without breaking older files.
typedef Argon2Cost = ({int memoryKiB, int iterations, int parallelism});

/// Wraps an export in a passphrase-protected envelope so the file can sit
/// in any cloud drive: Argon2id derives a 256-bit key from the passphrase
/// and a random salt, and AES-256-GCM encrypts and authenticates the data.
/// Nothing about the passphrase is stored.
abstract final class BackupCipher {
  static const String format = 'sakina-backup-encrypted';
  static const int version = 1;

  /// OWASP's minimum for Argon2id (19 MiB, 2 passes).
  static const Argon2Cost defaultCost = (
    memoryKiB: 19456,
    iterations: 2,
    parallelism: 1,
  );

  static const int minPassphraseLength = 8;

  static final AesGcm _aes = AesGcm.with256bits();

  static bool isEncrypted(String raw) {
    try {
      final Object? decoded = jsonDecode(raw);
      return decoded is Map && decoded['format'] == format;
    } on FormatException {
      return false;
    }
  }

  static Future<SecretKey> _key(
    String passphrase,
    List<int> salt,
    Argon2Cost cost,
  ) => Argon2id(
    parallelism: cost.parallelism,
    memory: cost.memoryKiB,
    iterations: cost.iterations,
    hashLength: 32,
  ).deriveKeyFromPassword(password: passphrase, nonce: salt);

  static List<int> _random(int length) {
    final Random r = Random.secure();
    return List<int>.generate(length, (_) => r.nextInt(256));
  }

  static Future<String> encrypt(
    String plain,
    String passphrase, {
    Argon2Cost cost = defaultCost,
  }) async {
    final List<int> salt = _random(16);
    final SecretKey key = await _key(passphrase, salt, cost);
    final SecretBox box = await _aes.encrypt(
      utf8.encode(plain),
      secretKey: key,
      nonce: _aes.newNonce(),
    );
    return jsonEncode({
      'format': format,
      'version': version,
      'kdf': {
        'name': 'argon2id',
        'memoryKiB': cost.memoryKiB,
        'iterations': cost.iterations,
        'parallelism': cost.parallelism,
        'salt': base64Encode(salt),
      },
      'cipher': {'name': 'aes-256-gcm', 'nonce': base64Encode(box.nonce)},
      'data': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    });
  }

  /// The original export. Throws [BackupPassphraseException] for a wrong
  /// passphrase and [FormatException] for a file that is not one of ours.
  static Future<String> decrypt(String raw, String passphrase) async {
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map || decoded['format'] != format) {
      throw const FormatException('Not an encrypted backup');
    }
    try {
      final kdf = decoded['kdf'] as Map;
      final cipher = decoded['cipher'] as Map;
      if (decoded['version'] != version ||
          kdf['name'] != 'argon2id' ||
          cipher['name'] != 'aes-256-gcm') {
        throw const FormatException('Unsupported encrypted backup');
      }
      final cost = (
        memoryKiB: kdf['memoryKiB'] as int,
        iterations: kdf['iterations'] as int,
        parallelism: kdf['parallelism'] as int,
      );
      if (cost.memoryKiB < 8 ||
          cost.memoryKiB > 1 << 20 ||
          cost.iterations < 1 ||
          cost.iterations > 10 ||
          cost.parallelism < 1 ||
          cost.parallelism > 8) {
        throw const FormatException('Unreasonable key cost');
      }
      final SecretKey key = await _key(
        passphrase,
        base64Decode(kdf['salt'] as String),
        cost,
      );
      final List<int> plain = await _aes.decrypt(
        SecretBox(
          base64Decode(decoded['data'] as String),
          nonce: base64Decode(cipher['nonce'] as String),
          mac: Mac(base64Decode(decoded['mac'] as String)),
        ),
        secretKey: key,
      );
      return utf8.decode(plain);
    } on SecretBoxAuthenticationError {
      throw const BackupPassphraseException();
    } on TypeError {
      throw const FormatException('Damaged encrypted backup');
    }
  }
}
