import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/use_cases/validate_medical_visit.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'medical_visit_controller.g.dart';

/// Enregistre une visite (ou la supprime si elle est vide) puis resynchronise.
@riverpod
class MedicalVisitController extends _$MedicalVisitController {
  @override
  FutureOr<void> build() {}

  Future<bool> save(MedicalVisit visit, {required DateTime birthDate}) async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return false;
    // Lu avant l'await : le contrôleur autoDispose peut être détruit pendant l'écriture.
    final sync = ref.read(healthSyncProvider);
    final repo = ref.read(medicalRepositoryProvider);
    final now = ref.read(clockProvider).now();
    final stamped = visit.copyWith(
      updatedAt: now,
      updatedByDeviceId: ref.read(deviceIdProvider),
    );
    state = const AsyncLoading();
    final result =
        await const ValidateMedicalVisit()(
          stamped,
          birthDate: birthDate,
          now: now,
        ).fold<Future<Either<Failure, void>>>(
          (failure) async => left(failure),
          (valid) => valid.isEmpty
              ? repo.deleteVisit(code, valid.stageId)
              : repo.saveVisit(code, valid),
        );
    if (ref.mounted) {
      state = result.fold(
        (failure) => AsyncError(failure, StackTrace.current),
        (_) => const AsyncData(null),
      );
    }
    if (result.isRight()) await sync.sync();
    return result.isRight();
  }
}
