import 'package:colette/core/result/failure.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:fpdart/fpdart.dart';

/// Sommeils d'un foyer.
abstract interface class SleepRepository {
  /// Sommeils dont `startAt` ≥ [from], du plus récent au plus ancien.
  Stream<List<SleepSession>> watchStartedSince(
    String householdCode,
    DateTime from,
  );

  /// Dernier sommeil par `startAt`, toutes dates confondues.
  Stream<SleepSession?> watchLatest(String householdCode);

  /// Sommeils dont `startAt` est dans `[from, to[`.
  Future<Either<Failure, List<SleepSession>>> getStartedBetween(
    String householdCode, {
    required DateTime from,
    required DateTime to,
  });

  /// Crée ou remplace le sommeil (clé : `session.id`).
  Future<Either<Failure, void>> save(
    String householdCode,
    SleepSession session,
  );

  Future<Either<Failure, void>> delete(String householdCode, String sessionId);

  /// Écrit [close] et supprime [deleteIds] en un seul lot.
  Future<Either<Failure, void>> wakeUp(
    String householdCode, {
    required SleepSession close,
    required List<String> deleteIds,
  });
}
