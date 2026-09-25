import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/features/events/domain/repositories/events_repository.dart';
import 'package:colette/features/events/presentation/providers/bottle_timer_controller.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/events/presentation/widgets/event_form_sheet.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/care_event_factory.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

class MockEventsRepository extends Mock implements EventsRepository {}

void main() {
  final now = DateTime(2026, 9, 25, 14);
  const startLabel = 'Lancer le minuteur (30 + 12 min)';
  late MockEventsRepository repo;
  late StreamController<DateTime> ticks;

  setUpAll(() => registerFallbackValue(makeEvent(startAt: DateTime(2026))));

  setUp(() {
    repo = MockEventsRepository();
    when(() => repo.save(any(), any())).thenAnswer((_) async => right(null));
    ticks = StreamController<DateTime>.broadcast();
  });

  tearDown(() => ticks.close());

  Future<void> openSheet(WidgetTester tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showEventFormSheet(context),
            child: const Text('ouvrir'),
          ),
        ),
      ),
      viewSize: const Size(430, 1400),
      overrides: [
        eventsRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(FixedClock(now)),
        idGeneratorProvider.overrideWithValue(const FixedIdGenerator('e-new')),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(
            householdCode: 'ABCDEFGH',
            deviceId: 'dev-1',
          ),
        ),
        babyProfileProvider.overrideWith((ref) => Stream.value(null)),
        feedingPlanSyncProvider.overrideWithValue(const NoopFeedingPlanSync()),
        bottleTimerTickProvider.overrideWith((ref) => ticks.stream),
      ],
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  Future<void> enableBottleAndStart(WidgetTester tester) async {
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.tap(find.text(startLabel));
    await tester.pump();
  }

  Future<void> requestClose(WidgetTester tester) async {
    await tester.state<NavigatorState>(find.byType(Navigator).first).maybePop();
    await tester.pumpAndSettle();
  }

  testWidgets('le minuteur n\'apparaît qu\'avec Biberon activé', (
    tester,
  ) async {
    await openSheet(tester);
    expect(find.text(startLabel), findsNothing);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(find.text(startLabel), findsOneWidget);
  });

  testWidgets('sans minuteur, la fermeture ne demande rien', (tester) async {
    await openSheet(tester);
    await requestClose(tester);
    expect(find.byType(EventFormSheet), findsNothing);
  });

  testWidgets('fermer pendant le minuteur demande confirmation', (
    tester,
  ) async {
    await openSheet(tester);
    await enableBottleAndStart(tester);

    await requestClose(tester);
    expect(find.text('Arrêter le minuteur ?'), findsOneWidget);
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.byType(EventFormSheet), findsOneWidget);
    expect(find.text('Biberon'), findsWidgets);

    await requestClose(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Arrêter').last);
    await tester.pumpAndSettle();
    expect(find.byType(EventFormSheet), findsNothing);
  });

  testWidgets('enregistrer pendant le minuteur ferme sans confirmation', (
    tester,
  ) async {
    await openSheet(tester);
    await enableBottleAndStart(tester);
    final save = find.widgetWithText(FilledButton, 'Enregistrer');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Arrêter le minuteur ?'), findsNothing);
    expect(find.byType(EventFormSheet), findsNothing);
    final saved =
        verify(() => repo.save('ABCDEFGH', captureAny())).captured.single
            as CareEvent;
    expect(saved.bottleMl, 120);
  });

  testWidgets('désactiver Biberon arrête le minuteur', (tester) async {
    await openSheet(tester);
    await enableBottleAndStart(tester);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await requestClose(tester);
    expect(find.text('Arrêter le minuteur ?'), findsNothing);
    expect(find.byType(EventFormSheet), findsNothing);
  });
}
