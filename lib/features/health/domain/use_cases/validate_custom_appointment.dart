import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/health/domain/entities/custom_appointment.dart';
import 'package:fpdart/fpdart.dart';

/// Règles de validité d'un RDV libre ; renvoie le RDV nettoyé (textes
/// `trim`és, vides → `null`).
class ValidateCustomAppointment {
  const ValidateCustomAppointment();

  static const futureTolerance = Duration(minutes: 5);

  Either<ValidationFailure, CustomAppointment> call(
    CustomAppointment appointment, {
    required DateTime birthDate,
    required DateTime now,
  }) {
    final title = appointment.title.trim();
    if (title.isEmpty) {
      return left(
        const ValidationFailure(ValidationReason.medicalTitleRequired),
      );
    }
    final vaccines = [
      for (final v in appointment.vaccines)
        v.copyWith(
          name: _clean(v.name),
          brand: _clean(v.brand),
          lot: _clean(v.lot),
        ),
    ];
    if (vaccines.any((v) => (v.code == null) == (v.name == null))) {
      return left(
        const ValidationFailure(ValidationReason.medicalVaccineNameRequired),
      );
    }
    final birthDay = birthDate.dateOnly;
    final latest = now.add(futureTolerance);
    final past = [
      appointment.doneAt,
      for (final v in vaccines) v.givenAt,
    ].nonNulls;
    final all = [appointment.appointmentAt, ...past];
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
    return right(
      appointment.copyWith(
        title: title,
        practitioner: _clean(appointment.practitioner),
        note: _clean(appointment.note),
        vaccines: vaccines,
      ),
    );
  }

  static String? _clean(String? text) {
    final trimmed = text?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
