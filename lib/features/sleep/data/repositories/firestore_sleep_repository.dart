import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/firebase/firestore_paths.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/sleep/data/dtos/sleep_session_dto.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:colette/features/sleep/domain/repositories/sleep_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Sommeils dans `households/{code}/sleeps/{id}`.
class FirestoreSleepRepository implements SleepRepository {
  FirestoreSleepRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _sleeps(String code) => _db
      .collection(FirestorePaths.households)
      .doc(code)
      .collection(FirestorePaths.sleeps);

  List<SleepSession> _toList(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs.map(SleepSessionDto.fromDoc).toList();

  @override
  Stream<List<SleepSession>> watchStartedSince(
    String householdCode,
    DateTime from,
  ) =>
      _sleeps(householdCode)
          .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .orderBy('startAt', descending: true)
          .snapshots()
          .map(_toList);

  @override
  Stream<SleepSession?> watchLatest(String householdCode) =>
      _sleeps(householdCode)
          .orderBy('startAt', descending: true)
          .limit(1)
          .snapshots()
          .map((snap) => _toList(snap).firstOrNull);

  @override
  Future<Either<Failure, List<SleepSession>>> getStartedBetween(
    String householdCode, {
    required DateTime from,
    required DateTime to,
  }) => guard(
    () async => _toList(
      await _sleeps(householdCode)
          .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .where('startAt', isLessThan: Timestamp.fromDate(to))
          .orderBy('startAt', descending: true)
          .get(),
    ),
  );

  @override
  Future<Either<Failure, void>> save(
    String householdCode,
    SleepSession session,
  ) => guard(
    () =>
        _sleeps(householdCode)
            .doc(session.id)
            .set(SleepSessionDto.toMap(session)),
  );

  @override
  Future<Either<Failure, void>> delete(
    String householdCode,
    String sessionId,
  ) => guard(() => _sleeps(householdCode).doc(sessionId).delete());

  @override
  Future<Either<Failure, void>> wakeUp(
    String householdCode, {
    required SleepSession close,
    required List<String> deleteIds,
  }) => guard(() {
    final sleeps = _sleeps(householdCode);
    final batch = _db.batch()
      ..set(sleeps.doc(close.id), SleepSessionDto.toMap(close));
    for (final id in deleteIds) {
      batch.delete(sleeps.doc(id));
    }
    return batch.commit();
  });
}
