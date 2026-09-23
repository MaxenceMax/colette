import 'package:colette/features/health/domain/entities/calendar_action.dart';
import 'package:colette/features/health/domain/entities/calendar_event.dart';
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
  }) {
    final begin = start ?? at;
    return CalendarEvent(
      eventId: eventId,
      url: ReconcileCalendar.urlOf(stageId),
      title: title ?? titleOf(stageId),
      start: begin,
      end: begin.add(ReconcileCalendar.eventDuration),
      notes: notes,
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
      CalendarAction.create(
        CalendarEventDraft(
          url: 'colette://rdv/m2',
          title: 'Titre m2',
          start: at,
          end: at.add(const Duration(minutes: 30)),
          notes: 'Dr Martin',
          alarms: [DateTime(2026, 11, 2, 18), DateTime(2026, 11, 3, 9)],
        ),
      ),
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
      final moved = run(
        [makeVisit(MedicalStageId.m2, appointmentAt: at)],
        [event('e1', MedicalStageId.m2, start: DateTime(2026, 11, 2, 9))],
      );
      expect(moved.single, isA<UpdateCalendarEvent>());
      expect((moved.single as UpdateCalendarEvent).eventId, 'e1');
      final renamed = run(
        [makeVisit(MedicalStageId.m2, appointmentAt: at)],
        [event('e1', MedicalStageId.m2, title: 'Ancien')],
      );
      expect(renamed.single, isA<UpdateCalendarEvent>());
      final newDoctor = run(
        [makeVisit(MedicalStageId.m2, appointmentAt: at, practitioner: 'Dr B')],
        [event('e1', MedicalStageId.m2, notes: 'Dr A')],
      );
      expect(newDoctor.single, isA<UpdateCalendarEvent>());
    },
  );

  test('supprime les doublons en gardant le premier', () {
    expect(
      run(
        [makeVisit(MedicalStageId.m2, appointmentAt: at)],
        [event('e1', MedicalStageId.m2), event('e2', MedicalStageId.m2)],
      ),
      [const CalendarAction.delete('e2')],
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

  test('fenêtre de lecture : minuit d\'hier à deux ans', () {
    expect(ReconcileCalendar.windowStart(now), DateTime(2026, 10, 19));
    expect(ReconcileCalendar.windowEnd(now), DateTime(2028, 10, 20));
  });
}
