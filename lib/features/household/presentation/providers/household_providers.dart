import 'dart:async';
import 'dart:developer' as developer;

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/result/no_retry.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/household/data/firestore_device_repository.dart';
import 'package:colette/features/household/data/firestore_household_repository.dart';
import 'package:colette/features/household/data/prefs_household_local_store.dart';
import 'package:colette/features/household/domain/entities/device_info.dart';
import 'package:colette/features/household/domain/household_code_generator.dart';
import 'package:colette/features/household/domain/repositories/device_repository.dart';
import 'package:colette/features/household/domain/repositories/household_local_store.dart';
import 'package:colette/features/household/domain/repositories/household_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'household_providers.g.dart';

@Riverpod(keepAlive: true)
HouseholdLocalStore householdLocalStore(Ref ref) =>
    PrefsHouseholdLocalStore(ref.watch(sharedPreferencesProvider));

@riverpod
HouseholdRepository householdRepository(Ref ref) =>
    FirestoreHouseholdRepository(
      ref.watch(firestoreProvider),
      ref.watch(clockProvider),
    );

/// Sans état : `keepAlive` car consommé par l'enregistrement push (keepAlive).
@Riverpod(keepAlive: true)
DeviceRepository deviceRepository(Ref ref) =>
    FirestoreDeviceRepository(ref.watch(firestoreProvider));

@riverpod
HouseholdCodeGenerator householdCodeGenerator(Ref ref) =>
    HouseholdCodeGenerator();

/// Code du foyer courant ; `null` tant que l'onboarding n'est pas terminé.
@Riverpod(keepAlive: true)
class CurrentHouseholdCode extends _$CurrentHouseholdCode {
  @override
  String? build() => ref.watch(householdLocalStoreProvider).householdCode;

  Future<void> set(String code) async {
    await ref.read(householdLocalStoreProvider).saveHouseholdCode(code);
    state = code;
  }

  Future<void> clear() async {
    await ref.read(householdLocalStoreProvider).clearHouseholdCode();
    state = null;
  }
}

/// Identifiant stable de cet iPhone.
@Riverpod(keepAlive: true)
String deviceId(Ref ref) => ref.watch(householdLocalStoreProvider).deviceId;

/// Document de cet iPhone dans le foyer courant.
@Riverpod(retry: noRetry)
Stream<DeviceInfo?> currentDevice(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(null);
  return ref
      .watch(deviceRepositoryProvider)
      .watchDevice(code, ref.watch(deviceIdProvider));
}

/// Retire cet iPhone du foyer puis oublie le code foyer.
@riverpod
class LeaveHouseholdController extends _$LeaveHouseholdController {
  @override
  FutureOr<void> build() {}

  Future<void> leave() async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return;
    state = const AsyncLoading();
    final result = await ref
        .read(deviceRepositoryProvider)
        .deleteDevice(code, ref.read(deviceIdProvider))
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () => left(const NetworkFailure()),
        );
    result.fold(
      (failure) => developer.log(
        'Appareil non retiré du foyer : $failure',
        name: 'colette',
      ),
      (_) {},
    );
    state = const AsyncData(null);
    await ref.read(currentHouseholdCodeProvider.notifier).clear();
  }
}
