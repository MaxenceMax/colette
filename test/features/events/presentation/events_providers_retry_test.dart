import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/features/events/domain/repositories/events_repository.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';

class MockEventsRepository extends Mock implements EventsRepository {}

/// Une `Exception` (pas une `Error`) : c'est le cas que Riverpod relance par défaut.
final _failure = Exception('permission-denied');

void main() {
  final now = DateTime(2026, 9, 22, 10);
  late MockEventsRepository repo;

  ProviderContainer containerWith(MockEventsRepository repo) {
    final container = ProviderContainer(
      overrides: [
        eventsRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(FixedClock(now)),
        minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Écoute [provider], laisse l'erreur du stream se propager et renvoie l'état.
  Future<AsyncValue<T>> failedState<T>(
    ProviderContainer container,
    ProviderListenable<AsyncValue<T>> provider,
  ) async {
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();
    return container.read(provider);
  }

  setUp(() {
    repo = MockEventsRepository();
    when(
      () => repo.watchBetween(
        any(),
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) => Stream<List<CareEvent>>.error(_failure));
    when(() => repo.watchLatestBottle(any()))
        .thenAnswer((_) => Stream<CareEvent?>.error(_failure));
    when(
      () => repo.watchDiaperChangeCountSince(any(), from: any(named: 'from')),
    ).thenAnswer((_) => Stream<int>.error(_failure));
    when(() => repo.watchLatest(any(), limit: any(named: 'limit')))
        .thenAnswer((_) => Stream<List<CareEvent>>.error(_failure));
  });

  test('todayEvents remonte la failure en AsyncError sans relance', () async {
    final state = await failedState(containerWith(repo), todayEventsProvider);
    expect(state, isA<AsyncError<List<CareEvent>>>());
    expect(state.retrying, isFalse);
  });

  test('recentEvents remonte la failure en AsyncError sans relance', () async {
    final state = await failedState(containerWith(repo), recentEventsProvider);
    expect(state, isA<AsyncError<List<CareEvent>>>());
    expect(state.retrying, isFalse);
  });

  test('weekEvents remonte la failure en AsyncError sans relance', () async {
    final state = await failedState(containerWith(repo), weekEventsProvider);
    expect(state, isA<AsyncError<List<CareEvent>>>());
    expect(state.retrying, isFalse);
  });

  test('latestBottle remonte la failure en AsyncError sans relance', () async {
    final state = await failedState(containerWith(repo), latestBottleProvider);
    expect(state, isA<AsyncError<CareEvent?>>());
    expect(state.retrying, isFalse);
  });

  test(
    'diaperChangesSince remonte la failure en AsyncError sans relance',
    () async {
      final state = await failedState(
        containerWith(repo),
        diaperChangesSinceProvider(now),
      );
      expect(state, isA<AsyncError<int>>());
      expect(state.retrying, isFalse);
    },
  );

  test(
    'timelineEvents remonte la failure en AsyncError sans relance',
    () async {
      final state = await failedState(
        containerWith(repo),
        timelineEventsProvider,
      );
      expect(state, isA<AsyncError<List<CareEvent>>>());
      expect(state.retrying, isFalse);
    },
  );
}
