import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/features/events/domain/use_cases/validate_care_event.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_form_controller.g.dart';

/// Enregistrement et suppression d'un événement. L'état porte l'échec éventuel.
@riverpod
class EventFormController extends _$EventFormController {
  @override
  FutureOr<void> build() {}

  /// Valide puis enregistre [draft]. Renvoie l'événement enregistré, ou `null`.
  Future<CareEvent?> submit(CareEvent draft) async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return null;
    final now = ref.read(clockProvider).now();
    final validated = const ValidateCareEvent()(
      draft.copyWith(updatedAt: now),
      now: now,
    );
    state = const AsyncLoading();
    final result = await validated.fold<Future<Either<Failure, CareEvent>>>(
      (failure) async => left(failure),
      (event) async {
        final saved = await ref
            .read(eventsRepositoryProvider)
            .save(code, event);
        return saved.map((_) => event);
      },
    );
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    final saved = result.getRight().toNullable();
    if (saved != null) await ref.read(feedingPlanSyncProvider).sync();
    return saved;
  }

  Future<bool> delete(String eventId) async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return false;
    state = const AsyncLoading();
    final result = await ref
        .read(eventsRepositoryProvider)
        .delete(code, eventId);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    if (result.isRight()) await ref.read(feedingPlanSyncProvider).sync();
    return result.isRight();
  }
}
