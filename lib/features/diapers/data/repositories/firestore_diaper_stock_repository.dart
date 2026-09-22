import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/firebase/firestore_paths.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/diapers/data/dtos/diaper_stock_dto.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:colette/features/diapers/domain/repositories/diaper_stock_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Stock dans `households/{code}.diaperStock`.
class FirestoreDiaperStockRepository implements DiaperStockRepository {
  FirestoreDiaperStockRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _household(String code) =>
      _db.collection(FirestorePaths.households).doc(code);

  @override
  Stream<DiaperStock?> watchStock(String householdCode) =>
      _household(householdCode).snapshots().map((snap) {
        final data = snap.data()?['diaperStock'] as Map<String, dynamic>?;
        return data == null ? null : DiaperStockDto.fromMap(data);
      });

  @override
  Future<Either<Failure, void>> saveStock(
    String householdCode,
    DiaperStock stock,
  ) => guard(
    () => _household(householdCode).set({
      'diaperStock': DiaperStockDto.toMap(stock),
    }, SetOptions(merge: true)),
  );
}
