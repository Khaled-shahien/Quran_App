// Fails when a tracked file contains a credential-shaped value.
//
// Only the file, line and rule are reported, so CI logs never repeat a value.
import 'dart:convert';
import 'dart:io';

/// Firebase client configuration that is intentionally tracked. The values
/// identify the app rather than authorize it; restrict them in Google Cloud.
const Set<String> allowedGoogleKeyPaths = {
  'android/app/google-services.json',
  'lib/firebase_options.dart',
};

final Map<String, RegExp> secretRules = {
  'google-api-key': RegExp(r'AIza[0-9A-Za-z_-]{30,}'),
  'private-key': RegExp(r'-----BEGIN [A-Z ]*PRIVATE KEY-----'),
};

/// Returns `path:line (rule)` for each match outside the allowlist.
List<String> findSecrets(String path, String content) {
  final hits = <String>[];
  final lines = const LineSplitter().convert(content);
  for (var index = 0; index < lines.length; index++) {
    for (final rule in secretRules.entries) {
      if (rule.key == 'google-api-key' &&
          allowedGoogleKeyPaths.contains(path)) {
        continue;
      }
      if (rule.value.hasMatch(lines[index])) {
        hits.add('$path:${index + 1} (${rule.key})');
      }
    }
  }
  return hits;
}

void main() {
  final tracked = Process.runSync('git', ['ls-files', '-z']);
  if (tracked.exitCode != 0) {
    stderr.writeln('Could not list tracked files.');
    exit(2);
  }
  final hits = <String>[];
  for (final path in (tracked.stdout as String).split('\u0000')) {
    if (path.isEmpty) continue;
    final file = File(path);
    if (!file.existsSync()) continue;
    final content = utf8.decode(file.readAsBytesSync(), allowMalformed: true);
    hits.addAll(findSecrets(path, content));
  }
  if (hits.isNotEmpty) {
    stderr.writeln('Credential-shaped values found in tracked files:');
    hits.forEach(stderr.writeln);
    exit(1);
  }
  stdout.writeln('No credential-shaped values outside the allowlist.');
}
