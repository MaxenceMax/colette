import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';
import 'package:colette/features/health/domain/reference/medical_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final birth = DateTime(2026, 9, 1);

  test('une étape par identifiant, dans l\'ordre de l\'enum', () {
    expect(medicalSchedule.map((s) => s.id), MedicalStageId.values);
  });

  test('fenêtres non vides et débuts croissants', () {
    for (final stage in medicalSchedule) {
      expect(
        stage.until.from(birth).isAfter(stage.from.from(birth)),
        isTrue,
        reason: stage.id.name,
      );
    }
    for (var i = 1; i < medicalSchedule.length; i++) {
      expect(
        medicalSchedule[i].from
            .from(birth)
            .isBefore(medicalSchedule[i - 1].from.from(birth)),
        isFalse,
        reason: medicalSchedule[i].id.name,
      );
    }
  });

  List<MedicalStageId> mandatory(VaccineCode code) => [
    for (final stage in medicalSchedule)
      if (stage.vaccines.any((v) => v.code == code && !v.recommended)) stage.id,
  ];

  test('vaccins obligatoires aux âges du calendrier 2026', () {
    expect(mandatory(VaccineCode.hexavalent), [
      MedicalStageId.m2,
      MedicalStageId.m4,
      MedicalStageId.m11,
    ]);
    expect(mandatory(VaccineCode.pneumococcal), [
      MedicalStageId.m2,
      MedicalStageId.m4,
      MedicalStageId.m11,
    ]);
    expect(mandatory(VaccineCode.menB), [
      MedicalStageId.m3,
      MedicalStageId.m5,
      MedicalStageId.m12,
    ]);
    expect(mandatory(VaccineCode.menACWY), [
      MedicalStageId.m6,
      MedicalStageId.m12,
    ]);
    expect(mandatory(VaccineCode.mmr), [
      MedicalStageId.m12,
      MedicalStageId.m16,
    ]);
    expect(mandatory(VaccineCode.rotavirus), isEmpty);
  });

  test('rotavirus recommandé à 2, 3 et 4 mois', () {
    expect(
      [
        for (final stage in medicalSchedule)
          if (stage.vaccines.any(
            (v) => v.code == VaccineCode.rotavirus && v.recommended,
          ))
            stage.id,
      ],
      [MedicalStageId.m2, MedicalStageId.m3, MedicalStageId.m4],
    );
  });

  test('certificats à 8 jours, 8 mois et 23-24 mois ; 6 mois sans examen', () {
    expect(
      [
        for (final stage in medicalSchedule)
          if (stage.hasCertificate) stage.id,
      ],
      [MedicalStageId.day8, MedicalStageId.m8, MedicalStageId.m23],
    );
    expect(stageById(MedicalStageId.m6).hasExam, isFalse);
    expect(stageById(MedicalStageId.m11).hasExam, isTrue);
  });

  test('fenêtres de quelques étapes', () {
    final m2 = stageById(MedicalStageId.m2);
    expect(m2.from.from(birth), DateTime(2026, 11, 1));
    expect(m2.until.from(birth), DateTime(2026, 12, 1));
    final day8 = stageById(MedicalStageId.day8);
    expect(day8.from.from(birth), birth);
    expect(day8.until.from(birth), DateTime(2026, 9, 9));
  });
}
