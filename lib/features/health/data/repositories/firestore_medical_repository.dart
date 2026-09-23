import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/firebase/firestore_paths.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/health/data/dtos/medical_reminder_snapshot_dto.dart';
import 'package:colette/features/health/data/dtos/medical_visit_dto.dart';
import 'package:colette/features/health/domain/entities/medical_reminder_snapshot.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/repositories/medical_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Visites dans `households/{code}/medicalVisits`, snapshot dans `households/{code}.medicalReminder`.
class FirestoreMedicalRepository implements MedicalRepository {
  FirestoreMedicalRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _household(String code) =>
      _db.collection(FirestorePaths.households).doc(code);

  CollectionReference<Map<String, dynamic>> _visits(String code) =>
      _household(code).collection(FirestorePaths.medicalVisits);

  static List<MedicalVisit> _decode(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs.map(MedicalVisitDto.fromDoc).nonNulls.toList()
        ..sort((a, b) => a.stageId.index.compareTo(b.stageId.index));

  @override
  Stream<List<MedicalVisit>> watchVisits(String householdCode) =>
      _visits(householdCode).snapshots().map(_decode);

  @override
  Future<Either<Failure, List<MedicalVisit>>> fetchVisitsFromServer(
    String householdCode,
  ) => guard(
    () async => _decode(
      await _visits(householdCode).get(const GetOptions(source: Source.server)),
    ),
  );

  @override
  Future<Either<Failure, void>> saveVisit(
    String householdCode,
    MedicalVisit visit,
  ) => guard(
    () =>
        _visits(householdCode)
            .doc(visit.stageId.name)
            .set(MedicalVisitDto.toMap(visit)),
  );

  @override
  Future<Either<Failure, void>> deleteVisit(
    String householdCode,
    MedicalStageId stageId,
  ) => guard(() => _visits(householdCode).doc(stageId.name).delete());

  @override
  Future<Either<Failure, void>> saveReminderSnapshot(
    String householdCode,
    MedicalReminderSnapshot snapshot,
  ) => guard(
    () => _household(householdCode).set({
      'medicalReminder': MedicalReminderSnapshotDto.toMap(snapshot),
    }, SetOptions(merge: true)),
  );
}
