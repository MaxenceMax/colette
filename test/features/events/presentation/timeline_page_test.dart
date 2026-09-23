import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/features/events/domain/repositories/events_repository.dart';
import 'package:colette/features/events/presentation/pages/timeline_page.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/events/presentation/widgets/event_tile.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_providers.dart';
import 'package:colette/features/sleep/presentation/widgets/sleep_tile.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/care_event_factory.dart';
import '../../../helpers/fake_sleep_repository.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/sleep_session_factory.dart';

class MockEventsRepository extends Mock implements EventsRepository {}

/// Dépôt de sommeils qui répond immédiatement tant que [holdNewCalls] est
/// faux ; une fois activé, chaque nouvel appel de `watchStartedSince` renvoie
/// un flux qui ne dira jamais rien, pour simuler un écho Firestore qui
/// n'arrive pas tout de suite.
class RecordingSleepRepository extends FakeSleepRepository {
  RecordingSleepRepository([super.sessions = const []]);

  final List<DateTime> calls = [];
  bool holdNewCalls = false;
  final List<StreamController<List<SleepSession>>> heldControllers = [];

  @override
  Stream<List<SleepSession>> watchStartedSince(String code, DateTime from) {
    calls.add(from);
    if (holdNewCalls) {
      final controller = StreamController<List<SleepSession>>();
      heldControllers.add(controller);
      return controller.stream;
    }
    return super.watchStartedSince(code, from);
  }
}

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
        sleepRepositoryProvider.overrideWithValue(FakeSleepRepository()),
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
    expect(find.text('Couche'), findsOneWidget);
    expect(find.text('Bain'), findsOneWidget);
    expect(find.byIcon(Icons.local_drink_outlined), findsOneWidget);
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
        sleepRepositoryProvider.overrideWithValue(FakeSleepRepository()),
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
          sleepRepositoryProvider.overrideWithValue(FakeSleepRepository()),
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
        sleepRepositoryProvider.overrideWithValue(FakeSleepRepository()),
        clockProvider.overrideWithValue(FixedClock(now)),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
        feedingPlanSyncProvider.overrideWithValue(const NoopFeedingPlanSync()),
      ],
    );
    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Supprimer'));
    await tester.pumpAndSettle();
    verify(() => repo.delete('ABCDEFGH', 'e1')).called(1);
  });

  testWidgets('mêle les sommeils aux soins dans le bon jour', (tester) async {
    final repo = MockEventsRepository();
    when(() => repo.watchLatest(any(), limit: any(named: 'limit'))).thenAnswer(
      (_) => Stream.value([
        makeEvent(id: 'today', startAt: DateTime(2026, 9, 21, 9, 5), pee: true),
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
        sleepRepositoryProvider.overrideWithValue(
          FakeSleepRepository([
            makeSleep(
              id: 's',
              startAt: DateTime(2026, 9, 21, 10, 20),
              endAt: DateTime(2026, 9, 21, 12),
            ),
          ]),
        ),
        clockProvider.overrideWithValue(FixedClock(now)),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    expect(find.text('Sieste'), findsOneWidget);
    expect(find.text('1 h 40'), findsOneWidget);
    final sleepY = tester.getTopLeft(find.text('Sieste')).dy;
    final careY = tester.getTopLeft(find.text('09h05')).dy;
    expect(sleepY, lessThan(careY));
  });

  testWidgets(
    'un Journal qui ne contient que des sommeils n\'affiche pas l\'état vide',
    (tester) async {
      final repo = MockEventsRepository();
      when(() => repo.watchLatest(any(), limit: any(named: 'limit')))
          .thenAnswer((_) => Stream.value(const []));
      await pumpApp(
        tester,
        const TimelinePage(),
        overrides: [
          eventsRepositoryProvider.overrideWithValue(repo),
          sleepRepositoryProvider.overrideWithValue(
            FakeSleepRepository([
              makeSleep(
                id: 's',
                startAt: DateTime(2026, 9, 21, 10, 20),
                endAt: DateTime(2026, 9, 21, 12),
              ),
            ]),
          ),
          clockProvider.overrideWithValue(FixedClock(now)),
          householdLocalStoreProvider.overrideWithValue(
            InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
          ),
        ],
      );
      expect(find.byType(EmptyState), findsNothing);
      expect(find.byType(SleepTile), findsOneWidget);
    },
  );

  testWidgets('glisser puis confirmer supprime le sommeil', (tester) async {
    final eventsRepo = MockEventsRepository();
    when(() => eventsRepo.watchLatest(any(), limit: any(named: 'limit')))
        .thenAnswer((_) => Stream.value(const []));
    final sleepRepo = FakeSleepRepository([
      makeSleep(
        id: 's1',
        startAt: DateTime(2026, 9, 21, 10),
        endAt: DateTime(2026, 9, 21, 11),
      ),
    ]);
    await pumpApp(
      tester,
      const TimelinePage(),
      overrides: [
        eventsRepositoryProvider.overrideWithValue(eventsRepo),
        sleepRepositoryProvider.overrideWithValue(sleepRepo),
        clockProvider.overrideWithValue(FixedClock(now)),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
        feedingPlanSyncProvider.overrideWithValue(const NoopFeedingPlanSync()),
      ],
    );
    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Supprimer'));
    await tester.pumpAndSettle();
    expect(sleepRepo.deleted, ['s1']);
  });

  testWidgets(
    'les sommeils ne disparaissent pas quand la fenêtre chargée s\'élargit',
    (tester) async {
      final eventsRepo = MockEventsRepository();
      final initialEvents = List.generate(
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
      when(() => eventsRepo.watchLatest(any(), limit: 30))
          .thenAnswer((_) => Stream.value(initialEvents));
      when(() => eventsRepo.watchLatest(any(), limit: 60))
          .thenAnswer((_) => page2.stream);

      final sleepRepo = RecordingSleepRepository([
        makeSleep(
          id: 's1',
          startAt: DateTime(2026, 9, 21, 10),
          endAt: DateTime(2026, 9, 21, 11),
        ),
      ]);
      addTearDown(() {
        for (final controller in sleepRepo.heldControllers) {
          controller.close();
        }
      });

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
          eventsRepositoryProvider.overrideWithValue(eventsRepo),
          sleepRepositoryProvider.overrideWithValue(sleepRepo),
          clockProvider.overrideWithValue(FixedClock(now)),
          householdLocalStoreProvider.overrideWithValue(
            InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
          ),
        ],
      );

      expect(find.byType(SleepTile), findsOneWidget);

      // À partir d'ici, tout nouvel appel au dépôt de sommeils reste en
      // attente indéfiniment (simule un écho Firestore qui tarde).
      sleepRepo.holdNewCalls = true;

      // Charge la page suivante : la liste d'événements finit par s'élargir
      // à un jour plus ancien, ce qui recule `from` pour les sommeils.
      pageRef.read(timelineLimitProvider.notifier).loadMore();
      await tester.pump();
      page2.add([
        ...initialEvents,
        makeEvent(id: 'older', startAt: DateTime(2026, 9, 20, 8), pee: true),
      ]);
      await tester.pump();
      await tester.pump();

      expect(
        find.byType(SleepTile),
        findsOneWidget,
        reason:
            'la tuile de sommeil doit rester affichée pendant le rechargement',
      );
    },
  );
}
