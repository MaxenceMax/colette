import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/firebase/firestore_paths.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/teeth/data/dtos/tooth_record_dto.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/domain/repositories/teeth_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Dents dans `households/{code}/teeth/{numéro}`.
class FirestoreTeethRepository implements TeethRepository {
  FirestoreTeethRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _teeth(String code) => _db
      .collection(FirestorePaths.households)
      .doc(code)
      .collection(FirestorePaths.teeth);

  static List<ToothRecord> _decode(QuerySnapshot<Map<String, dynamic>> snap) {
    final records = <ToothRecord>[];
    for (final doc in snap.docs) {
      final record = ToothRecordDto.fromDoc(doc);
      if (record == null) {
        log('Dent illisible ignorée : ${doc.id}', name: 'colette');
        continue;
      }
      records.add(record);
    }
    return records;
  }

  @override
  Stream<List<ToothRecord>> watchTeeth(String householdCode) =>
      _teeth(householdCode).snapshots().map(_decode);

  @override
  Future<Either<Failure, void>> saveTooth(
    String householdCode,
    ToothRecord record,
  ) => guard(
    () =>
        _teeth(householdCode)
            .doc(ToothRecordDto.docId(record.toothId))
            .set(ToothRecordDto.toMap(record)),
  );

  @override
  Future<Either<Failure, void>> deleteTooth(
    String householdCode,
    ToothId toothId,
  ) => guard(
    () => _teeth(householdCode).doc(ToothRecordDto.docId(toothId)).delete(),
  );
}
