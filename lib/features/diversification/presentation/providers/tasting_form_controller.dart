import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tasting_form_controller.g.dart';

/// Enregistrement et suppression d'une dégustation. L'état porte l'échec éventuel.
@riverpod
class TastingFormController extends _$TastingFormController {
  @override
  FutureOr<void> build() {}

  /// Crée ([Tasting.id] vide) ou remplace la dégustation ; `false` si refusée
  /// (date future) ou en échec.
  Future<bool> save(Tasting draft) async {
    if (draft.at.isAfter(ref.read(clockProvider).now())) {
      state = AsyncError(
        const ValidationFailure(ValidationReason.startInFuture),
        StackTrace.current,
      );
      return false;
    }
    final note = draft.note?.trim();
    final tasting = draft.copyWith(
      id: draft.id.isEmpty ? ref.read(idGeneratorProvider).newId() : draft.id,
      note: note == null || note.isEmpty ? null : note,
    );
    return _run(
      (code) => ref.read(tastingsRepositoryProvider).save(code, tasting),
    );
  }

  Future<bool> delete(String tastingId) => _run(
    (code) => ref.read(tastingsRepositoryProvider).delete(code, tastingId),
  );

  Future<bool> _run(
    Future<Either<Failure, void>> Function(String code) action,
  ) async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return false;
    state = const AsyncLoading();
    final result = await action(code);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    return result.isRight();
  }
}
