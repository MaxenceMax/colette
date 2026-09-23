import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/use_cases/compute_custom_appointment_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../health_factories.dart';

void main() {
  const compute = ComputeCustomAppointmentStatus();
  final now = DateTime(2026, 11, 10, 12);

  test('fait dès que doneAt est posé, même avec un RDV futur', () {
    expect(
      compute(
        appointment: makeAppointment(
          appointmentAt: DateTime(2026, 12, 1, 9),
          doneAt: DateTime(2026, 11, 9),
        ),
        now: now,
      ),
      MedicalStageStatus.done,
    );
  });

  test('programmé si le RDV est à venir (ou maintenant)', () {
    expect(
      compute(
        appointment: makeAppointment(appointmentAt: DateTime(2026, 12, 1, 9)),
        now: now,
      ),
      MedicalStageStatus.scheduled,
    );
    expect(
      compute(
        appointment: makeAppointment(appointmentAt: now),
        now: now,
      ),
      MedicalStageStatus.scheduled,
    );
  });

  test('RDV passé si la date est avant maintenant', () {
    expect(
      compute(
        appointment: makeAppointment(appointmentAt: DateTime(2026, 11, 3, 10)),
        now: now,
      ),
      MedicalStageStatus.appointmentPassed,
    );
  });
}
