import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_household_local_store.dart';

void main() {
  test('set et clear mettent à jour l\'état et le stockage local', () async {
    final store = InMemoryHouseholdLocalStore();
    final container = ProviderContainer(
      overrides: [householdLocalStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    expect(container.read(currentHouseholdCodeProvider), isNull);

    await container.read(currentHouseholdCodeProvider.notifier).set('ABCDEFGH');
    expect(container.read(currentHouseholdCodeProvider), 'ABCDEFGH');
    expect(store.householdCode, 'ABCDEFGH');

    await container.read(currentHouseholdCodeProvider.notifier).clear();
    expect(container.read(currentHouseholdCodeProvider), isNull);
    expect(store.householdCode, isNull);
  });

  test('deviceIdProvider expose l\'identifiant du stockage local', () {
    final container = ProviderContainer(
      overrides: [
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(deviceId: 'dev-9'),
        ),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(deviceIdProvider), 'dev-9');
  });
}
