import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:fpdart/fpdart.dart';

/// Règles de validité d'une visite avant enregistrement.
class ValidateMedicalVisit {
  const ValidateMedicalVisit();

  static const futureTolerance = Duration(minutes: 5);

  Either<ValidationFailure, MedicalVisit> call(
    MedicalVisit visit, {
    required DateTime birthDate,
    required DateTime now,
  }) {
    final birthDay = birthDate.dateOnly;
    final latest = now.add(futureTolerance);
    final past = [
      visit.doneAt,
      for (final v in visit.vaccines.values) v.givenAt,
    ].nonNulls;
    final all = [visit.appointmentAt, ...past].nonNulls;
    if (all.any((date) => date.isBefore(birthDay))) {
      return left(
        const ValidationFailure(ValidationReason.medicalDateBeforeBirth),
      );
    }
    if (past.any((date) => date.isAfter(latest))) {
      return left(
        const ValidationFailure(ValidationReason.medicalDateInFuture),
      );
    }
    return right(visit);
  }
}
