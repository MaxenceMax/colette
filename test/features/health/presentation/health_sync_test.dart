import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/health/domain/entities/calendar_choice.dart';
import 'package:colette/features/health/domain/entities/calendar_event.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/repositories/calendar_repository.dart';
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

void main() {
  const code = 'ABCDEFGH';
  final now = DateTime(2026, 10, 20, 12);
  late FakeFirebaseFirestore db;
  late MockCalendarRepository calendar;

  setUpAll(() {
    registerFallbackValue(
      CalendarEventDraft(url: '', title: '', start: now, end: now),
    );
  });

  Future<ProviderContainer> container({String? calendarId}) async {
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

  test('medicalVisitsProvider lit les visites du foyer', () async {
    final c = await container();
    await c
        .read(medicalRepositoryProvider)
        .saveVisit(code, makeVisit(MedicalStageId.m2, note: 'x'));
    final sub = c.listen(medicalVisitsProvider, (_, _) {});
    addTearDown(sub.close);
    expect(
      (await c.read(medicalVisitsProvider.future)).single.stageId,
      MedicalStageId.m2,
    );
  });

  test('CalendarChoice est une valeur', () {
    expect(
      const CalendarChoice(id: 'a', title: 'b'),
      const CalendarChoice(id: 'a', title: 'b'),
    );
  });
}
