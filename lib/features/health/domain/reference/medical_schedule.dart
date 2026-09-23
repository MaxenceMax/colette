// Examens : service-public.gouv.fr F35490 (vérifié le 29 juillet 2026) et ameli.fr
// « 20 examens de suivi médical de l'enfant et de l'adolescent » (11 août 2025).
// Vaccins : ameli.fr « Les vaccins obligatoires chez le nourrisson » (21 mai 2026),
// calendrier des vaccinations 2026. « À N mois » = fenêtre [N mois, N+1 mois).

import 'package:colette/features/health/domain/entities/age_offset.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';

/// Étapes de la naissance à 3 ans, dans l'ordre de [MedicalStageId].
const medicalSchedule = <MedicalStage>[
  MedicalStage(
    id: MedicalStageId.day8,
    from: AgeOffset.days(0),
    until: AgeOffset.days(8),
    hasCertificate: true,
  ),
  MedicalStage(
    id: MedicalStageId.week2,
    from: AgeOffset.days(8),
    until: AgeOffset.days(15),
  ),
  MedicalStage(
    id: MedicalStageId.m1,
    from: AgeOffset.months(1),
    until: AgeOffset.months(2),
  ),
  MedicalStage(
    id: MedicalStageId.m2,
    from: AgeOffset.months(2),
    until: AgeOffset.months(3),
    vaccines: [
      ScheduledVaccine(VaccineCode.hexavalent),
      ScheduledVaccine(VaccineCode.pneumococcal),
      ScheduledVaccine(VaccineCode.rotavirus, recommended: true),
    ],
  ),
  MedicalStage(
    id: MedicalStageId.m3,
    from: AgeOffset.months(3),
    until: AgeOffset.months(4),
    vaccines: [
      ScheduledVaccine(VaccineCode.menB),
      ScheduledVaccine(VaccineCode.rotavirus, recommended: true),
    ],
  ),
  MedicalStage(
    id: MedicalStageId.m4,
    from: AgeOffset.months(4),
    until: AgeOffset.months(5),
    vaccines: [
      ScheduledVaccine(VaccineCode.hexavalent),
      ScheduledVaccine(VaccineCode.pneumococcal),
      ScheduledVaccine(VaccineCode.rotavirus, recommended: true),
    ],
  ),
  MedicalStage(
    id: MedicalStageId.m5,
    from: AgeOffset.months(5),
    until: AgeOffset.months(6),
    vaccines: [ScheduledVaccine(VaccineCode.menB)],
  ),
  MedicalStage(
    id: MedicalStageId.m6,
    from: AgeOffset.months(6),
    until: AgeOffset.months(7),
    hasExam: false,
    vaccines: [ScheduledVaccine(VaccineCode.menACWY)],
  ),
  MedicalStage(
    id: MedicalStageId.m8,
    from: AgeOffset.months(8),
    until: AgeOffset.months(9),
    hasCertificate: true,
  ),
  MedicalStage(
    id: MedicalStageId.m11,
    from: AgeOffset.months(11),
    until: AgeOffset.months(12),
    vaccines: [
      ScheduledVaccine(VaccineCode.hexavalent),
      ScheduledVaccine(VaccineCode.pneumococcal),
    ],
  ),
  MedicalStage(
    id: MedicalStageId.m12,
    from: AgeOffset.months(12),
    until: AgeOffset.months(13),
    vaccines: [
      ScheduledVaccine(VaccineCode.mmr),
      ScheduledVaccine(VaccineCode.menACWY),
      ScheduledVaccine(VaccineCode.menB),
    ],
  ),
  MedicalStage(
    id: MedicalStageId.m16,
    from: AgeOffset.months(16),
    until: AgeOffset.months(19),
    vaccines: [ScheduledVaccine(VaccineCode.mmr)],
  ),
  MedicalStage(
    id: MedicalStageId.m23,
    from: AgeOffset.months(23),
    until: AgeOffset.months(25),
    hasCertificate: true,
  ),
  MedicalStage(
    id: MedicalStageId.y2,
    from: AgeOffset.months(25),
    until: AgeOffset.months(36),
  ),
  MedicalStage(
    id: MedicalStageId.y3,
    from: AgeOffset.months(36),
    until: AgeOffset.months(48),
  ),
];

/// Étape de [id].
MedicalStage stageById(MedicalStageId id) => medicalSchedule[id.index];
