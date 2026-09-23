import 'dart:async';

import 'package:colette/core/result/failure.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:colette/features/sleep/domain/repositories/sleep_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Dépôt de sommeils en mémoire ; enregistre les écritures pour les assertions.
class FakeSleepRepository implements SleepRepository {
  FakeSleepRepository([List<SleepSession> sessions = const []])
    : sessions = [...sessions];

  final List<SleepSession> sessions;
  final saved = <SleepSession>[];
  final deleted = <String>[];
  ({SleepSession close, List<String> deleteIds})? lastWakeUp;

  /// Échec renvoyé par toutes les écritures, si renseigné.
  Failure? failure;

  /// Si renseigné, chaque écriture attend cette complétion avant de finir :
  /// permet de vérifier l'état du contrôleur pendant une écriture en cours.
  Completer<void>? writeGate;

  List<SleepSession> _sorted(Iterable<SleepSession> list) =>
      [...list]..sort((a, b) => b.startAt.compareTo(a.startAt));

  @override
  Stream<List<SleepSession>> watchStartedSince(String code, DateTime from) =>
      Stream.value(_sorted(sessions.where((s) => !s.startAt.isBefore(from))));

  @override
  Stream<SleepSession?> watchLatest(String code) =>
      Stream.value(_sorted(sessions).firstOrNull);

  @override
  Future<Either<Failure, List<SleepSession>>> getStartedBetween(
    String code, {
    required DateTime from,
    required DateTime to,
  }) async => right(
    _sorted(
      sessions.where(
        (s) => !s.startAt.isBefore(from) && s.startAt.isBefore(to),
      ),
    ),
  );

  Future<Either<Failure, void>> _write(void Function() action) async {
    if (writeGate case final gate?) await gate.future;
    if (failure case final f?) return left(f);
    action();
    return right(null);
  }

  @override
  Future<Either<Failure, void>> save(String code, SleepSession session) =>
      _write(() {
        saved.add(session);
        sessions
          ..removeWhere((s) => s.id == session.id)
          ..add(session);
      });

  @override
  Future<Either<Failure, void>> delete(String code, String sessionId) =>
      _write(() {
        deleted.add(sessionId);
        sessions.removeWhere((s) => s.id == sessionId);
      });

  @override
  Future<Either<Failure, void>> wakeUp(
    String code, {
    required SleepSession close,
    required List<String> deleteIds,
  }) => _write(() {
    lastWakeUp = (close: close, deleteIds: deleteIds);
    sessions
      ..removeWhere((s) => s.id == close.id || deleteIds.contains(s.id))
      ..add(close);
  });
}
