import 'package:colette/features/health/domain/entities/appointment_proximity.dart';
import 'package:colette/features/health/domain/use_cases/compute_appointment_proximity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const compute = ComputeAppointmentProximity();
  final today = DateTime(2026, 10, 20, 8);

  AppointmentProximity at(DateTime appointmentAt) =>
      compute(appointmentAt: appointmentAt, today: today);

  test('le jour même, quelle que soit l\'heure : today', () {
    expect(at(DateTime(2026, 10, 20, 23, 30)), AppointmentProximity.today);
    expect(at(DateTime(2026, 10, 20, 7)), AppointmentProximity.today);
  });

  test('le lendemain : tomorrow', () {
    expect(at(DateTime(2026, 10, 21, 0, 5)), AppointmentProximity.tomorrow);
  });

  test('de 2 à 7 jours : soon', () {
    expect(at(DateTime(2026, 10, 22)), AppointmentProximity.soon);
    expect(at(DateTime(2026, 10, 27, 23, 59)), AppointmentProximity.soon);
  });

  test('8 jours et plus : later', () {
    expect(at(DateTime(2026, 10, 28)), AppointmentProximity.later);
    expect(at(DateTime(2027, 3, 1)), AppointmentProximity.later);
  });

  test('un écart négatif est traité comme today', () {
    expect(at(DateTime(2026, 10, 19)), AppointmentProximity.today);
  });
}
