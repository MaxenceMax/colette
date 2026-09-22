import 'package:colette/core/result/failure.dart';
import 'package:colette/features/household/domain/repositories/device_repository.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';

class MockDeviceRepository extends Mock implements DeviceRepository {}

void main() {
  late MockDeviceRepository devices;
  late InMemoryHouseholdLocalStore store;
  late ProviderContainer container;

  setUp(() {
    devices = MockDeviceRepository();
    store = InMemoryHouseholdLocalStore(
      householdCode: 'ABCDEFGH',
      deviceId: 'dev-1',
    );
    container = ProviderContainer(
      overrides: [
        deviceRepositoryProvider.overrideWithValue(devices),
        householdLocalStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);
  });

  test('leave() retire l\'appareil puis oublie le code foyer', () async {
    when(() => devices.deleteDevice(any(), any()))
        .thenAnswer((_) async => right(null));
    await container.read(leaveHouseholdControllerProvider.notifier).leave();
    verify(() => devices.deleteDevice('ABCDEFGH', 'dev-1')).called(1);
    expect(container.read(currentHouseholdCodeProvider), isNull);
  });

  test('un échec de suppression n\'empêche pas de quitter le foyer', () async {
    when(() => devices.deleteDevice(any(), any()))
        .thenAnswer((_) async => left(const NetworkFailure()));
    await container.read(leaveHouseholdControllerProvider.notifier).leave();
    expect(container.read(currentHouseholdCodeProvider), isNull);
  });
}
