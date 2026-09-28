import 'package:colette/core/result/failure.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_session.dart';
import 'package:colette/features/events/domain/repositories/bottle_timer_session_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Session gardée en mémoire ; [failLoad] simule une session illisible.
class InMemoryBottleTimerSessionRepository
    implements BottleTimerSessionRepository {
  InMemoryBottleTimerSessionRepository({this.session, this.failLoad = false});

  BottleTimerSession? session;
  bool failLoad;
  int clears = 0;

  @override
  Future<Either<Failure, void>> save(BottleTimerSession session) async {
    this.session = session;
    return right(null);
  }

  @override
  Future<Either<Failure, BottleTimerSession?>> load() async =>
      failLoad ? left(UnknownFailure(StateError('illisible'))) : right(session);

  @override
  Future<Either<Failure, void>> clear() async {
    clears++;
    session = null;
    failLoad = false;
    return right(null);
  }
}
