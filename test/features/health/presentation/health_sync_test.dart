import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/health/domain/entities/calendar_choice.dart';
import 'package:colette/features/health/domain/entities/calendar_event.dart';
import 'package:colette/features/health/domain/entities/medical_reminder_snapshot.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/repositories/calendar_repository.dart';
import 'package:colette/features/health/domain/repositories/medical_repository.dart';
import 'package:colette/features/health/domain/use_cases/reconcile_calendar.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/health/presentation/providers/selected_calendar.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../health_factories.dart';

class MockCalendarRepository extends Mock implements CalendarRepository {}

class MockMedicalRepository extends Mock implements MedicalRepository {}

void main() {
  const code = 'ABCDEFGH';
  final now = DateTime(2026, 10, 20, 12);
  late FakeFirebaseFirestore db;
  late MockCalendarRepository calendar;

  setUpAll(() {
    registerFallbackValue(
      CalendarEventDraft(url: '', title: '', start: now, end: now),
    );
    registerFallbackValue(
      MedicalReminderSnapshot(stages: const [], computedAt: now),
    );
  });

  Future<ProviderContainer> container({
    String? calendarId,
    MedicalRepository? medicalRepository,
  }) async {
    SharedPreferences.setMockInitialValues({
      SelectedCalendar.idKey: ?calendarId,
      if (calendarId != null) SelectedCalendar.titleKey: 'Famille',
    });
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(FixedClock(now)),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: code),
        ),
        calendarRepositoryProvider.overrideWithValue(calendar),
        if (medicalRepository != null)
          medicalRepositoryProvider.overrideWithValue(medicalRepository),
      ],
    );
    addTearDown(c.dispose);
    await c
        .read(babyRepositoryProvider)
        .saveProfile(
          code,
          BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1)),
        );
    return c;
  }

  setUp(() {
    db = FakeFirebaseFirestore();
    calendar = MockCalendarRepository();
  });

  test('écrit le snapshot des rappels, sans calendrier choisi', () async {
    final c = await container();
    await c.read(healthSyncProvider).sync();
    final data = (await db.collection('households').doc(code).get()).data()!;
    final stages =
        (data['medicalReminder'] as Map<String, dynamic>)['stages'] as List;
    expect((stages.first as Map)['stageId'], 'day8');
    verifyZeroInteractions(calendar);
  });

  test('crée l\'événement d\'un RDV dans le calendrier choisi', () async {
    final c = await container(calendarId: 'c1');
    await c
        .read(medicalRepositoryProvider)
        .saveVisit(
          code,
          makeVisit(
            MedicalStageId.m2,
            appointmentAt: DateTime(2026, 11, 3, 10),
          ),
        );
    when(
      () => calendar.findEvents(
        'c1',
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => right(const <CalendarEvent>[]));
    when(
      () => calendar.upsertEvent(
        'c1',
        eventId: any(named: 'eventId'),
        draft: any(named: 'draft'),
      ),
    ).thenAnswer((_) async => right('e1'));

    await c.read(healthSyncProvider).sync();

    final draft =
        verify(
              () => calendar.upsertEvent(
                'c1',
                eventId: null,
                draft: captureAny(named: 'draft'),
              ),
            ).captured.single
            as CalendarEventDraft;
    expect(draft.title, 'Examen et vaccins des 2 mois · Colette');
    expect(draft.url, 'colette://rdv/m2');
  });

  test('met à jour un événement dont le RDV a changé d\'heure', () async {
    final c = await container(calendarId: 'c1');
    await c
        .read(medicalRepositoryProvider)
        .saveVisit(
          code,
          makeVisit(
            MedicalStageId.m2,
            appointmentAt: DateTime(2026, 11, 3, 10),
          ),
        );
    when(
      () => calendar.findEvents(
        'c1',
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer(
      (_) async => right([
        CalendarEvent(
          eventId: 'e1',
          url: ReconcileCalendar.urlOf(MedicalStageId.m2),
          title: 'Ancien titre',
          start: DateTime(2026, 11, 3, 9),
          end: DateTime(2026, 11, 3, 9, 30),
        ),
      ]),
    );
    when(
      () => calendar.upsertEvent(
        'c1',
        eventId: any(named: 'eventId'),
        draft: any(named: 'draft'),
      ),
    ).thenAnswer((_) async => right('e1'));

    await c.read(healthSyncProvider).sync();

    verify(
      () => calendar.upsertEvent(
        'c1',
        eventId: 'e1',
        draft: any(named: 'draft'),
      ),
    ).called(1);
  });

  test('supprime un événement orphelin', () async {
    final c = await container(calendarId: 'c1');
    when(
      () => calendar.findEvents(
        'c1',
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer(
      (_) async => right([
        CalendarEvent(
          eventId: 'orphan',
          url: '${ReconcileCalendar.urlPrefix}m3',
          title: 'x',
          start: DateTime(2026, 11, 3, 9),
          end: DateTime(2026, 11, 3, 9, 30),
        ),
      ]),
    );
    when(() => calendar.deleteEvent('c1', 'orphan'))
        .thenAnswer((_) async => right(null));

    await c.read(healthSyncProvider).sync();

    verify(() => calendar.deleteEvent('c1', 'orphan')).called(1);
  });

  test('calendrier introuvable : choix local effacé', () async {
    final c = await container(calendarId: 'gone');
    when(
      () => calendar.findEvents(
        'gone',
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer(
      (_) async => left(const CalendarFailure(CalendarReason.calendarNotFound)),
    );
    await c.read(healthSyncProvider).sync();
    expect(c.read(selectedCalendarProvider), isNull);
  });

  test('accès refusé : le choix local n\'est pas effacé', () async {
    final c = await container(calendarId: 'c1');
    when(
      () => calendar.findEvents(
        'c1',
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer(
      (_) async => left(const CalendarFailure(CalendarReason.accessDenied)),
    );

    await c.read(healthSyncProvider).sync();

    expect(c.read(selectedCalendarProvider)?.id, 'c1');
  });

  test(
    'calendrier introuvable : le choix changé entre-temps est conservé',
    () async {
      final c = await container(calendarId: 'old');
      final findCalled = Completer<void>();
      final result = Completer<Either<Failure, List<CalendarEvent>>>();
      when(
        () => calendar.findEvents(
          'old',
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) {
        if (!findCalled.isCompleted) findCalled.complete();
        return result.future;
      });

      final syncFuture = c.read(healthSyncProvider).sync();
      // Attend que la sync ait lu l'ancien choix et lancé `findEvents`
      // avant de le changer, pour reproduire la course décrite.
      await findCalled.future;
      await c
          .read(selectedCalendarProvider.notifier)
          .choose(const CalendarChoice(id: 'new', title: 'Nouveau'));
      result.complete(
        left(const CalendarFailure(CalendarReason.calendarNotFound)),
      );
      await syncFuture;

      expect(
        c.read(selectedCalendarProvider),
        const CalendarChoice(id: 'new', title: 'Nouveau'),
      );
    },
  );

  test('un échec io n\'arrête pas les actions suivantes', () async {
    final c = await container(calendarId: 'c1');
    await c
        .read(medicalRepositoryProvider)
        .saveVisit(
          code,
          makeVisit(
            MedicalStageId.m2,
            appointmentAt: DateTime(2026, 11, 3, 10),
          ),
        );
    await c
        .read(medicalRepositoryProvider)
        .saveVisit(
          code,
          makeVisit(
            MedicalStageId.m3,
            appointmentAt: DateTime(2026, 11, 4, 10),
          ),
        );
    when(
      () => calendar.findEvents(
        'c1',
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => right(const <CalendarEvent>[]));
    when(
      () => calendar.upsertEvent(
        'c1',
        eventId: any(named: 'eventId'),
        draft: any(named: 'draft'),
      ),
    ).thenAnswer((invocation) async {
      final draft = invocation.namedArguments[#draft] as CalendarEventDraft;
      return draft.url == ReconcileCalendar.urlOf(MedicalStageId.m2)
          ? left(const CalendarFailure(CalendarReason.io))
          : right('e-m3');
    });

    await c.read(healthSyncProvider).sync();

    verify(
      () =>
          calendar.upsertEvent('c1', eventId: null, draft: any(named: 'draft')),
    ).called(2);
    expect(c.read(selectedCalendarProvider)?.id, 'c1');
  });

  test(
    'coalesce les synchronisations concurrentes sans double création',
    () async {
      final c = await container(calendarId: 'c1');
      await c
          .read(medicalRepositoryProvider)
          .saveVisit(
            code,
            makeVisit(
              MedicalStageId.m2,
              appointmentAt: DateTime(2026, 11, 3, 10),
            ),
          );

      final findCompleter = Completer<Either<Failure, List<CalendarEvent>>>();
      var findCalls = 0;
      CalendarEventDraft? created;
      when(
        () => calendar.findEvents(
          'c1',
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) {
        findCalls++;
        if (findCalls == 1) return findCompleter.future;
        final draft = created!;
        return Future.value(
          right([
            CalendarEvent(
              eventId: 'e1',
              url: draft.url,
              title: draft.title,
              start: draft.start,
              end: draft.end,
              notes: draft.notes,
            ),
          ]),
        );
      });
      when(
        () => calendar.upsertEvent(
          'c1',
          eventId: any(named: 'eventId'),
          draft: any(named: 'draft'),
        ),
      ).thenAnswer((invocation) async {
        created = invocation.namedArguments[#draft] as CalendarEventDraft;
        return right('e1');
      });

      final sync = c.read(healthSyncProvider);
      final first = sync.sync();
      final second = sync.sync();

      findCompleter.complete(right(const <CalendarEvent>[]));
      await first;
      await second;

      verify(
        () => calendar.upsertEvent(
          'c1',
          eventId: null,
          draft: any(named: 'draft'),
        ),
      ).called(1);
    },
  );

  test(
    'le calendrier ne dépend pas de l\'accusé du snapshot Firestore',
    () async {
      final repo = MockMedicalRepository();
      final visit = makeVisit(
        MedicalStageId.m2,
        appointmentAt: DateTime(2026, 11, 3, 10),
      );
      when(() => repo.fetchVisitsFromServer(code))
          .thenAnswer((_) async => right([visit]));
      when(() => repo.fetchAppointmentsFromServer(code))
          .thenAnswer((_) async => right(const []));
      when(() => repo.saveReminderSnapshot(any(), any()))
          .thenAnswer((_) => Completer<Either<Failure, void>>().future);
      final c = await container(calendarId: 'c1', medicalRepository: repo);
      when(
        () => calendar.findEvents(
          'c1',
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => right(const <CalendarEvent>[]));
      when(
        () => calendar.upsertEvent(
          'c1',
          eventId: any(named: 'eventId'),
          draft: any(named: 'draft'),
        ),
      ).thenAnswer((_) async => right('e1'));

      await c.read(healthSyncProvider).sync();

      verify(
        () => calendar.upsertEvent(
          'c1',
          eventId: null,
          draft: any(named: 'draft'),
        ),
      ).called(1);
    },
  );

  test('crée l\'événement d\'un RDV libre avec le prénom', () async {
    final c = await container(calendarId: 'c1');
    await c
        .read(medicalRepositoryProvider)
        .saveAppointment(code, makeAppointment(title: 'Ostéopathe'));
    when(
      () => calendar.findEvents(
        'c1',
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => right(const <CalendarEvent>[]));
    when(
      () => calendar.upsertEvent(
        'c1',
        eventId: any(named: 'eventId'),
        draft: any(named: 'draft'),
      ),
    ).thenAnswer((_) async => right('e1'));

    await c.read(healthSyncProvider).sync();

    final draft =
        verify(
              () => calendar.upsertEvent(
                'c1',
                eventId: null,
                draft: captureAny(named: 'draft'),
              ),
            ).captured.single
            as CalendarEventDraft;
    expect(draft.title, 'Ostéopathe · Colette');
    expect(draft.url, 'colette://rdv/custom/rdv-1');
  });

  test('RDV libres injoignables sur le serveur : rien n\'est écrit', () async {
    final repo = MockMedicalRepository();
    when(() => repo.fetchVisitsFromServer(code))
        .thenAnswer((_) async => right(const []));
    when(() => repo.fetchAppointmentsFromServer(code))
        .thenAnswer((_) async => left(const NetworkFailure()));
    final c = await container(calendarId: 'c1', medicalRepository: repo);

    await c.read(healthSyncProvider).sync();

    verifyNever(() => repo.saveReminderSnapshot(any(), any()));
    verifyZeroInteractions(calendar);
  });
}
