/// Outcome of an operation that can fail without throwing.
///
/// Repositories return a [Result] so callers must handle the failure branch
/// explicitly; presentation code maps a [Failure] to a localized message.
sealed class Result<T> {
  const Result();

  /// Runs [action] and wraps its value, or maps any thrown error with [onError].
  static Future<Result<T>> guard<T>(
    Future<T> Function() action, {
    required Failure Function(Object error, StackTrace stackTrace) onError,
  }) async {
    try {
      return Success<T>(await action());
    } catch (error, stackTrace) {
      return Err<T>(onError(error, stackTrace));
    }
  }

  bool get isSuccess => this is Success<T>;

  /// The value on success, otherwise null.
  T? get valueOrNull => switch (this) {
    Success<T>(:final value) => value,
    Err<T>() => null,
  };

  /// The failure on error, otherwise null.
  Failure? get failureOrNull => switch (this) {
    Success<T>() => null,
    Err<T>(:final failure) => failure,
  };

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  }) => switch (this) {
    Success<T>(:final value) => onSuccess(value),
    Err<T>(:final failure) => onFailure(failure),
  };
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

/// Why an operation failed. Presentation maps each kind to Arabic copy; the
/// [cause] is kept for logging only and is never shown to the user.
sealed class Failure {
  const Failure({this.cause});
  final Object? cause;
}

/// Bundled content (Quran, adhkar, duas…) could not be read or parsed.
final class ContentFailure extends Failure {
  const ContentFailure({super.cause});
}

/// The device is offline or the server could not be reached in time.
final class NetworkFailure extends Failure {
  const NetworkFailure({super.cause});
}

/// The server answered with an error or a payload the app cannot use.
final class ServerFailure extends Failure {
  const ServerFailure({this.statusCode, super.cause});
  final int? statusCode;
}

/// Local persistence (preferences, files) failed.
final class StorageFailure extends Failure {
  const StorageFailure({super.cause});
}

/// A required device capability or permission is unavailable.
final class PermissionFailure extends Failure {
  const PermissionFailure({super.cause});
}

/// Anything not covered above.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure({super.cause});
}
