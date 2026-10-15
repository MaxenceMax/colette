import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/teeth/presentation/providers/teeth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../teeth_factories.dart';

void main() {
  test('indexe les dents par numéro et les résume', () async {
    final record = makeTooth(71, eruptedAt: DateTime(2027, 1, 10, 12));
    final repo = MockTeethRepository();
    when(() => repo.watchTeeth('ABCDEFGH'))
        .thenAnswer((_) => Stream.value([record]));
    final container = ProviderContainer(
      overrides: [
        teethRepositoryProvider.overrideWithValue(repo),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(teethSummaryProvider, (_, _) {});
    addTearDown(sub.close);
    expect(await container.read(teethProvider.future), {tooth(71): record});
    expect(container.read(teethSummaryProvider)!.inMouth, 1);
  });

  test('sans foyer : aucune dent', () async {
    final container = ProviderContainer(
      overrides: [
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(teethProvider, (_, _) {});
    addTearDown(sub.close);
    expect(await container.read(teethProvider.future), isEmpty);
  });
}
