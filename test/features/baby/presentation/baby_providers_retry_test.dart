import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';

class MockBabyRepository extends Mock implements BabyRepository {}

/// Une `Exception` (pas une `Error`) : c'est le cas que Riverpod relance par défaut.
final _failure = Exception('permission-denied');

void main() {
  late MockBabyRepository repo;

  ProviderContainer containerWith(MockBabyRepository repo) {
    final container = ProviderContainer(
      overrides: [
        babyRepositoryProvider.overrideWithValue(repo),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    repo = MockBabyRepository();
    when(() => repo.watchProfile(any()))
        .thenAnswer((_) => Stream<BabyProfile?>.error(_failure));
    when(() => repo.watchWeights(any()))
        .thenAnswer((_) => Stream<List<WeightEntry>>.error(_failure));
  });

  test('babyProfile remonte la failure en AsyncError sans relance', () async {
    final container = containerWith(repo);
    final sub = container.listen(babyProfileProvider, (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();
    final state = container.read(babyProfileProvider);
    expect(state, isA<AsyncError<BabyProfile?>>());
    expect(state.retrying, isFalse);
  });

  test('weights remonte la failure en AsyncError sans relance', () async {
    final container = containerWith(repo);
    final sub = container.listen(weightsProvider, (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();
    final state = container.read(weightsProvider);
    expect(state, isA<AsyncError<List<WeightEntry>>>());
    expect(state.retrying, isFalse);
  });
}
