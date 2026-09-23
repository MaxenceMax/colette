import 'package:colette/features/health/domain/entities/given_vaccine.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'medical_visit.freezed.dart';

/// Ce que les parents ont saisi pour une étape : RDV, injections, visite faite.
@freezed
abstract class MedicalVisit with _$MedicalVisit {
  const MedicalVisit._();

  const factory MedicalVisit({
    required MedicalStageId stageId,
    DateTime? appointmentAt,
    String? practitioner,
    DateTime? doneAt,
    String? note,
    @Default(<VaccineCode, GivenVaccine>{})
    Map<VaccineCode, GivenVaccine> vaccines,
    required DateTime updatedAt,
    required String updatedByDeviceId,
  }) = _MedicalVisit;

  /// Rien de saisi : ni RDV, ni visite faite, ni injection, ni note.
  /// Le praticien seul ne compte pas : il n'a de sens qu'avec un RDV.
  bool get isEmpty =>
      appointmentAt == null &&
      doneAt == null &&
      vaccines.isEmpty &&
      (note?.trim().isEmpty ?? true);
}
