import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/domain/use_cases/validate_tooth_record.dart';
import 'package:colette/features/teeth/presentation/providers/teeth_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'teeth_controller.g.dart';

/// Enregistre une dent (ou la supprime si elle est vide), ou l'efface.
@riverpod
class TeethController extends _$TeethController {
  @override
  FutureOr<void> build() {}

  Future<bool> save(ToothRecord record, {required DateTime birthDate}) async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return false;
    // Lu avant l'await : le contrôleur autoDispose peut être détruit pendant l'écriture.
    final repo = ref.read(teethRepositoryProvider);
    final now = ref.read(clockProvider).now();
    final stamped = record.copyWith(
      updatedAt: now,
      updatedByDeviceId: ref.read(deviceIdProvider),
    );
    state = const AsyncLoading();
    final result =
        await const ValidateToothRecord()(
          stamped,
          birthDate: birthDate,
          now: now,
        ).fold<Future<Either<Failure, void>>>(
          (failure) async => left(failure),
          (valid) => valid.isEmpty
              ? repo.deleteTooth(code, valid.toothId)
              : repo.saveTooth(code, valid),
        );
    _settle(result);
    return result.isRight();
  }

  Future<bool> clear(ToothId toothId) async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return false;
    final repo = ref.read(teethRepositoryProvider);
    state = const AsyncLoading();
    final result = await repo.deleteTooth(code, toothId);
    _settle(result);
    return result.isRight();
  }

  void _settle(Either<Failure, void> result) {
    if (!ref.mounted) return;
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }
}
