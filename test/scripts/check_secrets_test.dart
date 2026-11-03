import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/check_secrets.dart';

void main() {
  // Built at runtime so this test file does not itself match the scanner.
  final fakeKey =
      'AI'
      'za${'x' * 35}';
  const privateKeyHeader =
      '-----BEGIN '
      'PRIVATE KEY-----';
  final rsaKeyHeader = privateKeyHeader.replaceFirst('PRIVATE', 'RSA PRIVATE');

  group('Google API keys', () {
    test('reports the location without repeating the value', () {
      final hits = findSecrets('docs/plan.md', 'intro\nkey=$fakeKey\n');
      expect(hits, ['docs/plan.md:2 (google-api-key)']);
      expect(hits.join(), isNot(contains(fakeKey)));
    });

    test('ignores values too short to be a key', () {
      expect(findSecrets('a.md', fakeKey.substring(0, 38)), isEmpty);
    });

    test('allows only the exact Firebase client configuration files', () {
      for (final path in allowedGoogleKeyPaths) {
        expect(findSecrets(path, fakeKey), isEmpty, reason: path);
      }
      for (final path in [
        'lib/other.dart',
        'copy/lib/firebase_options.dart',
        'google-services.json',
      ]) {
        expect(findSecrets(path, fakeKey), hasLength(1), reason: path);
      }
    });

    test('is detected in the env example file', () {
      expect(findSecrets('.env.example', 'YOUTUBE_API_KEY=$fakeKey'), [
        '.env.example:1 (google-api-key)',
      ]);
    });
  });

  group('private keys', () {
    test('are detected even in allowlisted files', () {
      expect(findSecrets('lib/firebase_options.dart', privateKeyHeader), [
        'lib/firebase_options.dart:1 (private-key)',
      ]);
    });

    test('are detected with an algorithm name', () {
      expect(findSecrets('notes.txt', rsaKeyHeader), [
        'notes.txt:1 (private-key)',
      ]);
    });
  });

  group('forbidden files', () {
    test('signing files are reported by path, even when binary', () {
      for (final path in [
        'android/app/upload.jks',
        'release.KEYSTORE',
        'android/key.properties',
      ]) {
        expect(scanFile(path, const [0, 1, 2]), [
          '$path (signing-file)',
        ], reason: path);
      }
    });

    test('env files are reported, except the example', () {
      for (final path in ['.env', '.env.prod', 'config/app.env', 'a.local']) {
        expect(findForbiddenPath(path), ['$path (env-file)'], reason: path);
      }
      expect(findForbiddenPath('.env.example'), isEmpty);
      expect(findForbiddenPath('docs/env.md'), isEmpty);
    });
  });

  group('env assignments', () {
    test('a non-empty secret assignment is reported without its value', () {
      const value = 'not-a-real-value';
      for (final line in [
        'YOUTUBE_API_KEY=$value',
        'export MY_APIKEY="$value"',
        'SERVICE_TOKEN = $value',
        'DB_PASSWORD=$value',
      ]) {
        final hits = findSecrets('.env.local', line);
        expect(hits, ['.env.local:1 (env-assignment)'], reason: line);
        expect(hits.join(), isNot(contains(value)));
      }
    });

    test('empty values, comments and other names pass', () {
      for (final line in [
        'YOUTUBE_API_KEY=',
        'YOUTUBE_API_KEY=""',
        'YOUTUBE_API_KEY= # paste here',
        '# YOUTUBE_API_KEY=value',
        'APP_ENV=production',
      ]) {
        expect(findSecrets('.env.local', line), isEmpty, reason: line);
      }
    });

    test('applies only to env-style files other than the example', () {
      const line = 'YOUTUBE_API_KEY=value';
      expect(findSecrets('.env.example', line), isEmpty);
      expect(findSecrets('README.md', line), isEmpty);
    });
  });

  group('skipped content', () {
    test('binary and generated files are not read as text', () {
      final bytes = [0, ...utf8.encode(fakeKey)];
      expect(scanFile('assets/image.png', bytes), isEmpty);
      expect(scanFile('lib/model.g.dart', utf8.encode(fakeKey)), isEmpty);
    });

    test('other tracked text is scanned wherever it lives', () {
      for (final path in [
        'docs/plan.md',
        'scripts/run.sh',
        'android/app/build.gradle.kts',
        'ios/Runner/Info.plist',
        'test/a_test.dart',
        'integration_test/a_test.dart',
      ]) {
        expect(scanFile(path, utf8.encode(fakeKey)), [
          '$path:1 (google-api-key)',
        ], reason: path);
      }
    });
  });

  group('repository scan', () {
    late Directory repository;

    void git(List<String> arguments) {
      final result = Process.runSync(
        'git',
        arguments,
        workingDirectory: repository.path,
      );
      expect(result.exitCode, 0, reason: 'git ${arguments.first}');
    }

    void write(String path, String content) =>
        File('${repository.path}/$path').writeAsStringSync(content);

    setUp(() {
      repository = Directory.systemTemp.createTempSync('check_secrets_');
      git(['init', '--quiet']);
    });

    tearDown(() => repository.deleteSync(recursive: true));

    List<String> scan({required bool staged}) =>
        scanRepository(staged: staged, workingDirectory: repository.path);

    test('staged mode reads the index, not the working copy', () {
      write('notes.md', 'key=$fakeKey');
      git(['add', 'notes.md']);
      write('notes.md', 'clean');

      expect(scan(staged: true), ['notes.md:1 (google-api-key)']);
      expect(scan(staged: false), isEmpty);
    });

    test('staged mode ignores a credential that was not staged', () {
      write('notes.md', 'clean');
      git(['add', 'notes.md']);
      write('notes.md', 'key=$fakeKey');
      write('untracked.md', 'key=$fakeKey');

      expect(scan(staged: true), isEmpty);
      expect(scan(staged: false), ['notes.md:1 (google-api-key)']);
    });

    test('staged mode reports forbidden files', () {
      write('key.properties', 'storePassword=x');
      git(['add', 'key.properties']);

      expect(scan(staged: true), ['key.properties (signing-file)']);
    });

    test('a failed git command is an error, not a clean scan', () {
      final outside = Directory.systemTemp.createTempSync('no_repo_');
      addTearDown(() => outside.deleteSync(recursive: true));

      expect(
        () => scanRepository(workingDirectory: '${outside.path}/missing'),
        throwsA(isA<ScanFailure>()),
      );
    });
  });

  test('the versioned hook runs the staged scan with LF line endings', () {
    final hook = File('.githooks/pre-commit').readAsBytesSync();
    expect(hook, isNot(contains(13)));
    expect(
      utf8.decode(hook),
      contains('dart scripts/check_secrets.dart --staged'),
    );
  });
}
