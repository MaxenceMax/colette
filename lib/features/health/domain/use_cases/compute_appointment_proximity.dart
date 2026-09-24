import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/health/domain/entities/appointment_proximity.dart';

/// Proximité d'un RDV en jours civils : 0 → `today`, 1 → `tomorrow`,
/// 2 à [soonDays] → `soon`, au-delà → `later`. Un écart négatif (ne devrait
/// pas arriver : un RDV passé a le statut `appointmentPassed`) vaut `today`.
class ComputeAppointmentProximity {
  const ComputeAppointmentProximity();

  static const soonDays = 7;

  AppointmentProximity call({
    required DateTime appointmentAt,
    required DateTime today,
  }) {
    final days = calendarDaysBetween(today.dateOnly, appointmentAt.dateOnly);
    return switch (days) {
      <= 0 => .today,
      1 => .tomorrow,
      <= soonDays => .soon,
      _ => .later,
    };
  }
}
