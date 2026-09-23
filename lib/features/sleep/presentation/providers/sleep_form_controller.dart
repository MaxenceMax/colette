import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:colette/features/sleep/domain/use_cases/validate_sleep_session.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sleep_form_controller.g.dart';

/// Enregistrement et suppression d'un sommeil depuis le formulaire.
///
/// Séparé de `SleepController` : une erreur de saisie ne doit pas déclencher
/// la SnackBar de la carte, et un `wakeUp` en cours ne doit pas désactiver le
/// bouton Enregistrer du formulaire.
@riverpod
class SleepFormController extends _$SleepFormController {
  /// Marge au-delà de `now` pour la recherche des sommeils voisins.
  static const _neighbourMargin = Duration(minutes: 2);

  @override
  FutureOr<void> build() {
    // Le profil doit déjà être chargé au moment de l'appel : on l'écoute sans
    // reconstruire le contrôleur. Un `watch` remettrait `state` à `AsyncData`
    // à chaque émission du profil, y compris pendant une écriture, ce qui
    // réactiverait le bouton Enregistrer et permettrait un double envoi.
    ref.listen(babyProfileProvider, (_, _) {});
  }

  /// Valide puis enregistre [draft]. Renvoie le sommeil enregistré, ou `null`.
  Future<SleepSession?> save(SleepSession draft) async {
    if (state.isLoading) return null;
    final code = ref.read(currentHouseholdCodeProvider);
    final profile = ref.read(babyProfileProvider).value;
    if (code == null || profile == null) {
      state = AsyncError(const NotFoundFailure(), StackTrace.current);
      return null;
    }
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

  /// Supprime le sommeil [id]. `false` sans code foyer ou en cas d'échec.
  Future<bool> delete(String id) async {
    if (state.isLoading) return false;
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return false;
    state = const AsyncLoading();
    final result = await ref.read(sleepRepositoryProvider).delete(code, id);
    if (ref.mounted) {
      state = result.fold(
        (failure) => AsyncError(failure, StackTrace.current),
        (_) => const AsyncData(null),
      );
    }
    return result.isRight();
  }
}
