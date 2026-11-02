import 'package:flutter_test/flutter_test.dart';

import '../../scripts/check_secrets.dart';

void main() {
  // Built at runtime so this test file does not itself match the scanner.
  final fakeKey = 'AIza${'x' * 35}';

  test('reports the location without repeating the value', () {
    final hits = findSecrets('docs/plan.md', 'intro\nkey=$fakeKey\n');
    expect(hits, ['docs/plan.md:2 (google-api-key)']);
    expect(hits.join(), isNot(contains(fakeKey)));
  });

  test('allows tracked Firebase client configuration only', () {
    expect(findSecrets('lib/firebase_options.dart', fakeKey), isEmpty);
    expect(findSecrets('lib/other.dart', fakeKey), hasLength(1));
  });

  test('detects private keys even in allowlisted files', () {
    const header = '-----BEGIN PRIVATE KEY-----';
    expect(findSecrets('lib/firebase_options.dart', header), [
      'lib/firebase_options.dart:1 (private-key)',
    ]);
  });
}
