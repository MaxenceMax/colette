import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/device/bottle_timer_system.dart';
import 'package:colette/core/device/device_feedback.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_run.dart';
import 'package:colette/features/events/domain/use_cases/bottle_timer.dart';
import 'package:colette/features/events/presentation/providers/bottle_timer_session_providers.dart';
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

  /// Remet un minuteur interrompu (app tuée) sans changer ses dates.
  void restore(BottleTimerRun run) => state = run;

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

/// Écran maintenu allumé, sons et vibrations aux transitions du minuteur ;
/// Live Activity et notifications tenues à jour. À sa destruction (fermeture
/// du formulaire) : écran relâché, activité fermée, session effacée.
@riverpod
void bottleTimerEffects(Ref ref) {
  final feedback = ref.watch(deviceFeedbackProvider);
  final system = ref.watch(bottleTimerSystemProvider);
  final sessions = ref.watch(bottleTimerSessionRepositoryProvider);
  Future<void> release() async {
    await system.clear();
    await sessions.clear();
  }

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
    ..listen(bottleTimerControllerProvider, (previous, next) {
      if (next != null && next != previous) {
        unawaited(
          system.sync(
            startedAt: next.startedAt,
            feedingEndsAt: next.feedingEndsAt,
            uprightEndsAt: next.uprightEndsAt,
            babyName: ref.read(babyProfileProvider).value?.name ?? '',
          ),
        );
      } else if (next == null && previous != null) {
        unawaited(release());
      }
    })
    ..onDispose(() {
      unawaited(feedback.setKeepScreenOn(false));
      unawaited(release());
    });
}
