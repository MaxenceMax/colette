import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:colette/features/diapers/domain/repositories/diaper_stock_repository.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';

class MockDiaperStockRepository extends Mock implements DiaperStockRepository {}

/// Une `Exception` (pas une `Error`) : c'est le cas que Riverpod relance par défaut.
final _failure = Exception('permission-denied');

void main() {
  test('diaperStock remonte la failure en AsyncError sans relance', () async {
    final repo = MockDiaperStockRepository();
    when(() => repo.watchStock(any()))
        .thenAnswer((_) => Stream<DiaperStock?>.error(_failure));
    final container = ProviderContainer(
      overrides: [
        diaperStockRepositoryProvider.overrideWithValue(repo),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(diaperStockProvider, (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();
    final state = container.read(diaperStockProvider);
    expect(state, isA<AsyncError<DiaperStock?>>());
    expect(state.retrying, isFalse);
  });
}
