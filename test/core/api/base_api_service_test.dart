import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sakina_app/core/api/base_api_service.dart';
import 'package:sakina_app/core/errors/network_exception.dart';

class _OnlineConnectivity implements Connectivity {
  @override
  Future<ConnectivityResult> checkConnectivity() async =>
      ConnectivityResult.wifi;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

BaseApiService _service(MockClientHandler handler) => BaseApiService(
  httpClient: MockClient(handler),
  connectivity: _OnlineConnectivity(),
  timeout: const Duration(milliseconds: 20),
);

void main() {
  test('a request that never answers fails with a timeout', () async {
    final never = Completer<http.Response>();
    await expectLater(
      _service((_) => never.future).get('https://example.com/a'),
      throwsA(
        isA<NetworkException>().having(
          (e) => e.type,
          'type',
          NetworkErrorType.timeout,
        ),
      ),
    );
  });

  test('a dropped connection is a network failure without its URL', () async {
    const secretQuery = 'latitude=12.34';
    await expectLater(
      _service(
        (request) => throw http.ClientException('closed', request.url),
      ).get('https://example.com/a?$secretQuery'),
      throwsA(
        isA<NetworkException>().having(
          (e) => e.toString(),
          'text',
          isNot(contains(secretQuery)),
        ),
      ),
    );
  });
}
