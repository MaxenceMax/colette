import 'package:colette/core/result/failure.dart';
import 'package:colette/l10n/generated/app_localizations.dart';

/// Texte affichable pour une [Failure].
String failureMessage(Object failure, S s) => switch (failure) {
  NetworkFailure() => s.errorNetwork,
  NotFoundFailure() => s.errorNotFound,
  ValidationFailure(:final reason) => switch (reason) {
    ValidationReason.emptyEvent => s.errorEmptyEvent,
    ValidationReason.endBeforeStart => s.errorEndBeforeStart,
    ValidationReason.startInFuture => s.errorStartInFuture,
    ValidationReason.bottleOutOfRange => s.errorBottleOutOfRange,
    ValidationReason.invalidWeight => s.errorInvalidWeight,
    ValidationReason.emptyName => s.errorEmptyName,
    ValidationReason.unknownHouseholdCode => s.errorUnknownCode,
  },
  _ => s.errorUnknown,
};
