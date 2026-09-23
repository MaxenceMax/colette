import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/health/domain/entities/custom_appointment.dart';
import 'package:colette/features/health/domain/use_cases/validate_custom_appointment.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'custom_appointment_controller.g.dart';

/// Enregistre ou supprime un RDV libre, puis resynchronise rappels et calendrier.
@riverpod
class CustomAppointmentController extends _$CustomAppointmentController {
  @override
  FutureOr<void> build() {}

  Future<bool> save(
    CustomAppointment appointment, {
    required DateTime birthDate,
  }) async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return false;
    // Lu avant l'await : le contrôleur autoDispose peut être détruit pendant l'écriture.
    final sync = ref.read(healthSyncProvider);
    final repo = ref.read(medicalRepositoryProvider);
    final now = ref.read(clockProvider).now();
    final stamped = appointment.copyWith(
      updatedAt: now,
      updatedByDeviceId: ref.read(deviceIdProvider),
    );
    state = const AsyncLoading();
    final result =
        await const ValidateCustomAppointment()(
          stamped,
          birthDate: birthDate,
          now: now,
        ).fold<Future<Either<Failure, void>>>(
          (failure) async => left(failure),
          (valid) => repo.saveAppointment(code, valid),
        );
    return _finish(result, sync);
  }

  Future<bool> delete(String appointmentId) async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return false;
    final sync = ref.read(healthSyncProvider);
    final repo = ref.read(medicalRepositoryProvider);
    state = const AsyncLoading();
    final result = await repo.deleteAppointment(code, appointmentId);
    return _finish(result, sync);
  }

  Future<bool> _finish(Either<Failure, void> result, HealthSync sync) async {
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
