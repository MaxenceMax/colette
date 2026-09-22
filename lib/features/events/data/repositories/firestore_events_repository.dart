import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/firebase/firestore_paths.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/events/data/dtos/care_event_dto.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/features/events/domain/repositories/events_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Événements dans `households/{code}/events/{id}`.
class FirestoreEventsRepository implements EventsRepository {
  FirestoreEventsRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _events(String code) => _db
      .collection(FirestorePaths.households)
      .doc(code)
      .collection(FirestorePaths.events);

  Query<Map<String, dynamic>> _between(
    String code,
    DateTime from,
    DateTime to,
  ) =>
      _events(code)
          .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .where('startAt', isLessThan: Timestamp.fromDate(to))
          .orderBy('startAt', descending: true);

  Query<Map<String, dynamic>> _latestWhere(String code, String field) =>
      _events(code)
          .where(field, isEqualTo: true)
          .orderBy('startAt', descending: true)
          .limit(1);

  List<CareEvent> _toList(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs.map(CareEventDto.fromDoc).toList();

  CareEvent? _firstOrNull(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs.isEmpty ? null : CareEventDto.fromDoc(snap.docs.first);

  @override
  Stream<List<CareEvent>> watchLatest(
    String householdCode, {
    required int limit,
  }) =>
      _events(householdCode)
          .orderBy('startAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(_toList);

  @override
  Stream<List<CareEvent>> watchBetween(
    String householdCode, {
    required DateTime from,
    required DateTime to,
  }) => _between(householdCode, from, to).snapshots().map(_toList);

  @override
  Future<Either<Failure, List<CareEvent>>> getBetween(
    String householdCode, {
    required DateTime from,
    required DateTime to,
  }) =>
      guard(() async => _toList(await _between(householdCode, from, to).get()));

  @override
  Stream<CareEvent?> watchLatestBath(String householdCode) =>
      _latestWhere(householdCode, 'bath').snapshots().map(_firstOrNull);

  @override
  Stream<CareEvent?> watchLatestBottle(String householdCode) =>
      _latestWhere(householdCode, 'hasBottle').snapshots().map(_firstOrNull);

  @override
  Future<Either<Failure, CareEvent?>> getLatestBottle(String householdCode) =>
      guard(
        () async =>
            _firstOrNull(await _latestWhere(householdCode, 'hasBottle').get()),
      );

  @override
  Stream<int> watchDiaperChangeCountSince(
    String householdCode, {
    required DateTime from,
  }) =>
      _events(householdCode)
          .where('diaperChange', isEqualTo: true)
          .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .snapshots()
          .map((snap) => snap.docs.length);

  @override
  Future<Either<Failure, void>> save(String householdCode, CareEvent event) =>
      guard(
        () =>
            _events(householdCode).doc(event.id).set(CareEventDto.toMap(event)),
      );

  @override
  Future<Either<Failure, void>> delete(String householdCode, String eventId) =>
      guard(() => _events(householdCode).doc(eventId).delete());
}
