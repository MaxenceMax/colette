import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:fpdart/fpdart.dart';

/// Règles de validité d'une dent notée ; renvoie la dent avec sa note rognée.
///
/// Les dates sont comparées en jours civils : une date choisie au sélecteur est
/// enregistrée à midi, une tolérance en minutes refuserait la date du jour le matin.
class ValidateToothRecord {
  const ValidateToothRecord();

  Either<ValidationFailure, ToothRecord> call(
    ToothRecord record, {
    required DateTime birthDate,
    required DateTime now,
  }) {
    final erupted = record.eruptedAt;
    final lost = record.lostAt;
    if (lost != null && record.toothId.dentition == Dentition.permanent) {
      return left(
        const ValidationFailure(ValidationReason.toothLossOnPermanent),
      );
    }
    final days = [erupted, lost].nonNulls.map((date) => date.dateOnly);
    if (days.any((day) => day.isBefore(birthDate.dateOnly))) {
      return left(
        const ValidationFailure(ValidationReason.toothDateBeforeBirth),
      );
    }
    if (days.any((day) => day.isAfter(now.dateOnly))) {
      return left(const ValidationFailure(ValidationReason.toothDateInFuture));
    }
    if (erupted != null &&
        lost != null &&
        lost.dateOnly.isBefore(erupted.dateOnly)) {
      return left(
        const ValidationFailure(ValidationReason.toothLostBeforeErupted),
      );
    }
    final note = record.note?.trim();
    return right(
      record.copyWith(note: note == null || note.isEmpty ? null : note),
    );
  }
}
