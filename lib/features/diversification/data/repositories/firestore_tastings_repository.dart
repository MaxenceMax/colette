import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/firebase/firestore_paths.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/diversification/data/dtos/tasting_dto.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/domain/repositories/tastings_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Dégustations dans `households/{code}/tastings`.
class FirestoreTastingsRepository implements TastingsRepository {
  FirestoreTastingsRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _tastings(String code) => _db
      .collection(FirestorePaths.households)
      .doc(code)
      .collection(FirestorePaths.tastings);

  @override
  Stream<List<Tasting>> watchAll(String householdCode) =>
      _tastings(householdCode).snapshots().map((snap) {
        final tastings = [
          for (final doc in snap.docs) ?TastingDto.fromDoc(doc),
        ];
        // Tri en Dart plutôt qu'un `orderBy` Firestore : un document dont `at`
        // est invalide (donc écarté par `fromDoc`) ne doit pas empêcher le tri
        // des documents valides.
        tastings.sort((a, b) {
          final byAt = b.at.compareTo(a.at);
          return byAt != 0 ? byAt : a.id.compareTo(b.id);
        });
        return tastings;
      });

  @override
  Future<Either<Failure, void>> save(String householdCode, Tasting tasting) =>
      guard(
        () =>
            _tastings(householdCode)
                .doc(tasting.id)
                .set(TastingDto.toMap(tasting)),
      );

  @override
  Future<Either<Failure, void>> delete(
    String householdCode,
    String tastingId,
  ) => guard(() => _tastings(householdCode).doc(tastingId).delete());
}
