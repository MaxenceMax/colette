import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/firebase/firestore_paths.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/household/domain/entities/household.dart';
import 'package:colette/features/household/domain/repositories/household_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Foyers stockés dans `households/{code}`.
class FirestoreHouseholdRepository implements HouseholdRepository {
  FirestoreHouseholdRepository(this._db, this._clock);

  final FirebaseFirestore _db;
  final AppClock _clock;

  DocumentReference<Map<String, dynamic>> _doc(String code) =>
      _db.collection(FirestorePaths.households).doc(code);

  @override
  Future<Either<Failure, Household>> create(String code) => guard(() async {
    final now = _clock.now();
    await _doc(code)
        .set({'createdAt': Timestamp.fromDate(now)}, SetOptions(merge: true));
    return Household(code: code, createdAt: now);
  });

  @override
  Future<Either<Failure, Household>> join(String code) async {
    final snapshot = await guard(() => _doc(code).get());
    return snapshot.flatMap<Household>((snap) {
      final data = snap.data();
      if (data == null) return left(const NotFoundFailure());
      return right(
        Household(
          code: code,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        ),
      );
    });
  }
}
