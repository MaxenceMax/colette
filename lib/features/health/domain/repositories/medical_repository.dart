import 'package:colette/core/result/failure.dart';
import 'package:colette/features/health/domain/entities/medical_reminder_snapshot.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:fpdart/fpdart.dart';

/// Visites médicales du foyer et snapshot des rappels.
abstract interface class MedicalRepository {
  /// Visites saisies, dans l'ordre du calendrier.
  Stream<List<MedicalVisit>> watchVisits(String householdCode);

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

  /// Écrit `medicalReminder` dans le document du foyer.
  Future<Either<Failure, void>> saveReminderSnapshot(
    String householdCode,
    MedicalReminderSnapshot snapshot,
  );
}
