import 'package:colette/core/result/failure.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:fpdart/fpdart.dart';

/// Événements de soin d'un foyer.
abstract interface class EventsRepository {
  /// Les [limit] événements les plus récents, du plus récent au plus ancien.
  Stream<List<CareEvent>> watchLatest(
    String householdCode, {
    required int limit,
  });

  /// Événements dont `startAt` est dans `[from, to[`, du plus récent au plus ancien.
  Stream<List<CareEvent>> watchBetween(
    String householdCode, {
    required DateTime from,
    required DateTime to,
  });

  Future<Either<Failure, List<CareEvent>>> getBetween(
    String householdCode, {
    required DateTime from,
    required DateTime to,
  });

  Stream<CareEvent?> watchLatestBath(String householdCode);

  Stream<CareEvent?> watchLatestBottle(String householdCode);

  Future<Either<Failure, CareEvent?>> getLatestBottle(String householdCode);

  /// Crée ou remplace l'événement (clé : `event.id`).
  Future<Either<Failure, void>> save(String householdCode, CareEvent event);

  Future<Either<Failure, void>> delete(String householdCode, String eventId);
}
