import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/features/events/domain/entities/event_tag.dart';
import 'package:colette/features/events/domain/entities/timeline_filter.dart';
import 'package:colette/features/events/domain/repositories/events_repository.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/events/presentation/providers/timeline_filter_controller.dart';
import 'package:colette/features/events/presentation/providers/timeline_sleeps_provider.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_providers.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/care_event_factory.dart';
import '../../../helpers/fake_sleep_repository.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/sleep_session_factory.dart';

class MockEventsRepository extends Mock implements EventsRepository {}

void main() {
  final now = DateTime(2026, 9, 21, 14);
  late MockEventsRepository repo;

  setUpAll(() => registerFallbackValue(const BottleTag()));

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        eventsRepositoryProvider.overrideWithValue(repo),
        sleepRepositoryProvider.overrideWithValue(
          FakeSleepRepository([
            makeSleep(
              id: 's',
              startAt: DateTime(2026, 9, 21, 10),
              endAt: DateTime(2026, 9, 21, 11),
            ),
          ]),
        ),
        clockProvider.overrideWithValue(FixedClock(now)),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    repo = MockEventsRepository();
    when(
      () => repo.watchLatest(
        any(),
        limit: any(named: 'limit'),
        only: any(named: 'only'),
      ),
    ).thenAnswer(
      (_) => Stream.value([
        makeEvent(id: 'e', startAt: DateTime(2026, 9, 21, 9), poop: true),
      ]),
    );
  });

  test('le filtre vaut Tout par défaut', () {
    final container = makeContainer();
    expect(
      container.read(timelineFilterControllerProvider),
      const AllEntriesFilter(),
    );
  });

  test('choisir un filtre remet la limite à une page', () {
    final container = makeContainer();
    final limitSub = container.listen(timelineLimitProvider, (_, _) {});
    addTearDown(limitSub.close);
    final filterSub = container.listen(
      timelineFilterControllerProvider,
      (_, _) {},
    );
    addTearDown(filterSub.close);
    container.read(timelineLimitProvider.notifier).loadMore();
    expect(container.read(timelineLimitProvider), timelinePageSize * 2);
    container
        .read(timelineFilterControllerProvider.notifier)
        .select(const CareTypeFilter(CareType.poop));
    expect(
      container.read(timelineFilterControllerProvider),
      const CareTypeFilter(CareType.poop),
    );
    expect(container.read(timelineLimitProvider), timelinePageSize);
  });

  test('timelineEvents transmet le tag du filtre au dépôt', () async {
    final container = makeContainer();
    final sub = container.listen(timelineEventsProvider, (_, _) {});
    addTearDown(sub.close);
    container
        .read(timelineFilterControllerProvider.notifier)
        .select(const CareTypeFilter(CareType.poop));
    await container.read(timelineEventsProvider.future);
    verify(
      () => repo.watchLatest(
        'ABCDEFGH',
        limit: timelinePageSize,
        only: const CareTag(CareType.poop),
      ),
    ).called(1);
  });

  test('timelineEvents est vide avec le filtre Sommeil', () async {
    final container = makeContainer();
    final sub = container.listen(timelineEventsProvider, (_, _) {});
    addTearDown(sub.close);
    container
        .read(timelineFilterControllerProvider.notifier)
        .select(const SleepFilter());
    expect(await container.read(timelineEventsProvider.future), <CareEvent>[]);
  });

  test('timelineSleeps est vide avec un filtre de soin', () async {
    final container = makeContainer();
    final sub = container.listen(timelineSleepsProvider, (_, _) {});
    addTearDown(sub.close);
    container
        .read(timelineFilterControllerProvider.notifier)
        .select(const CareTypeFilter(CareType.poop));
    expect(await container.read(timelineSleepsProvider.future), isEmpty);
  });

  test('timelineSleeps pagine les sommeils avec le filtre Sommeil', () async {
    final container = makeContainer();
    final sub = container.listen(timelineSleepsProvider, (_, _) {});
    addTearDown(sub.close);
    container
        .read(timelineFilterControllerProvider.notifier)
        .select(const SleepFilter());
    final sleeps = await container.read(timelineSleepsProvider.future);
    expect(sleeps.map((s) => s.id), ['s']);
  });
}
