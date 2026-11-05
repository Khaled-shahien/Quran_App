import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:sakina_app/l10n/localization.dart';

/// Friendly Arabic copy for a [Failure]. Technical details stay in
/// [Failure.cause] and are never shown.
String failureMessage(Failure failure, [AppLocalizations? l10n]) {
  final strings = l10n ?? appL10n;
  return switch (failure) {
    NetworkFailure() => strings.mediaRepositoryImplMessage5,
    ServerFailure() || ContentFailure() => strings.mediaRepositoryImplMessage6,
    StorageFailure() ||
    PermissionFailure() ||
    UnexpectedFailure() => strings.appStringsMessage20,
  };
}
