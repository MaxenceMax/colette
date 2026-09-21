import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/features/events/domain/repositories/events_repository.dart';
import 'package:colette/features/events/presentation/pages/timeline_page.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/events/presentation/widgets/event_tile.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
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

  testWidgets(
    'charger plus conserve la liste affichée pendant le rechargement',
    (tester) async {
      final repo = MockEventsRepository();
      final events = List.generate(
        5,
        (i) => makeEvent(
          id: 'e$i',
          startAt: DateTime(
            2026,
            9,
            21,
            20,
          ).subtract(Duration(minutes: 10 * i)),
          pee: true,
        ),
      );
      final page2 = StreamController<List<CareEvent>>();
      addTearDown(page2.close);
      when(() => repo.watchLatest(any(), limit: 30))
          .thenAnswer((_) => Stream.value(events));
      when(() => repo.watchLatest(any(), limit: 60))
          .thenAnswer((_) => page2.stream);
      late WidgetRef pageRef;
      await pumpApp(
        tester,
        Consumer(
          builder: (context, ref, _) {
            pageRef = ref;
            return const TimelinePage();
          },
        ),
        overrides: [
          eventsRepositoryProvider.overrideWithValue(repo),
          clockProvider.overrideWithValue(FixedClock(now)),
          householdLocalStoreProvider.overrideWithValue(
            InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
          ),
        ],
      );
      expect(find.byType(EventTile), findsWidgets);
      pageRef.read(timelineLimitProvider.notifier).loadMore();
      await tester.pump();
      expect(
        find.byType(EventTile),
        findsWidgets,
        reason: 'la liste reste montée pendant le rechargement',
      );
      expect(
        find.byType(EmptyState),
        findsNothing,
        reason: 'la liste ne doit pas être remplacée par un état vide',
      );
    },
  );

  testWidgets('glisser puis confirmer supprime l\'événement', (tester) async {
    final repo = MockEventsRepository();
    final event = makeEvent(
      id: 'e1',
      startAt: DateTime(2026, 9, 21, 9),
      pee: true,
    );
    when(() => repo.watchLatest(any(), limit: any(named: 'limit')))
        .thenAnswer((_) => Stream.value([event]));
    when(() => repo.delete('ABCDEFGH', 'e1'))
        .thenAnswer((_) async => right(null));
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
    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Supprimer'));
    await tester.pumpAndSettle();
    verify(() => repo.delete('ABCDEFGH', 'e1')).called(1);
  });
}
