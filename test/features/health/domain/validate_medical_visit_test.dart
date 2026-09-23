import 'package:colette/core/result/either_extensions.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/health/domain/entities/given_vaccine.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';
import 'package:colette/features/health/domain/use_cases/validate_medical_visit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../health_factories.dart';

void main() {
  const validate = ValidateMedicalVisit();
  final birth = DateTime(2026, 9, 1);
  final now = DateTime(2026, 11, 10, 12);

  ValidationReason? reasonOf(MedicalVisit visit) =>
      validate(visit, birthDate: birth, now: now).leftOrNull?.reason;

  test('accepte un RDV futur', () {
    expect(
      reasonOf(
        makeVisit(MedicalStageId.m2, appointmentAt: DateTime(2026, 12, 1, 9)),
      ),
      isNull,
    );
  });

  test('refuse un RDV avant la naissance', () {
    expect(
      reasonOf(
        makeVisit(MedicalStageId.day8, appointmentAt: DateTime(2026, 8, 31)),
      ),
      ValidationReason.medicalDateBeforeBirth,
    );
  });

  test('refuse une visite faite dans le futur, tolère 5 min', () {
    expect(
      reasonOf(
        makeVisit(
          MedicalStageId.m2,
          doneAt: now.add(const Duration(minutes: 5)),
        ),
      ),
      isNull,
    );
    expect(
      reasonOf(makeVisit(MedicalStageId.m2, doneAt: DateTime(2026, 11, 11))),
      ValidationReason.medicalDateInFuture,
    );
  });

  test('refuse une injection datée dans le futur ou avant la naissance', () {
    expect(
      reasonOf(
        makeVisit(
          MedicalStageId.m2,
          vaccines: {
            VaccineCode.hexavalent: GivenVaccine(
              givenAt: DateTime(2026, 11, 12),
            ),
          },
        ),
      ),
      ValidationReason.medicalDateInFuture,
    );
    expect(
      reasonOf(
        makeVisit(
          MedicalStageId.m2,
          vaccines: {
            VaccineCode.hexavalent: GivenVaccine(givenAt: DateTime(2026, 8, 1)),
          },
        ),
      ),
      ValidationReason.medicalDateBeforeBirth,
    );
  });
}
