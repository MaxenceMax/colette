import 'package:colette/features/health/domain/entities/age_offset.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';

/// Identifiant stable d'une étape ; `name` sert d'identifiant Firestore.
enum MedicalStageId {
  day8,
  week2,
  m1,
  m2,
  m3,
  m4,
  m5,
  m6,
  m8,
  m11,
  m12,
  m16,
  m23,
  y2,
  y3,
}

/// Vaccin attendu à une étape ; [recommended] : recommandé, non obligatoire.
final class ScheduledVaccine {
  const ScheduledVaccine(this.code, {this.recommended = false});

  final VaccineCode code;
  final bool recommended;
}

/// Étape du calendrier : visite attendue entre les âges [from] (inclus) et
/// [until] (exclu).
final class MedicalStage {
  const MedicalStage({
    required this.id,
    required this.from,
    required this.until,
    this.hasExam = true,
    this.hasCertificate = false,
    this.vaccines = const [],
  });

  final MedicalStageId id;
  final AgeOffset from;
  final AgeOffset until;
  final bool hasExam;
  final bool hasCertificate;
  final List<ScheduledVaccine> vaccines;

  bool get hasVaccines => vaccines.isNotEmpty;
}
