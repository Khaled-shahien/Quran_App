import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/utils/external_links.dart';

void main() {
  test('accepts only web URLs with a host', () {
    expect(parseWebUrl(' https://example.com/a '), isNotNull);
    expect(parseWebUrl('http://example.com'), isNotNull);
    for (final url in [
      '',
      'not a url',
      'intent://scan/#Intent;scheme=x;end',
      'file:///data/local/secret',
      'tel:123',
      'javascript:alert(1)',
      'https://',
      'https:/missing-authority',
      'http://[bad',
    ]) {
      expect(parseWebUrl(url), isNull, reason: url);
    }
  });

  test('rejected URLs never reach the launcher', () async {
    var launched = false;
    final opened = await openWebUrl(
      'file:///etc/hosts',
      launcher: (_) async => launched = true,
    );
    expect(opened, isFalse);
    expect(launched, isFalse);
  });

  test('launch failures are reported as false', () async {
    final opened = await openWebUrl(
      'https://example.com',
      launcher: (_) async => throw PlatformException(code: 'no_activity'),
    );
    expect(opened, isFalse);
  });
}
