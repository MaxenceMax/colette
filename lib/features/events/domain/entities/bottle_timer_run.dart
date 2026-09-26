import 'package:freezed_annotation/freezed_annotation.dart';

part 'bottle_timer_run.freezed.dart';

/// Durée utile pour donner le biberon.
const bottleFeedingDuration = Duration(minutes: 30);

/// Durée de maintien à la verticale après le biberon.
const bottleUprightDuration = Duration(minutes: 12);

/// Minuteur de biberon lancé : heure de départ et fin (prévue ou anticipée)
/// du biberon.
@freezed
abstract class BottleTimerRun with _$BottleTimerRun {
  const BottleTimerRun._();

  const factory BottleTimerRun({
    required DateTime startedAt,
    required DateTime feedingEndsAt,
  }) = _BottleTimerRun;

  /// Minuteur lancé à [startedAt], biberon prévu sur toute sa durée.
  factory BottleTimerRun.startingAt(DateTime startedAt) => BottleTimerRun(
    startedAt: startedAt,
    feedingEndsAt: startedAt.add(bottleFeedingDuration),
  );

  /// Fin du maintien à la verticale.
  DateTime get uprightEndsAt => feedingEndsAt.add(bottleUprightDuration);
}
