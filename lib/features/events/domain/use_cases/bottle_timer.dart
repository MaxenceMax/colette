import 'package:colette/features/events/domain/entities/bottle_timer_run.dart';

/// Phase du minuteur de biberon à un instant donné.
sealed class BottleTimerPhase {
  const BottleTimerPhase();
}

/// Biberon en cours.
final class BottleFeeding extends BottleTimerPhase {
  const BottleFeeding({required this.remaining, required this.progress});

  final Duration remaining;

  /// Avancement de la phase, entre 0 et 1.
  final double progress;
}

/// Maintien à la verticale en cours.
final class BottleUpright extends BottleTimerPhase {
  const BottleUpright({required this.remaining, required this.progress});

  final Duration remaining;

  /// Avancement de la phase, entre 0 et 1.
  final double progress;
}

/// Minuteur terminé.
final class BottleTimerDone extends BottleTimerPhase {
  const BottleTimerDone();
}

/// Phase du minuteur [run], vue à [now].
BottleTimerPhase computeBottleTimerPhase({
  required BottleTimerRun run,
  required DateTime now,
}) {
  final at = now.isBefore(run.startedAt) ? run.startedAt : now;
  if (at.isBefore(run.feedingEndsAt)) {
    return BottleFeeding(
      remaining: run.feedingEndsAt.difference(at),
      progress:
          at.difference(run.startedAt).inMilliseconds /
          bottleFeedingDuration.inMilliseconds,
    );
  }
  if (at.isBefore(run.uprightEndsAt)) {
    return BottleUpright(
      remaining: run.uprightEndsAt.difference(at),
      progress:
          at.difference(run.feedingEndsAt).inMilliseconds /
          bottleUprightDuration.inMilliseconds,
    );
  }
  return const BottleTimerDone();
}

/// Changement de phase qui appelle une réaction (son, veille, enregistrement).
enum BottleTimerTransition { started, feedingEnded, finished, stopped }

/// Transition entre deux phases successives ; `null` = repos.
BottleTimerTransition? bottleTimerTransition(
  BottleTimerPhase? previous,
  BottleTimerPhase? next,
) {
  final wasRunning = previous is BottleFeeding || previous is BottleUpright;
  return switch (next) {
    BottleFeeding() when !wasRunning => .started,
    BottleUpright() when !wasRunning => .started,
    BottleUpright() when previous is BottleFeeding => .feedingEnded,
    BottleTimerDone() when wasRunning => .finished,
    null when wasRunning => .stopped,
    _ => null,
  };
}
