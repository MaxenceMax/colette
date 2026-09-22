import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'diaper_stock_controller.g.dart';

/// Recomptage, ajout de paquet et seuil d'alerte. L'état porte l'échec éventuel.
/// Reçoit le stock courant en paramètre (`null` s'il n'est pas encore renseigné).
@riverpod
class DiaperStockController extends _$DiaperStockController {
  static const maxCount = DiaperStock.maxCount;
  static const maxPackSize = DiaperStock.maxPackSize;
  static const maxThreshold = DiaperStock.maxThreshold;

  @override
  FutureOr<void> build() {}

  /// Pose [count] comme nouveau stock à l'instant présent.
  Future<bool> recount(DiaperStock? current, int count) {
    if (count < 0 || count > maxCount) return _reject();
    final now = ref.read(clockProvider).now();
    final base = current ?? DiaperStock(count: 0, countedAt: now);
    return _save(base.recount(count, now: now));
  }

  /// Ajoute un paquet de [size] couches au [remaining] courant.
  Future<bool> addPack(
    DiaperStock? current, {
    required int remaining,
    required int size,
  }) {
    final next = remaining + size;
    if (size < 1 || size > maxPackSize || next < 0 || next > maxCount) {
      return _reject();
    }
    final now = ref.read(clockProvider).now();
    final base = current ?? DiaperStock(count: 0, countedAt: now);
    return _save(base.addPack(size, remaining: remaining, now: now));
  }

  /// Pose le seuil d'alerte ; `0` désactive l'alerte. N'écrit que ce champ,
  /// en fusion Firestore : un recomptage de l'autre parent n'est jamais écrasé.
  Future<bool> setThreshold(int threshold) {
    if (threshold < 0 || threshold > maxThreshold) return _reject();
    return _run(
      (code) => ref
          .read(diaperStockRepositoryProvider)
          .saveThreshold(code, threshold),
    );
  }

  Future<bool> _reject() async {
    state = AsyncError(
      const ValidationFailure(ValidationReason.invalidDiaperCount),
      StackTrace.current,
    );
    return false;
  }

  /// Sauvegarde [stock] entier via `saveStock`.
  Future<bool> _save(DiaperStock stock) => _run(
    (code) => ref.read(diaperStockRepositoryProvider).saveStock(code, stock),
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
