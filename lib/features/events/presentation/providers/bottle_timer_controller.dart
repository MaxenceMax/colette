import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/events/domain/use_cases/bottle_timer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bottle_timer_controller.g.dart';

/// Heure de lancement du minuteur de biberon ; `null` au repos.
@riverpod
class BottleTimerController extends _$BottleTimerController {
  @override
  DateTime? build() => null;

  /// Lance (ou relance) le minuteur maintenant.
  void start() => state = ref.read(clockProvider).now();

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
  final startedAt = ref.watch(bottleTimerControllerProvider);
  if (startedAt == null) return null;
  final now =
      ref.watch(bottleTimerTickProvider).value ??
      ref.watch(clockProvider).now();
  return computeBottleTimerPhase(startedAt: startedAt, now: now);
}
