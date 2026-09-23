import 'package:colette/features/health/domain/entities/calendar_action.dart';
import 'package:colette/features/health/domain/entities/calendar_event.dart';
import 'package:colette/features/health/domain/entities/custom_appointment.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/use_cases/reconcile_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

import '../health_factories.dart';

void main() {
  const reconcile = ReconcileCalendar();
  final now = DateTime(2026, 10, 20, 12);
  final at = DateTime(2026, 11, 3, 10);
  String titleOf(MedicalStageId id) => 'Titre ${id.name}';

  CalendarEvent event(
    String eventId,
    MedicalStageId stageId, {
    DateTime? start,
    String? title,
    String? notes,
    String? externalId,
  }) {
    final begin = start ?? at;
    return CalendarEvent(
      eventId: eventId,
      url: ReconcileCalendar.urlOf(stageId),
      title: title ?? titleOf(stageId),
      start: begin,
      end: begin.add(ReconcileCalendar.eventDuration),
      notes: notes,
      externalId: externalId,
    );
  }

  CalendarEventDraft draft(
    MedicalStageId stageId, {
    DateTime? start,
    String? notes,
    List<DateTime>? alarms,
  }) {
    final begin = start ?? at;
    return CalendarEventDraft(
      url: ReconcileCalendar.urlOf(stageId),
      title: titleOf(stageId),
      start: begin,
      end: begin.add(ReconcileCalendar.eventDuration),
      notes: notes,
      alarms:
          alarms ??
          [
            DateTime(begin.year, begin.month, begin.day - 1, 18),
            begin.subtract(const Duration(hours: 1)),
          ],
    );
  }

  List<CalendarAction> run(
    List<MedicalVisit> visits,
    List<CalendarEvent> events,
  ) => reconcile(visits: visits, events: events, titleOf: titleOf, now: now);

  test('crée l\'événement d\'un RDV sans événement', () {
    final actions = run([
      makeVisit(
        MedicalStageId.m2,
        appointmentAt: at,
        practitioner: 'Dr Martin',
      ),
    ], []);
    expect(actions, [
      CalendarAction.create(draft(MedicalStageId.m2, notes: 'Dr Martin')),
    ]);
  });

  test('rien à faire si l\'événement est déjà à jour', () {
    expect(
      run(
        [makeVisit(MedicalStageId.m2, appointmentAt: at)],
        [event('e1', MedicalStageId.m2)],
      ),
      isEmpty,
    );
  });

  test(
    'met à jour un événement dont l\'heure, le titre ou les notes diffèrent',
    () {
      expect(
        run(
          [makeVisit(MedicalStageId.m2, appointmentAt: at)],
          [event('e1', MedicalStageId.m2, start: DateTime(2026, 11, 2, 9))],
        ),
        [CalendarAction.update('e1', draft(MedicalStageId.m2))],
      );
      expect(
        run(
          [makeVisit(MedicalStageId.m2, appointmentAt: at)],
          [event('e1', MedicalStageId.m2, title: 'Ancien')],
        ),
        [CalendarAction.update('e1', draft(MedicalStageId.m2))],
      );
      expect(
        run(
          [
            makeVisit(
              MedicalStageId.m2,
              appointmentAt: at,
              practitioner: 'Dr B',
            ),
          ],
          [event('e1', MedicalStageId.m2, notes: 'Dr A')],
        ),
        [CalendarAction.update('e1', draft(MedicalStageId.m2, notes: 'Dr B'))],
      );
    },
  );

  test('supprime les doublons en gardant, à égalité, celui dont l\'eventId est le plus petit', () {
    expect(
      run(
        [makeVisit(MedicalStageId.m2, appointmentAt: at)],
        [event('e1', MedicalStageId.m2), event('e2', MedicalStageId.m2)],
      ),
      [const CalendarAction.delete('e2')],
    );
  });

  test(
    'doublon départagé par externalId, indépendamment de l\'ordre EventKit',
    () {
      for (final events in [
        [
          event('e1', MedicalStageId.m2, externalId: 'b'),
          event('e2', MedicalStageId.m2, externalId: 'a'),
        ],
        [
          event('e2', MedicalStageId.m2, externalId: 'a'),
          event('e1', MedicalStageId.m2, externalId: 'b'),
        ],
      ]) {
        expect(run([makeVisit(MedicalStageId.m2, appointmentAt: at)], events), [
          const CalendarAction.delete('e1'),
        ]);
      }
    },
  );

  test(
    'doublon : garde celui qui a un externalId face à celui qui n\'en a pas',
    () {
      expect(
        run(
          [makeVisit(MedicalStageId.m2, appointmentAt: at)],
          [
            event('e1', MedicalStageId.m2),
            event('e2', MedicalStageId.m2, externalId: 'a'),
          ],
        ),
        [const CalendarAction.delete('e1')],
      );
    },
  );

  test('doublon : met à jour l\'événement gardé puis supprime l\'autre', () {
    expect(
      run(
        [makeVisit(MedicalStageId.m2, appointmentAt: at)],
        [
          event(
            'e1',
            MedicalStageId.m2,
            externalId: 'a',
            title: 'Ancien titre',
          ),
          event('e2', MedicalStageId.m2, externalId: 'b'),
        ],
      ),
      [
        CalendarAction.update('e1', draft(MedicalStageId.m2)),
        const CalendarAction.delete('e2'),
      ],
    );
  });

  test('supprime l\'événement d\'un RDV retiré ou d\'une visite faite', () {
    expect(run([], [event('e1', MedicalStageId.m2)]), [
      const CalendarAction.delete('e1'),
    ]);
    expect(
      run(
        [makeVisit(MedicalStageId.m2, appointmentAt: at, doneAt: now)],
        [event('e1', MedicalStageId.m2)],
      ),
      [const CalendarAction.delete('e1')],
    );
  });

  test('supprime un événement orphelin avec une URL inconnue', () {
    final orphan = CalendarEvent(
      eventId: 'e1',
      url: 'colette://rdv/zzz',
      title: 'Ancien RDV',
      start: at,
      end: at.add(ReconcileCalendar.eventDuration),
    );
    expect(run([], [orphan]), [const CalendarAction.delete('e1')]);
  });

  test('garde un RDV d\'hier, ignore un RDV plus ancien', () {
    final yesterday = DateTime(2026, 10, 19, 9);
    expect(
      run(
        [makeVisit(MedicalStageId.week2, appointmentAt: yesterday)],
        [event('e1', MedicalStageId.week2, start: yesterday)],
      ),
      isEmpty,
    );
    expect(
      run([
        makeVisit(MedicalStageId.day8, appointmentAt: DateTime(2026, 9, 3)),
      ], []),
      isEmpty,
    );
  });

  test('ignore un RDV au-delà de la fenêtre de lecture', () {
    expect(
      run([
        makeVisit(
          MedicalStageId.m2,
          appointmentAt: DateTime(now.year + 3, now.month, now.day),
        ),
      ], []),
      isEmpty,
    );
  });

  test('ignore l\'écart de précision entre Firestore (secondes) et EventKit (minute)', () {
    expect(
      run(
        [
          makeVisit(
            MedicalStageId.m2,
            appointmentAt: DateTime(2026, 11, 3, 10, 0, 37, 123),
          ),
        ],
        [event('e1', MedicalStageId.m2, start: DateTime(2026, 11, 3, 10))],
      ),
      isEmpty,
    );
  });

  test('ne garde que les alertes postérieures à maintenant', () {
    final today20h = DateTime(now.year, now.month, now.day, 20);
    final tomorrow8h = DateTime(now.year, now.month, now.day + 1, 8);
    final actions = reconcile(
      visits: [makeVisit(MedicalStageId.m2, appointmentAt: tomorrow8h)],
      events: const [],
      titleOf: titleOf,
      now: today20h,
    );
    expect(actions, [
      CalendarAction.create(
        draft(
          MedicalStageId.m2,
          start: tomorrow8h,
          alarms: [tomorrow8h.subtract(const Duration(hours: 1))],
        ),
      ),
    ]);
  });

  test('fenêtre de lecture : minuit d\'hier à deux ans', () {
    expect(ReconcileCalendar.windowStart(now), DateTime(2026, 10, 19));
    expect(ReconcileCalendar.windowEnd(now), DateTime(2028, 10, 20));
  });

  group('RDV libres', () {
    CalendarEventDraft customDraft(CustomAppointment a) => CalendarEventDraft(
      url: ReconcileCalendar.customUrlOf(a.id),
      title: '${a.title} · Colette',
      start: a.appointmentAt,
      end: a.appointmentAt.add(ReconcileCalendar.eventDuration),
      notes: a.practitioner,
      alarms: [
        DateTime(
          a.appointmentAt.year,
          a.appointmentAt.month,
          a.appointmentAt.day - 1,
          18,
        ),
        a.appointmentAt.subtract(const Duration(hours: 1)),
      ],
    );

    List<CalendarAction> runWith(
      List<CustomAppointment> appointments,
      List<CalendarEvent> events, [
      List<MedicalVisit> visits = const [],
    ]) => reconcile(
      visits: visits,
      appointments: appointments,
      events: events,
      titleOf: titleOf,
      titleOfAppointment: (a) => '${a.title} · Colette',
      now: now,
    );

    test('crée l\'événement d\'un RDV libre avec son URL dédiée', () {
      final rdv = makeAppointment(practitioner: 'Mme Dupont');
      expect(runWith([rdv], []), [CalendarAction.create(customDraft(rdv))]);
      expect(
        ReconcileCalendar.customUrlOf('rdv-1'),
        'colette://rdv/custom/rdv-1',
      );
    });

    test('met à jour un RDV libre déplacé, garde un RDV à jour', () {
      final rdv = makeAppointment();
      final upToDate = CalendarEvent(
        eventId: 'e1',
        url: ReconcileCalendar.customUrlOf(rdv.id),
        title: 'Ostéopathe · Colette',
        start: rdv.appointmentAt,
        end: rdv.appointmentAt.add(ReconcileCalendar.eventDuration),
      );
      expect(runWith([rdv], [upToDate]), isEmpty);
      final moved = rdv.copyWith(appointmentAt: DateTime(2026, 11, 4, 10));
      expect(runWith([moved], [upToDate]), [
        CalendarAction.update('e1', customDraft(moved)),
      ]);
    });

    test('supprime l\'événement d\'un RDV libre fait ou retiré', () {
      final rdv = makeAppointment(doneAt: DateTime(2026, 11, 3));
      final existing = CalendarEvent(
        eventId: 'e1',
        url: ReconcileCalendar.customUrlOf(rdv.id),
        title: 'x',
        start: at,
        end: at,
      );
      expect(runWith([rdv], [existing]), [const CalendarAction.delete('e1')]);
      expect(runWith([], [existing]), [const CalendarAction.delete('e1')]);
    });

    test('coexiste avec les étapes : une action par RDV', () {
      final rdv = makeAppointment();
      final actions = runWith(
        [rdv],
        [],
        [makeVisit(MedicalStageId.m2, appointmentAt: at)],
      );
      expect(actions, [
        CalendarAction.create(draft(MedicalStageId.m2)),
        CalendarAction.create(customDraft(rdv)),
      ]);
    });

    test('sans titre fourni, le titre du RDV libre est utilisé', () {
      final rdv = makeAppointment();
      final actions = reconcile(
        visits: const [],
        appointments: [rdv],
        events: const [],
        titleOf: titleOf,
        now: now,
      );
      expect((actions.single as CreateCalendarEvent).draft.title, 'Ostéopathe');
    });
  });
}
