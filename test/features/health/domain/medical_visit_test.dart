import 'package:colette/features/health/domain/entities/given_vaccine.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';
import 'package:flutter_test/flutter_test.dart';

import '../health_factories.dart';

void main() {
  test('vide quand rien n\'est saisi', () {
    expect(makeVisit(MedicalStageId.m2).isEmpty, isTrue);
  });

  test('vide avec seulement un praticien', () {
    expect(
      makeVisit(MedicalStageId.m2, practitioner: 'Dr Martin').isEmpty,
      isTrue,
    );
  });

  test('vide avec une note faite uniquement d\'espaces', () {
    expect(makeVisit(MedicalStageId.m2, note: '   ').isEmpty, isTrue);
  });

  test('non vide avec un RDV', () {
    expect(
      makeVisit(
        MedicalStageId.m2,
        appointmentAt: DateTime(2026, 11, 3, 10),
      ).isEmpty,
      isFalse,
    );
  });

  test('non vide avec une visite faite', () {
    expect(
      makeVisit(MedicalStageId.m2, doneAt: DateTime(2026, 11, 3, 10)).isEmpty,
      isFalse,
    );
  });

  test('non vide avec un vaccin', () {
    expect(
      makeVisit(
        MedicalStageId.m2,
        vaccines: {
          VaccineCode.hexavalent: GivenVaccine(
            givenAt: DateTime(2026, 11, 3, 10),
          ),
        },
      ).isEmpty,
      isFalse,
    );
  });

  test('non vide avec une note', () {
    expect(makeVisit(MedicalStageId.m2, note: 'RAS').isEmpty, isFalse);
  });
}
