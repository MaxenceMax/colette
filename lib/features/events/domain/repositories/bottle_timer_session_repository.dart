import 'package:colette/core/result/failure.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_session.dart';
import 'package:fpdart/fpdart.dart';

/// Stockage local de la session du minuteur de biberon (une au plus).
abstract interface class BottleTimerSessionRepository {
  Future<Either<Failure, void>> save(BottleTimerSession session);

  /// `null` si aucune session n'est enregistrée.
  Future<Either<Failure, BottleTimerSession?>> load();

  Future<Either<Failure, void>> clear();
}
