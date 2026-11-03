// Fails when tracked or staged content contains a credential.
//
//   dart scripts/check_secrets.dart            scan all tracked files
//   dart scripts/check_secrets.dart --staged   scan the index, for pre-commit
//
// Only the file, line and rule are reported, so logs never repeat a value.
// Git history is not scanned.
import 'dart:convert';
import 'dart:io';

/// Firebase client configuration that is intentionally tracked. Its keys
/// identify the app rather than authorize it, and are limited by Google Cloud
/// restrictions. These exact files are exempt from the Google key rule only.
const Set<String> allowedGoogleKeyPaths = {
  'android/app/google-services.json',
  'lib/firebase_options.dart',
};

const String _exampleEnvFile = '.env.example';
const List<String> _generatedSuffixes = [
  '.g.dart',
  '.freezed.dart',
  '.mocks.dart',
];

final RegExp _googleApiKey = RegExp(r'AIza[0-9A-Za-z_\-]{35}');
final RegExp _privateKey = RegExp(r'-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----');
final RegExp _envAssignment = RegExp(
  r'''^\s*(?:export\s+)?[A-Za-z0-9_]*(?:API_?KEY|SECRET|TOKEN|PASSWORD)[A-Za-z0-9_]*\s*=\s*["']?[^\s"'#]''',
  caseSensitive: false,
);

/// Raised when git cannot supply the files, so a scan never passes by default.
class ScanFailure implements Exception {
  const ScanFailure(this.message);
  final String message;
}

String _baseName(String path) => path.split('/').last;

bool _isEnvFile(String path) {
  final name = _baseName(path);
  return name != _exampleEnvFile &&
      (name == '.env' ||
          name.startsWith('.env.') ||
          name.endsWith('.env') ||
          name.endsWith('.local'));
}

/// Returns a finding for each file that must never be in the repository.
List<String> findForbiddenPath(String path) {
  final name = _baseName(path).toLowerCase();
  if (name.endsWith('.jks') ||
      name.endsWith('.keystore') ||
      name == 'key.properties') {
    return ['$path (signing-file)'];
  }
  if (_isEnvFile(path)) return ['$path (env-file)'];
  return const [];
}

/// Returns `path:line (rule)` for each matching line of [content].
List<String> findSecrets(String path, String content) {
  final hits = <String>[];
  final checkGoogleKeys = !allowedGoogleKeyPaths.contains(path);
  final checkAssignments = _isEnvFile(path);
  final lines = const LineSplitter().convert(content);
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    void report(String rule) => hits.add('$path:${index + 1} ($rule)');
    if (checkGoogleKeys && _googleApiKey.hasMatch(line)) {
      report('google-api-key');
    }
    if (_privateKey.hasMatch(line)) report('private-key');
    if (checkAssignments && _envAssignment.hasMatch(line)) {
      report('env-assignment');
    }
  }
  return hits;
}

bool _isBinary(List<int> bytes) => bytes.take(8000).any((byte) => byte == 0);

/// Applies every rule to one file. The path rules also cover binary files.
List<String> scanFile(String path, List<int> bytes) {
  final hits = findForbiddenPath(path);
  if (_generatedSuffixes.any(path.endsWith) || _isBinary(bytes)) return hits;
  return [
    ...hits,
    ...findSecrets(path, utf8.decode(bytes, allowMalformed: true)),
  ];
}

List<int> _git(List<String> arguments, String? workingDirectory) {
  final ProcessResult result;
  try {
    result = Process.runSync(
      'git',
      arguments,
      workingDirectory: workingDirectory,
      stdoutEncoding: null,
    );
  } on ProcessException {
    throw const ScanFailure('git could not be started.');
  }
  if (result.exitCode != 0) {
    throw ScanFailure('git ${arguments.first} failed.');
  }
  return result.stdout as List<int>;
}

List<String> _paths(List<int> output) => utf8
    .decode(output, allowMalformed: true)
    .split('\u0000')
    .where((path) => path.isNotEmpty)
    .toList();

/// Scans the working copy of tracked files, or with [staged] the index, which
/// is what a commit would actually contain.
List<String> scanRepository({bool staged = false, String? workingDirectory}) {
  final hits = <String>[];
  if (staged) {
    final paths = _git([
      'diff',
      '--cached',
      '--name-only',
      '-z',
      '--diff-filter=ACMR',
    ], workingDirectory);
    for (final path in _paths(paths)) {
      hits.addAll(scanFile(path, _git(['show', ':$path'], workingDirectory)));
    }
    return hits;
  }
  for (final path in _paths(_git(['ls-files', '-z'], workingDirectory))) {
    final file = File(
      workingDirectory == null ? path : '$workingDirectory/$path',
    );
    // A deleted file still appears until the deletion is staged.
    hits.addAll(
      scanFile(path, file.existsSync() ? file.readAsBytesSync() : const []),
    );
  }
  return hits;
}

void main(List<String> arguments) {
  if (arguments.any((argument) => argument != '--staged')) {
    stderr.writeln('Usage: check_secrets.dart [--staged]');
    exit(2);
  }
  final staged = arguments.contains('--staged');
  final List<String> hits;
  try {
    hits = scanRepository(staged: staged);
  } on ScanFailure catch (failure) {
    stderr.writeln('Could not scan: ${failure.message}');
    exit(2);
  }
  if (hits.isNotEmpty) {
    stderr.writeln(
      'Credential findings in ${staged ? 'staged' : 'tracked'} files:',
    );
    hits.forEach(stderr.writeln);
    exit(1);
  }
  stdout.writeln(
    'No credentials found in ${staged ? 'staged' : 'tracked'} files.',
  );
}
