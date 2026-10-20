import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/events/domain/entities/care_day_summary.dart';
import 'package:colette/features/events/domain/entities/event_tag.dart';
import 'package:colette/features/events/domain/entities/timeline_filter.dart';
import 'package:colette/features/events/domain/repositories/events_repository.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/events/presentation/providers/timeline_day_summaries_provider.dart';
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
  final now = DateTime(2026, 10, 20, 14);
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
              startAt: DateTime(2026, 10, 17, 22),
              endAt: DateTime(2026, 10, 18, 6),
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
        makeEvent(id: 'p', startAt: DateTime(2026, 10, 19, 8), pee: true),
      ]),
    );
    when(
      () => repo.watchBetween(
        any(),
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer(
      (_) => Stream.value([
        makeEvent(id: 'b', startAt: DateTime(2026, 10, 20, 9), bottleMl: 120),
        makeEvent(id: 'p', startAt: DateTime(2026, 10, 19, 8), pee: true),
      ]),
    );
  });

  test('le bilan ignore le filtre et couvre les jours chargés', () async {
    final container = makeContainer();
    final sub = container.listen(timelineDaySummariesProvider, (_, _) {});
    addTearDown(sub.close);
    container
        .read(timelineFilterControllerProvider.notifier)
        .select(const CareTypeFilter(CareType.pee));
    await container.read(timelineEventsProvider.future);
    final summaries = await container.read(timelineDaySummariesProvider.future);
    expect(
      summaries[DateTime(2026, 10, 20)],
      const CareDaySummary(bottleMl: 120, bottleCount: 1),
    );
    expect(summaries[DateTime(2026, 10, 19)], const CareDaySummary(pee: 1));
    verify(
      () => repo.watchBetween(
        'ABCDEFGH',
        from: DateTime(2026, 10, 19),
        to: DateTime(2026, 10, 21),
      ),
    ).called(greaterThanOrEqualTo(1));
  });

  test('le bilan remonte au plus ancien sommeil chargé', () async {
    final container = makeContainer();
    final sub = container.listen(timelineDaySummariesProvider, (_, _) {});
    addTearDown(sub.close);
    container
        .read(timelineFilterControllerProvider.notifier)
        .select(const SleepFilter());
    await container.read(timelineSleepsProvider.future);
    await container.read(timelineDaySummariesProvider.future);
    verify(
      () => repo.watchBetween(
        'ABCDEFGH',
        from: DateTime(2026, 10, 17),
        to: DateTime(2026, 10, 21),
      ),
    ).called(greaterThanOrEqualTo(1));
  });
}
