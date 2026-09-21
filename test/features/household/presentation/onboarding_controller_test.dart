import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/domain/entities/device_info.dart';
import 'package:colette/features/household/domain/entities/household.dart';
import 'package:colette/features/household/domain/repositories/device_repository.dart';
import 'package:colette/features/household/domain/repositories/household_repository.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/household/presentation/providers/onboarding_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';

class MockHouseholdRepository extends Mock implements HouseholdRepository {}

class MockBabyRepository extends Mock implements BabyRepository {}

class MockDeviceRepository extends Mock implements DeviceRepository {}

void main() {
  late MockHouseholdRepository households;
  late MockBabyRepository babies;
  late MockDeviceRepository devices;
  late InMemoryHouseholdLocalStore store;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(BabyProfile(name: 'x', birthDate: DateTime(2026)));
    registerFallbackValue(const DeviceInfo(id: 'x', label: 'x'));
  });

  setUp(() {
    households = MockHouseholdRepository();
    babies = MockBabyRepository();
    devices = MockDeviceRepository();
    store = InMemoryHouseholdLocalStore(deviceId: 'dev-1');
    container = ProviderContainer(
      overrides: [
        householdRepositoryProvider.overrideWithValue(households),
        babyRepositoryProvider.overrideWithValue(babies),
        deviceRepositoryProvider.overrideWithValue(devices),
        householdLocalStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);
  });

  test('createHousehold crée le foyer, le profil, l\'appareil et enregistre le code', () async {
    when(() => households.create(any())).thenAnswer(
      (inv) async => right(
        Household(
          code: inv.positionalArguments.first as String,
          createdAt: DateTime(2026),
        ),
      ),
    );
    when(() => babies.saveProfile(any(), any()))
        .thenAnswer((_) async => right(null));
    when(() => devices.saveDevice(any(), any()))
        .thenAnswer((_) async => right(null));

    final ok = await container
        .read(onboardingControllerProvider.notifier)
        .createHousehold(
          babyName: 'Colette',
          birthDate: DateTime(2026, 9, 1),
          deviceLabel: 'iPhone de Maxence',
        );

    expect(ok, isTrue);
    expect(store.householdCode, hasLength(8));
    verify(() => babies.saveProfile(any(), any())).called(1);
    verify(() => devices.saveDevice(any(), any(that: isA<DeviceInfo>())))
        .called(1);
  });

  test(
    'createHousehold refuse un prénom vide sans appeler Firestore',
    () async {
      final ok = await container
          .read(onboardingControllerProvider.notifier)
          .createHousehold(
            babyName: '  ',
            birthDate: DateTime(2026, 9, 1),
            deviceLabel: 'iPhone',
          );
      expect(ok, isFalse);
      expect(
        container.read(onboardingControllerProvider).error,
        isA<ValidationFailure>(),
      );
      verifyNever(() => households.create(any()));
    },
  );

  test('joinHousehold convertit NotFoundFailure en code inconnu', () async {
    when(() => households.join('ABCDEFGH'))
        .thenAnswer((_) async => left(const NotFoundFailure()));
    final ok = await container
        .read(onboardingControllerProvider.notifier)
        .joinHousehold(code: 'abcd efgh', deviceLabel: 'iPhone');
    expect(ok, isFalse);
    final error = container.read(onboardingControllerProvider).error;
    expect(error, isA<ValidationFailure>());
    expect(
      (error! as ValidationFailure).reason,
      ValidationReason.unknownHouseholdCode,
    );
    expect(store.householdCode, isNull);
  });

  test('joinHousehold enregistre le code après succès', () async {
    when(() => households.join('ABCDEFGH')).thenAnswer(
      (_) async =>
          right(Household(code: 'ABCDEFGH', createdAt: DateTime(2026))),
    );
    when(() => devices.saveDevice(any(), any()))
        .thenAnswer((_) async => right(null));
    final ok = await container
        .read(onboardingControllerProvider.notifier)
        .joinHousehold(code: 'ABCDEFGH', deviceLabel: 'iPhone');
    expect(ok, isTrue);
    expect(store.householdCode, 'ABCDEFGH');
  });
}
