import 'package:colette/core/result/failure.dart';
import 'package:colette/features/health/domain/entities/custom_appointment.dart';
import 'package:colette/features/health/domain/entities/medical_reminder_snapshot.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:fpdart/fpdart.dart';

/// Visites médicales, RDV libres du foyer et snapshot des rappels.
abstract interface class MedicalRepository {
  /// Visites saisies, dans l'ordre du calendrier.
  Stream<List<MedicalVisit>> watchVisits(String householdCode);

  /// Visites lues sur le serveur, jamais dans le cache local ; échoue hors ligne.
  Future<Either<Failure, List<MedicalVisit>>> fetchVisitsFromServer(
    String householdCode,
  );

  /// Remplace entièrement la visite de son étape.
  Future<Either<Failure, void>> saveVisit(
    String householdCode,
    MedicalVisit visit,
  );

  /// Supprime la visite d'une étape.
  Future<Either<Failure, void>> deleteVisit(
    String householdCode,
    MedicalStageId stageId,
  );

  /// RDV libres, triés par date puis identifiant.
  Stream<List<CustomAppointment>> watchAppointments(String householdCode);

  /// RDV libres lus sur le serveur, jamais dans le cache local ; échoue hors ligne.
  Future<Either<Failure, List<CustomAppointment>>> fetchAppointmentsFromServer(
    String householdCode,
  );

  /// Remplace entièrement le RDV libre.
  Future<Either<Failure, void>> saveAppointment(
    String householdCode,
    CustomAppointment appointment,
  );

  /// Supprime un RDV libre.
  Future<Either<Failure, void>> deleteAppointment(
    String householdCode,
    String appointmentId,
  );

  /// Écrit `medicalReminder` dans le document du foyer.
  Future<Either<Failure, void>> saveReminderSnapshot(
    String householdCode,
    MedicalReminderSnapshot snapshot,
  );
}
