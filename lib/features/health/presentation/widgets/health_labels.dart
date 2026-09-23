import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';
import 'package:colette/l10n/generated/app_localizations.dart';

/// Libellés des étapes et des vaccins.
abstract final class HealthLabels {
  static String stage(S s, MedicalStageId id) => switch (id) {
    MedicalStageId.day8 => s.healthStageDay8,
    MedicalStageId.week2 => s.healthStageWeek2,
    MedicalStageId.m1 => s.healthStageM1,
    MedicalStageId.m2 => s.healthStageM2,
    MedicalStageId.m3 => s.healthStageM3,
    MedicalStageId.m4 => s.healthStageM4,
    MedicalStageId.m5 => s.healthStageM5,
    MedicalStageId.m6 => s.healthStageM6,
    MedicalStageId.m8 => s.healthStageM8,
    MedicalStageId.m11 => s.healthStageM11,
    MedicalStageId.m12 => s.healthStageM12,
    MedicalStageId.m16 => s.healthStageM16,
    MedicalStageId.m23 => s.healthStageM23,
    MedicalStageId.y2 => s.healthStageY2,
    MedicalStageId.y3 => s.healthStageY3,
  };

  /// Titre de l'événement de calendrier : « Examen et vaccins des 2 mois · Colette ».
  static String eventTitle(S s, MedicalStageId id, String babyName) =>
      s.healthEventTitle(stage(s, id), babyName);

  static String vaccine(S s, VaccineCode code) => switch (code) {
    VaccineCode.hexavalent => s.vaccineHexavalent,
    VaccineCode.pneumococcal => s.vaccinePneumococcal,
    VaccineCode.menB => s.vaccineMenB,
    VaccineCode.menACWY => s.vaccineMenACWY,
    VaccineCode.mmr => s.vaccineMmr,
    VaccineCode.rotavirus => s.vaccineRotavirus,
  };
}
