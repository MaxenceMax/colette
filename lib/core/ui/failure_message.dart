import 'package:colette/core/dates/time_format.dart';
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
    ValidationReason.notificationsDenied => s.errorNotificationsDenied,
    ValidationReason.invalidDiaperCount => s.errorInvalidDiaperCount,
    ValidationReason.sleepInFuture => s.errorSleepInFuture,
    ValidationReason.sleepTooLong => s.errorSleepTooLong,
    ValidationReason.sleepBeforeBirth => s.errorSleepBeforeBirth,
    ValidationReason.foodNameTooLong => s.errorFoodNameTooLong,
    ValidationReason.duplicateFoodName => s.errorDuplicateFoodName,
    ValidationReason.customFoodInUse => s.errorCustomFoodInUse,
    ValidationReason.emptyMeasurement => s.errorEmptyMeasurement,
    ValidationReason.invalidLength => s.errorInvalidLength,
    ValidationReason.invalidHeadCircumference =>
      s.errorInvalidHeadCircumference,
    ValidationReason.medicalDateBeforeBirth => s.errorMedicalDateBeforeBirth,
    ValidationReason.medicalDateInFuture => s.errorMedicalDateInFuture,
    ValidationReason.medicalTitleRequired => s.errorMedicalTitleRequired,
    ValidationReason.medicalVaccineNameRequired =>
      s.errorMedicalVaccineNameRequired,
  },
  SleepOverlapFailure(:final startAt, :final endAt) => switch (endAt) {
    null => s.errorSleepOverlapOngoing(formatHourMinute(startAt)),
    final end => s.errorSleepOverlap(
      formatHourMinute(startAt),
      formatHourMinute(end),
    ),
  },
  DocumentsFailure(:final reason) => switch (reason) {
    DocumentsReason.noFolder ||
    DocumentsReason.accessDenied => s.documentsErrorAccess,
    DocumentsReason.io => s.documentsErrorIo,
    // Jamais affiché : l'UI ignore cancelled.
    DocumentsReason.cancelled => s.errorUnknown,
  },
  CalendarFailure(:final reason) => switch (reason) {
    CalendarReason.accessDenied => s.calendarErrorAccessDenied,
    CalendarReason.calendarNotFound => s.calendarErrorNotFound,
    CalendarReason.io => s.calendarErrorIo,
  },
  _ => s.errorUnknown,
};
