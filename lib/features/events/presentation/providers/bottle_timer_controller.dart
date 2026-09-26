import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/device/device_feedback.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_run.dart';
import 'package:colette/features/events/domain/use_cases/bottle_timer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bottle_timer_controller.g.dart';

/// Minuteur de biberon lancé ; `null` au repos.
@riverpod
class BottleTimerController extends _$BottleTimerController {
  @override
  BottleTimerRun? build() => null;

  /// Lance (ou relance) le minuteur maintenant.
  void start() =>
      state = BottleTimerRun.startingAt(ref.read(clockProvider).now());

  /// Termine le biberon maintenant : la verticale démarre.
  void skipToUpright() {
    final run = state;
    final now = ref.read(clockProvider).now();
    if (run == null || !now.isBefore(run.feedingEndsAt)) return;
    state = run.copyWith(feedingEndsAt: now);
  }

  /// Arrête le minuteur.
  void reset() => state = null;
}

/// Heure courante, émise chaque seconde tant qu'un minuteur est lancé.
@riverpod
Stream<DateTime> bottleTimerTick(Ref ref) async* {
  final clock = ref.watch(clockProvider);
  yield clock.now();
  yield* Stream.periodic(const Duration(seconds: 1), (_) => clock.now());
}

/// Phase courante du minuteur de biberon ; `null` au repos.
@riverpod
BottleTimerPhase? bottleTimerPhase(Ref ref) {
  final run = ref.watch(bottleTimerControllerProvider);
  if (run == null) return null;
  final now =
      ref.watch(bottleTimerTickProvider).value ??
      ref.watch(clockProvider).now();
  return computeBottleTimerPhase(run: run, now: now);
}

/// Écran maintenu allumé, sons et vibrations aux transitions du minuteur.
/// Relâche l'écran à sa destruction (fermeture du formulaire).
@riverpod
void bottleTimerEffects(Ref ref) {
  final feedback = ref.watch(deviceFeedbackProvider);
  ref
    ..listen(bottleTimerPhaseProvider, (previous, next) {
      switch (bottleTimerTransition(previous, next)) {
        case .started:
          unawaited(feedback.setKeepScreenOn(true));
        case .feedingEnded:
          unawaited(feedback.playSound(.feedingEnded));
          unawaited(feedback.vibrate());
        case .finished:
          unawaited(feedback.playSound(.uprightEnded));
          unawaited(feedback.vibrate());
          unawaited(feedback.setKeepScreenOn(false));
        case .stopped:
          unawaited(feedback.setKeepScreenOn(false));
        case null:
          break;
      }
    })
    ..onDispose(() => unawaited(feedback.setKeepScreenOn(false)));
}
