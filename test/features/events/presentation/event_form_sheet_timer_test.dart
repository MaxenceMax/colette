import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/device/device_feedback.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_run.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_session.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/features/events/domain/repositories/events_repository.dart';
import 'package:colette/features/events/presentation/providers/bottle_timer_controller.dart';
import 'package:colette/features/events/presentation/providers/bottle_timer_session_providers.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/events/presentation/widgets/event_form_sheet.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/care_event_factory.dart';
import '../../../helpers/fake_device_feedback.dart';
import '../../../helpers/in_memory_bottle_timer_session_repository.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

class MockEventsRepository extends Mock implements EventsRepository {}

class _MutableClock implements AppClock {
  _MutableClock(this.current);

  DateTime current;

  @override
  DateTime now() => current;
}

void main() {
  final now = DateTime(2026, 9, 25, 14);
  const startLabel = 'Lancer le minuteur (30 + 12 min)';
  late MockEventsRepository repo;
  late StreamController<DateTime> ticks;
  late _MutableClock clock;
  late FakeDeviceFeedback feedback;
  late InMemoryBottleTimerSessionRepository sessions;

  setUpAll(() => registerFallbackValue(makeEvent(startAt: DateTime(2026))));

  setUp(() {
    repo = MockEventsRepository();
    when(() => repo.save(any(), any())).thenAnswer((_) async => right(null));
    ticks = StreamController<DateTime>.broadcast();
    clock = _MutableClock(now);
    feedback = FakeDeviceFeedback();
    sessions = InMemoryBottleTimerSessionRepository();
  });

  tearDown(() => ticks.close());

  Future<void> openSheet(
    WidgetTester tester, {
    BottleTimerSession? restored,
  }) async {
    await pumpApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showEventFormSheet(context, restored: restored),
            child: const Text('ouvrir'),
          ),
        ),
      ),
      viewSize: const Size(430, 1400),
      overrides: [
        eventsRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(clock),
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
        deviceFeedbackProvider.overrideWithValue(feedback),
        bottleTimerSessionRepositoryProvider.overrideWithValue(sessions),
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
    expect(feedback.calls, ['screen:on', 'screen:off', 'screen:off']);
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

  testWidgets('le bouton Fermer ferme le formulaire', (tester) async {
    await openSheet(tester);
    await tester.tap(find.byTooltip('Fermer'));
    await tester.pumpAndSettle();
    expect(find.byType(EventFormSheet), findsNothing);
    verifyNever(() => repo.save(any(), any()));
  });

  testWidgets('le bouton Fermer demande confirmation si le minuteur tourne', (
    tester,
  ) async {
    await openSheet(tester);
    await enableBottleAndStart(tester);
    await tester.tap(find.byTooltip('Fermer'));
    await tester.pumpAndSettle();
    expect(find.text('Arrêter le minuteur ?'), findsOneWidget);
  });

  Future<void> advanceTo(WidgetTester tester, Duration elapsed) async {
    clock.current = now.add(elapsed);
    ticks.add(clock.current);
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets(
    'fin du minuteur : enregistre avec les heures du minuteur et ferme',
    (tester) async {
      await openSheet(tester);
      clock.current = now.add(const Duration(minutes: 2));
      await enableBottleAndStart(tester);

      await advanceTo(tester, const Duration(minutes: 44));

      final saved =
          verify(() => repo.save('ABCDEFGH', captureAny())).captured.single
              as CareEvent;
      expect(saved.startAt, now.add(const Duration(minutes: 2)));
      expect(saved.endAt, now.add(const Duration(minutes: 32)));
      expect(saved.bottleMl, 120);
      expect(find.byType(EventFormSheet), findsNothing);
      expect(feedback.calls, contains('sound:uprightEnded'));
    },
  );

  testWidgets('avec « Biberon terminé », la fin du soin est ce moment-là', (
    tester,
  ) async {
    await openSheet(tester);
    await enableBottleAndStart(tester);
    clock.current = now.add(const Duration(minutes: 12));
    await tester.tap(find.text('Biberon terminé'));
    await tester.pump();

    await advanceTo(tester, const Duration(minutes: 24));

    final saved =
        verify(() => repo.save('ABCDEFGH', captureAny())).captured.single
            as CareEvent;
    expect(saved.startAt, now);
    expect(saved.endAt, now.add(const Duration(minutes: 12)));
    expect(find.byType(EventFormSheet), findsNothing);
  });

  testWidgets('fin du biberon : le formulaire prend les heures du minuteur', (
    tester,
  ) async {
    await openSheet(tester);
    clock.current = now.add(const Duration(minutes: 2));
    await enableBottleAndStart(tester);

    await advanceTo(tester, const Duration(minutes: 33));

    expect(find.text('Biberon terminé'), findsNothing);
    expect(find.text('14h02'), findsOneWidget);
    expect(find.text('14h32'), findsOneWidget);
    expect(
      sessions.session?.draft.startAt,
      now.add(const Duration(minutes: 2)),
    );
    expect(sessions.session?.draft.endAt, now.add(const Duration(minutes: 32)));
    verifyNever(() => repo.save(any(), any()));
  });

  testWidgets('« Biberon terminé » met à jour la fin dans le formulaire', (
    tester,
  ) async {
    await openSheet(tester);
    await enableBottleAndStart(tester);
    clock.current = now.add(const Duration(minutes: 12));
    await tester.tap(find.text('Biberon terminé'));
    await tester.pump();

    expect(find.text('14h00'), findsOneWidget);
    expect(find.text('14h12'), findsOneWidget);
    expect(sessions.session?.draft.endAt, now.add(const Duration(minutes: 12)));

    final save = find.widgetWithText(FilledButton, 'Enregistrer');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    final saved =
        verify(() => repo.save('ABCDEFGH', captureAny())).captured.single
            as CareEvent;
    expect(saved.endAt, now.add(const Duration(minutes: 12)));
  });

  BottleTimerSession restoredSession({
    required Duration startedAgo,
    bool editing = false,
  }) {
    final run = BottleTimerRun.startingAt(now.subtract(startedAgo));
    return BottleTimerSession(
      run: run,
      draft: makeEvent(id: 'e-old', startAt: run.startedAt, bottleMl: 90),
      editing: editing,
    );
  }

  testWidgets('pendant le minuteur, le brouillon est sauvegardé', (
    tester,
  ) async {
    await openSheet(tester);
    await enableBottleAndStart(tester);
    expect(sessions.session?.run.startedAt, now);
    expect(sessions.session?.draft.bottleMl, 120);
    expect(sessions.session?.editing, isFalse);
    await tester.tap(find.text('Pipi'));
    await tester.pump();
    expect(sessions.session?.draft.pee, isTrue);
    await tester.enterText(find.byType(TextField), 'rot');
    expect(sessions.session?.draft.note, 'rot');
  });

  testWidgets('session reprise en cours : minuteur et brouillon restaurés', (
    tester,
  ) async {
    final session = restoredSession(startedAgo: const Duration(minutes: 10));
    await openSheet(tester, restored: session);
    expect(find.text('Biberon terminé'), findsOneWidget);
    expect(find.text('Nouvel événement'), findsOneWidget);
    verifyNever(() => repo.save(any(), any()));

    final save = find.widgetWithText(FilledButton, 'Enregistrer');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    final saved =
        verify(() => repo.save('ABCDEFGH', captureAny())).captured.single
            as CareEvent;
    expect(saved.id, 'e-old');
    expect(saved.bottleMl, 90);
  });

  testWidgets('session reprise terminée : soin enregistré et feuille fermée', (
    tester,
  ) async {
    final session = restoredSession(startedAgo: const Duration(minutes: 50));
    await openSheet(tester, restored: session);
    final saved =
        verify(() => repo.save('ABCDEFGH', captureAny())).captured.single
            as CareEvent;
    expect(saved.startAt, session.run.startedAt);
    expect(saved.endAt, session.run.feedingEndsAt);
    expect(saved.bottleMl, 90);
    expect(find.byType(EventFormSheet), findsNothing);
    expect(feedback.calls, isNot(contains('sound:uprightEnded')));
    expect(sessions.session, isNull);
  });

  testWidgets('session reprise à la verticale : heures du minuteur reprises', (
    tester,
  ) async {
    final session = restoredSession(startedAgo: const Duration(minutes: 35));
    await openSheet(tester, restored: session);
    expect(find.text(formatHourMinute(session.run.startedAt)), findsOneWidget);
    expect(
      find.text(formatHourMinute(session.run.feedingEndsAt)),
      findsOneWidget,
    );
    verifyNever(() => repo.save(any(), any()));
  });

  testWidgets('session reprise en édition : titre de modification', (
    tester,
  ) async {
    await openSheet(
      tester,
      restored: restoredSession(startedAgo: Duration.zero, editing: true),
    );
    expect(find.text("Modifier l'événement"), findsOneWidget);
  });
}
