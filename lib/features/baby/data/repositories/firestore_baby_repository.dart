import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/firebase/firestore_paths.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/baby/data/dtos/baby_profile_dto.dart';
import 'package:colette/features/baby/data/dtos/weight_entry_dto.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/feeding_plan_snapshot.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Profil dans `households/{code}.baby`, pesées dans `households/{code}/weights`.
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
  Stream<List<WeightEntry>> watchWeights(String householdCode) =>
      _weights(householdCode)
          .orderBy('measuredAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map(WeightEntryDto.fromDoc).toList());

  @override
  Future<Either<Failure, void>> addWeight(
    String householdCode,
    WeightEntry entry,
  ) => guard(
    () =>
        _weights(householdCode).doc(entry.id).set(WeightEntryDto.toMap(entry)),
  );

  @override
  Future<Either<Failure, void>> deleteWeight(
    String householdCode,
    String weightId,
  ) => guard(() => _weights(householdCode).doc(weightId).delete());

  @override
  Future<Either<Failure, void>> saveFeedingPlan(
    String householdCode,
    FeedingPlanSnapshot snapshot,
  ) => guard(
    () => _household(householdCode).set({
      'feedingPlan': {
        'nextBottleAt': Timestamp.fromDate(snapshot.nextBottleAt),
        'suggestedMl': snapshot.suggestedMl,
        'computedAt': Timestamp.fromDate(snapshot.computedAt),
      },
    }, SetOptions(merge: true)),
  );
}
