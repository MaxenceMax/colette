import 'dart:async';

import 'package:colette/core/result/either_extensions.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/domain/entities/device_info.dart';
import 'package:colette/features/household/domain/household_code_generator.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_controller.g.dart';

/// Création ou jonction d'un foyer. L'état porte l'échec éventuel.
@riverpod
class OnboardingController extends _$OnboardingController {
  String? _pendingCode;

  @override
  FutureOr<void> build() {}

  Future<bool> createHousehold({
    required String babyName,
    required DateTime birthDate,
    required String deviceLabel,
  }) => _run(() async {
    final name = babyName.trim();
    if (name.isEmpty) {
      return left(const ValidationFailure(ValidationReason.emptyName));
    }
    final code = _pendingCode ??= ref
        .read(householdCodeGeneratorProvider)
        .generate();
    final created = await ref.read(householdRepositoryProvider).create(code);
    if (created.leftOrNull case final failure?) return left(failure);
    final saved = await ref
        .read(babyRepositoryProvider)
        .saveProfile(code, BabyProfile(name: name, birthDate: birthDate));
    if (saved.leftOrNull case final failure?) return left(failure);
    return _registerDeviceAndEnter(code, deviceLabel);
  });

  Future<bool> joinHousehold({
    required String code,
    required String deviceLabel,
  }) => _run(() async {
    final normalized = HouseholdCodeGenerator.normalize(code);
    if (!HouseholdCodeGenerator.isValid(normalized)) {
      return left(
        const ValidationFailure(ValidationReason.unknownHouseholdCode),
      );
    }
    final joined = await ref.read(householdRepositoryProvider).join(normalized);
    if (joined.leftOrNull case final failure?) {
      return left(
        failure is NotFoundFailure
            ? const ValidationFailure(ValidationReason.unknownHouseholdCode)
            : failure,
      );
    }
    return _registerDeviceAndEnter(normalized, deviceLabel);
  });

  Future<Either<Failure, void>> _registerDeviceAndEnter(
    String code,
    String deviceLabel,
  ) async {
    final device = DeviceInfo(
      id: ref.read(deviceIdProvider),
      label: deviceLabel.trim(),
    );
    final registered = await ref
        .read(deviceRepositoryProvider)
        .saveDevice(code, device);
    if (registered.leftOrNull case final failure?) return left(failure);
    await ref.read(currentHouseholdCodeProvider.notifier).set(code);
    _pendingCode = null;
    return right(null);
  }

  Future<bool> _run(Future<Either<Failure, void>> Function() action) async {
    state = const AsyncLoading();
    final result = await action();
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    return result.isRight();
  }
}
