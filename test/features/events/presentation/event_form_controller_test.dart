import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/features/events/domain/repositories/events_repository.dart';
import 'package:colette/features/events/presentation/providers/event_form_controller.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/care_event_factory.dart';
import '../../../helpers/in_memory_household_local_store.dart';

class MockEventsRepository extends Mock implements EventsRepository {}

void main() {
  final now = DateTime(2026, 9, 21, 14, 30);
  late MockEventsRepository repo;
  late ProviderContainer container;

  setUpAll(() => registerFallbackValue(makeEvent(startAt: DateTime(2026))));

  setUp(() {
    repo = MockEventsRepository();
    container = ProviderContainer(
      overrides: [
        eventsRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(FixedClock(now)),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
        feedingPlanSyncProvider.overrideWithValue(const NoopFeedingPlanSync()),
      ],
    );
    addTearDown(container.dispose);
  });

  test('submit valide, met à jour updatedAt et enregistre', () async {
    when(() => repo.save(any(), any())).thenAnswer((_) async => right(null));
    final draft = makeEvent(
      startAt: now.subtract(const Duration(hours: 1)),
      pee: true,
    );
    final saved = await container
        .read(eventFormControllerProvider.notifier)
        .submit(draft);
    expect(saved, isNotNull);
    expect(saved!.updatedAt, now);
    final captured =
        verify(() => repo.save('ABCDEFGH', captureAny())).captured.single
            as CareEvent;
    expect(captured.pee, isTrue);
  });

  test('submit refuse un brouillon vide sans écrire', () async {
    final saved = await container
        .read(eventFormControllerProvider.notifier)
        .submit(makeEvent(startAt: now));
    expect(saved, isNull);
    expect(
      container.read(eventFormControllerProvider).error,
      isA<ValidationFailure>(),
    );
    verifyNever(() => repo.save(any(), any()));
  });

  test('delete appelle le repository', () async {
    when(() => repo.delete('ABCDEFGH', 'e1'))
        .thenAnswer((_) async => right(null));
    final ok = await container
        .read(eventFormControllerProvider.notifier)
        .delete('e1');
    expect(ok, isTrue);
  });
}
