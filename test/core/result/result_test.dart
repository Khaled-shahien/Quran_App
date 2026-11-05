import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/result/failure_messages.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/l10n/localization.dart';

void main() {
  group('Result', () {
    test('Success exposes its value and folds to onSuccess', () {
      const Result<int> result = Success(7);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, 7);
      expect(result.failureOrNull, isNull);
      expect(result.fold(onSuccess: (v) => v * 2, onFailure: (_) => -1), 14);
    });

    test('Err exposes its failure and folds to onFailure', () {
      const Result<int> result = Err(NetworkFailure());

      expect(result.isSuccess, isFalse);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, isA<NetworkFailure>());
      expect(result.fold(onSuccess: (v) => v, onFailure: (_) => -1), -1);
    });

    test('guard wraps a returned value', () async {
      final result = await Result.guard(
        () async => 'ok',
        onError: (e, _) => UnexpectedFailure(cause: e),
      );

      expect(result.valueOrNull, 'ok');
    });

    test('guard maps exceptions and errors instead of throwing', () async {
      final fromException = await Result.guard<int>(
        () async => throw const SocketException('offline'),
        onError: (e, _) => e is SocketException
            ? NetworkFailure(cause: e)
            : UnexpectedFailure(cause: e),
      );
      final fromError = await Result.guard<int>(
        () async => throw StateError('bad state'),
        onError: (e, _) => UnexpectedFailure(cause: e),
      );

      expect(fromException.failureOrNull, isA<NetworkFailure>());
      expect(fromError.failureOrNull, isA<UnexpectedFailure>());
      expect(fromError.failureOrNull!.cause, isA<StateError>());
    });
  });

  group('failureMessage', () {
    test('maps every failure kind to non-empty Arabic copy', () {
      const failures = <Failure>[
        ContentFailure(),
        NetworkFailure(),
        ServerFailure(statusCode: 500),
        StorageFailure(),
        PermissionFailure(),
        UnexpectedFailure(),
      ];

      for (final failure in failures) {
        final message = failureMessage(failure);
        expect(message, isNotEmpty, reason: '$failure');
        expect(
          RegExp('[؀-ۿ]').hasMatch(message),
          isTrue,
          reason: '$failure should be described in Arabic',
        );
      }
    });

    test('never leaks the technical cause', () {
      final message = failureMessage(
        NetworkFailure(cause: TimeoutException('socket 10.0.0.1 timed out')),
      );

      expect(message, appL10n.mediaRepositoryImplMessage5);
      expect(message, isNot(contains('10.0.0.1')));
    });
  });
}
