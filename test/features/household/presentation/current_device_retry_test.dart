import 'package:colette/features/household/domain/entities/device_info.dart';
import 'package:colette/features/household/domain/repositories/device_repository.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';

class MockDeviceRepository extends Mock implements DeviceRepository {}

/// Une `Exception` (pas une `Error`) : c'est le cas que Riverpod relance par défaut.
final _failure = Exception('permission-denied');

void main() {
  test('currentDevice remonte la failure en AsyncError sans relance', () async {
    final repo = MockDeviceRepository();
    when(() => repo.watchDevice(any(), any()))
        .thenAnswer((_) => Stream<DeviceInfo?>.error(_failure));
    final container = ProviderContainer(
      overrides: [
        deviceRepositoryProvider.overrideWithValue(repo),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(currentDeviceProvider, (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();
    final state = container.read(currentDeviceProvider);
    expect(state, isA<AsyncError<DeviceInfo?>>());
    expect(state.retrying, isFalse);
  });
}
