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
import 'package:colette/features/sleep/domain/use_cases/validate_sleep_session.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sleep_controller.g.dart';

/// Endormissement, réveil, saisie et suppression d'un sommeil.
@riverpod
class SleepController extends _$SleepController {
  /// Marge au-delà de `now` pour la recherche des sommeils voisins.
  static const _neighbourMargin = Duration(minutes: 2);

  @override
  FutureOr<void> build() {
    // `babyProfileProvider` est autoDispose : le veiller ici évite qu'il soit
    // détruit pendant l'`await` d'un `ref.read` dans `fallAsleep`/`save`.
    ref.watch(babyProfileProvider);
  }

  /// Lance un sommeil maintenant ; `false` si un sommeil est déjà en cours.
  Future<bool> fallAsleep() async {
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
  Future<bool> wakeUp() async {
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

  /// Valide puis enregistre [draft]. Renvoie le sommeil enregistré, ou `null`.
  Future<SleepSession?> save(SleepSession draft) async {
    final code = ref.read(currentHouseholdCodeProvider);
    final profile = ref.read(babyProfileProvider).value;
    if (code == null || profile == null) return null;
    final repo = ref.read(sleepRepositoryProvider);
    final now = ref.read(clockProvider).now();
    final session = draft.copyWith(updatedAt: now);
    state = const AsyncLoading();
    final neighbours = await repo.getStartedBetween(
      code,
      from: session.startAt.subtract(ValidateSleepSession.maxDuration),
      to: now.add(_neighbourMargin),
    );
    final result = await neighbours
        .flatMap(
          (others) => const ValidateSleepSession()(
            session,
            now: now,
            birthDate: profile.birthDate,
            others: others,
          ),
        )
        .match<Future<Either<Failure, SleepSession>>>(
          (failure) async => left(failure),
          (valid) async => (await repo.save(code, valid)).map((_) => valid),
        );
    if (ref.mounted) {
      state = result.fold(
        (failure) => AsyncError(failure, StackTrace.current),
        (_) => const AsyncData(null),
      );
    }
    return result.getRight().toNullable();
  }

  Future<bool> delete(String sessionId) =>
      _run((code) => ref.read(sleepRepositoryProvider).delete(code, sessionId));

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
