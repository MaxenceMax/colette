import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'diaper_stock_controller.g.dart';

/// Recomptage, ajout de paquet et seuil d'alerte. L'état porte l'échec éventuel.
/// Reçoit le stock courant en paramètre (`null` s'il n'est pas encore renseigné).
@riverpod
class DiaperStockController extends _$DiaperStockController {
  static const maxCount = 9999;
  static const maxPackSize = 999;
  static const maxThreshold = 999;

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
    if (size < 1 || size > maxPackSize) return _reject();
    if (remaining + size > maxCount) return _reject();
    final now = ref.read(clockProvider).now();
    final base = current ?? DiaperStock(count: 0, countedAt: now);
    return _save(base.addPack(size, remaining: remaining, now: now));
  }

  Future<bool> setThreshold(DiaperStock current, int threshold) {
    if (threshold < 0 || threshold > maxThreshold) return _reject();
    return _save(current.copyWith(alertThreshold: threshold));
  }

  Future<bool> _reject() async {
    state = AsyncError(
      const ValidationFailure(ValidationReason.invalidDiaperCount),
      StackTrace.current,
    );
    return false;
  }

  Future<bool> _save(DiaperStock stock) async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return false;
    state = const AsyncLoading();
    final result = await ref
        .read(diaperStockRepositoryProvider)
        .saveStock(code, stock);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    return result.isRight();
  }
}
