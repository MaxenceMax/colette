import 'package:colette/features/health/domain/entities/custom_appointment.dart';
import 'package:colette/features/health/domain/entities/custom_vaccine.dart';
import 'package:colette/features/health/domain/entities/given_vaccine.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';

/// Visite de test, horodatée au 1er septembre 2026 par `device-a`.
MedicalVisit makeVisit(
  MedicalStageId stageId, {
  DateTime? appointmentAt,
  String? practitioner,
  DateTime? doneAt,
  String? note,
  Map<VaccineCode, GivenVaccine> vaccines = const {},
}) => MedicalVisit(
  stageId: stageId,
  appointmentAt: appointmentAt,
  practitioner: practitioner,
  doneAt: doneAt,
  note: note,
  vaccines: vaccines,
  updatedAt: DateTime(2026, 9, 1),
  updatedByDeviceId: 'device-a',
);

/// RDV libre de test, horodaté au 1er septembre 2026 par `device-a`.
CustomAppointment makeAppointment({
  String id = 'rdv-1',
  String title = 'Ostéopathe',
  DateTime? appointmentAt,
  String? practitioner,
  DateTime? doneAt,
  String? note,
  List<CustomVaccine> vaccines = const [],
}) => CustomAppointment(
  id: id,
  title: title,
  appointmentAt: appointmentAt ?? DateTime(2026, 11, 3, 10),
  practitioner: practitioner,
  doneAt: doneAt,
  note: note,
  vaccines: vaccines,
  updatedAt: DateTime(2026, 9, 1),
  updatedByDeviceId: 'device-a',
);
