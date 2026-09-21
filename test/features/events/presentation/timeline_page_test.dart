import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/events/domain/repositories/events_repository.dart';
import 'package:colette/features/events/presentation/pages/timeline_page.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/care_event_factory.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

class MockEventsRepository extends Mock implements EventsRepository {}

void main() {
  final now = DateTime(2026, 9, 21, 14);

  testWidgets('affiche les événements groupés par jour', (tester) async {
    final repo = MockEventsRepository();
    when(() => repo.watchLatest(any(), limit: any(named: 'limit'))).thenAnswer(
      (_) => Stream.value([
        makeEvent(
          id: 'today',
          startAt: DateTime(2026, 9, 21, 9, 5),
          bottleMl: 120,
          diaperChange: true,
        ),
        makeEvent(
          id: 'yesterday',
          startAt: DateTime(2026, 9, 20, 22),
          bath: true,
        ),
      ]),
    );
    await pumpApp(
      tester,
      const TimelinePage(),
      overrides: [
        eventsRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(FixedClock(now)),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    expect(find.text('Aujourd\'hui'), findsOneWidget);
    expect(find.text('Hier'), findsOneWidget);
    expect(find.text('09h05'), findsOneWidget);
    expect(find.text('120 ml'), findsOneWidget);
  });

  testWidgets('affiche l\'état vide sans événement', (tester) async {
    final repo = MockEventsRepository();
    when(() => repo.watchLatest(any(), limit: any(named: 'limit')))
        .thenAnswer((_) => Stream.value(const []));
    await pumpApp(
      tester,
      const TimelinePage(),
      overrides: [
        eventsRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(FixedClock(now)),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    expect(find.textContaining('Aucun événement'), findsOneWidget);
  });
}
