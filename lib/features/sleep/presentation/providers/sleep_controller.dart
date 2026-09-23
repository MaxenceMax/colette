import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:colette/features/sleep/domain/entities/sleep_status.dart';
import 'package:colette/features/sleep/domain/use_cases/classify_sleep_kind.dart';
import 'package:colette/features/sleep/domain/use_cases/compute_sleep_summary.dart';
import 'package:colette/features/sleep/domain/use_cases/plan_wake_up.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sleep_controller.g.dart';

/// Endormissement et réveil, déclenchés depuis la carte d'accueil.
@riverpod
class SleepController extends _$SleepController {
  @override
  FutureOr<void> build() {
    // Le profil doit déjà être chargé au moment de l'appel : on l'écoute sans
    // reconstruire le contrôleur. Un `watch` remettrait `state` à `AsyncData`
    // à chaque émission du profil, y compris pendant une écriture, ce qui
    // réactive les boutons de la carte et permet un double envoi.
    ref.listen(babyProfileProvider, (_, _) {});
  }

  /// Lance un sommeil maintenant ; `false` si un sommeil est déjà en cours.
  ///
  /// À appeler depuis un widget qui surveille `sleepSummaryProvider` (la
  /// carte), sinon les flux ne sont pas chargés et l'appel ne fait rien.
  Future<bool> fallAsleep() async {
    if (state.isLoading) return false;
    final status = ref.read(sleepSummaryProvider)?.status;
    if (status is! Awake) return false;
    final now = ref.read(clockProvider).now();
    final settings =
        ref.read(babyProfileProvider).value?.careSettings ??
        const CareSettings();
    final session = SleepSession(
      id: ref.read(idGeneratorProvider).newId(),
      startAt: now,
      kind: classifySleepKind(
        now,
        nightStartHour: settings.nightStartHour,
        nightEndHour: settings.nightEndHour,
      ),
      createdByDeviceId: ref.read(deviceIdProvider),
      createdAt: now,
      updatedAt: now,
    );
    return _run(
      (code) => ref.read(sleepRepositoryProvider).save(code, session),
    );
  }

  /// Termine le sommeil en cours maintenant et supprime les doublons ouverts.
  ///
  /// À appeler depuis un widget qui surveille `sleepSummaryProvider` (la
  /// carte), sinon les flux ne sont pas chargés et l'appel ne fait rien.
  Future<bool> wakeUp() async {
    if (state.isLoading) return false;
    final open = openSleeps(
      ref.read(recentSleepsProvider).value ?? const [],
      ref.read(latestSleepProvider).value,
    );
    final plan = planWakeUp(open, ref.read(clockProvider).now());
    if (plan == null) return false;
    return _run(
      (code) => ref
          .read(sleepRepositoryProvider)
          .wakeUp(code, close: plan.close, deleteIds: plan.deleteIds),
    );
  }

  Future<bool> _run(
    Future<Either<Failure, void>> Function(String code) action,
  ) async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return false;
    state = const AsyncLoading();
    final result = await action(code);
    if (ref.mounted) {
      state = result.fold(
        (failure) => AsyncError(failure, StackTrace.current),
        (_) => const AsyncData(null),
      );
    }
    return result.isRight();
  }
}
