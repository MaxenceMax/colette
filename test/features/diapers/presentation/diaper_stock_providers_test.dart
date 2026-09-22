import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock_status.dart';
import 'package:colette/features/diapers/domain/repositories/diaper_stock_repository.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_providers.dart';
import 'package:colette/features/events/domain/repositories/events_repository.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';

class MockDiaperStockRepository extends Mock implements DiaperStockRepository {}

class MockEventsRepository extends Mock implements EventsRepository {}

void main() {
  final countedAt = DateTime(2026, 9, 20, 10);

  ProviderContainer containerWith({
    required DiaperStock? stock,
    required int changes,
  }) {
    final stockRepo = MockDiaperStockRepository();
    final eventsRepo = MockEventsRepository();
    when(() => stockRepo.watchStock(any()))
        .thenAnswer((_) => Stream.value(stock));
    when(
      () => eventsRepo.watchDiaperChangeCountSince(
        any(),
        from: any(named: 'from'),
      ),
    ).thenAnswer((_) => Stream.value(changes));
    final container = ProviderContainer(
      overrides: [
        diaperStockRepositoryProvider.overrideWithValue(stockRepo),
        eventsRepositoryProvider.overrideWithValue(eventsRepo),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('diaperStockStatus est null sans stock renseigné', () async {
    final container = containerWith(stock: null, changes: 3);
    final sub = container.listen(diaperStockStatusProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(diaperStockProvider.future);
    expect(container.read(diaperStockStatusProvider), isNull);
  });

  test(
    'diaperStockStatus combine le stock et les changes depuis countedAt',
    () async {
      final container = containerWith(
        stock: DiaperStock(count: 12, countedAt: countedAt),
        changes: 3,
      );
      final sub = container.listen(diaperStockStatusProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(diaperStockProvider.future);
      await container.read(diaperChangesSinceProvider(countedAt).future);
      expect(
        container.read(diaperStockStatusProvider),
        const DiaperStockStatus(remaining: 9, isLow: true),
      );
    },
  );
}
