import 'package:colette/core/result/either_extensions.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/health/domain/entities/custom_appointment.dart';
import 'package:colette/features/health/domain/entities/custom_vaccine.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';
import 'package:colette/features/health/domain/use_cases/validate_custom_appointment.dart';
import 'package:flutter_test/flutter_test.dart';

import '../health_factories.dart';

void main() {
  const validate = ValidateCustomAppointment();
  final birth = DateTime(2026, 9, 1);
  final now = DateTime(2026, 11, 10, 12);

  ValidationReason? reasonOf(CustomAppointment a) =>
      validate(a, birthDate: birth, now: now).leftOrNull?.reason;

  test('accepte un RDV futur avec titre', () {
    expect(
      reasonOf(makeAppointment(appointmentAt: DateTime(2026, 12, 1, 9))),
      isNull,
    );
  });

  test('refuse un titre vide ou fait d\'espaces', () {
    expect(
      reasonOf(makeAppointment(title: '   ')),
      ValidationReason.medicalTitleRequired,
    );
  });

  test('nettoie les textes : trim, vides → null', () {
    final result = validate(
      makeAppointment(
        title: '  ORL ',
        practitioner: '  ',
        note: ' fièvre ',
        vaccines: [
          CustomVaccine(name: ' Grippe ', givenAt: DateTime(2026, 11, 3)),
        ],
      ),
      birthDate: birth,
      now: now,
    ).toNullable()!;
    expect(result.title, 'ORL');
    expect(result.practitioner, isNull);
    expect(result.note, 'fièvre');
    expect(result.vaccines.single.name, 'Grippe');
  });

  test('refuse un vaccin libre sans nom, ou avec code et nom', () {
    expect(
      reasonOf(
        makeAppointment(
          vaccines: [CustomVaccine(name: ' ', givenAt: DateTime(2026, 11, 3))],
        ),
      ),
      ValidationReason.medicalVaccineNameRequired,
    );
    expect(
      reasonOf(
        makeAppointment(
          vaccines: [
            CustomVaccine(
              code: VaccineCode.mmr,
              name: 'ROR',
              givenAt: DateTime(2026, 11, 3),
            ),
          ],
        ),
      ),
      ValidationReason.medicalVaccineNameRequired,
    );
  });

  test('refuse un RDV avant la naissance', () {
    expect(
      reasonOf(makeAppointment(appointmentAt: DateTime(2026, 8, 31, 10))),
      ValidationReason.medicalDateBeforeBirth,
    );
  });

  test('refuse visite ou injection dans le futur, tolère 5 min', () {
    expect(
      reasonOf(makeAppointment(doneAt: now.add(const Duration(minutes: 5)))),
      isNull,
    );
    expect(
      reasonOf(makeAppointment(doneAt: DateTime(2026, 11, 11))),
      ValidationReason.medicalDateInFuture,
    );
    expect(
      reasonOf(
        makeAppointment(
          vaccines: [
            CustomVaccine(
              code: VaccineCode.mmr,
              givenAt: DateTime(2026, 11, 11),
            ),
          ],
        ),
      ),
      ValidationReason.medicalDateInFuture,
    );
  });
}
