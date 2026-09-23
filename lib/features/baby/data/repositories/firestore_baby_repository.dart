import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/firebase/firestore_paths.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/baby/data/dtos/baby_profile_dto.dart';
import 'package:colette/features/baby/data/dtos/growth_measurement_dto.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/feeding_plan_snapshot.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Profil dans `households/{code}.baby`, mesures de croissance dans `households/{code}/weights`.
class FirestoreBabyRepository implements BabyRepository {
  FirestoreBabyRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _household(String code) =>
      _db.collection(FirestorePaths.households).doc(code);

  CollectionReference<Map<String, dynamic>> _weights(String code) =>
      _household(code).collection(FirestorePaths.weights);

  @override
  Stream<BabyProfile?> watchProfile(String householdCode) =>
      _household(householdCode).snapshots().map((snap) {
        final baby = snap.data()?['baby'] as Map<String, dynamic>?;
        return baby == null ? null : BabyProfileDto.fromMap(baby);
      });

  @override
  Future<Either<Failure, void>> saveProfile(
    String householdCode,
    BabyProfile profile,
  ) => guard(
    () => _household(householdCode)
        .set({'baby': BabyProfileDto.toMap(profile)}, SetOptions(merge: true)),
  );

  @override
  Stream<List<GrowthMeasurement>> watchMeasurements(String householdCode) =>
      _weights(householdCode)
          .orderBy('measuredAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map(GrowthMeasurementDto.fromDoc).toList());

  @override
  Future<Either<Failure, void>> saveMeasurement(
    String householdCode,
    GrowthMeasurement measurement,
  ) => guard(
    // `set` sans merge : une valeur effacée disparaît du document.
    () =>
        _weights(householdCode)
            .doc(measurement.id)
            .set(GrowthMeasurementDto.toMap(measurement)),
  );

  @override
  Future<Either<Failure, void>> deleteMeasurement(
    String householdCode,
    String measurementId,
  ) => guard(() => _weights(householdCode).doc(measurementId).delete());

  @override
  Future<Either<Failure, void>> saveFeedingPlan(
    String householdCode,
    FeedingPlanSnapshot snapshot,
  ) => guard(
    () => _household(householdCode).set({
      'feedingPlan': {
        'nextBottleAt': Timestamp.fromDate(snapshot.nextBottleAt),
        'windowStartAt': Timestamp.fromDate(snapshot.windowStartAt),
        'windowEndAt': Timestamp.fromDate(snapshot.windowEndAt),
        'suggestedMl': snapshot.suggestedMl,
        'computedAt': Timestamp.fromDate(snapshot.computedAt),
      },
    }, SetOptions(merge: true)),
  );
}
