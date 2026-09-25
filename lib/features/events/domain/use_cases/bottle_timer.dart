/// Durée utile pour donner le biberon.
const bottleFeedingDuration = Duration(minutes: 30);

/// Durée de maintien à la verticale après le biberon.
const bottleUprightDuration = Duration(minutes: 12);

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

/// Phase du minuteur lancé à [startedAt], vue à [now].
BottleTimerPhase computeBottleTimerPhase({
  required DateTime startedAt,
  required DateTime now,
}) {
  final elapsed = now.isBefore(startedAt)
      ? Duration.zero
      : now.difference(startedAt);
  if (elapsed < bottleFeedingDuration) {
    return BottleFeeding(
      remaining: bottleFeedingDuration - elapsed,
      progress: elapsed.inMilliseconds / bottleFeedingDuration.inMilliseconds,
    );
  }
  final upright = elapsed - bottleFeedingDuration;
  if (upright < bottleUprightDuration) {
    return BottleUpright(
      remaining: bottleUprightDuration - upright,
      progress: upright.inMilliseconds / bottleUprightDuration.inMilliseconds,
    );
  }
  return const BottleTimerDone();
}
