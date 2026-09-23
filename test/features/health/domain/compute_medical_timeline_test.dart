import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/domain/use_cases/compute_medical_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../health_factories.dart';

void main() {
  const compute = ComputeMedicalTimeline();
  final birth = DateTime(2026, 9, 1);

  test('une entrée par étape, avec dates absolues et visite', () {
    final visit = makeVisit(MedicalStageId.day8, doneAt: DateTime(2026, 9, 4));
    final timeline = compute(
      birthDate: birth,
      visits: [visit],
      now: DateTime(2026, 9, 10),
    );
    expect(timeline.entries, hasLength(MedicalStageId.values.length));
    final day8 = timeline.entries.first;
    expect(day8.stage.id, MedicalStageId.day8);
    expect(day8.visit, visit);
    expect(day8.status, MedicalStageStatus.done);
    final week2 = timeline.entries[1];
    expect(week2.dueFrom, DateTime(2026, 9, 9));
    expect(week2.dueUntil, DateTime(2026, 9, 16));
    expect(week2.status, MedicalStageStatus.due);
  });

  test('next : première étape non faite', () {
    final timeline = compute(
      birthDate: birth,
      visits: [
        makeVisit(MedicalStageId.day8, doneAt: DateTime(2026, 9, 4)),
        makeVisit(MedicalStageId.week2, doneAt: DateTime(2026, 9, 12)),
      ],
      now: DateTime(2026, 9, 20),
    );
    final next = timeline.next! as StageItem;
    expect(next.entry.stage.id, MedicalStageId.m1);
    expect(next.status, MedicalStageStatus.due);
  });

  test('next : null quand tout est fait', () {
    final timeline = compute(
      birthDate: birth,
      visits: [
        for (final id in MedicalStageId.values)
          makeVisit(id, doneAt: DateTime(2026, 9, 2)),
      ],
      now: DateTime(2030),
    );
    expect(timeline.next, isNull);
  });

  group('items : RDV libres mêlés aux étapes', () {
    MedicalStageId? stageOf(MedicalTimelineItem item) => switch (item) {
      StageItem(:final entry) => entry.stage.id,
      AppointmentItem() => null,
    };

    test('sans RDV libre, items = étapes dans l\'ordre', () {
      final timeline = compute(
        birthDate: birth,
        visits: const [],
        now: DateTime(2026, 9, 10),
      );
      expect(timeline.appointments, isEmpty);
      expect(timeline.items.map(stageOf), MedicalStageId.values);
    });

    test('un RDV libre s\'insère avant la première étape postérieure', () {
      // m1 commence le 1er octobre, m2 le 1er novembre.
      final rdv = makeAppointment(appointmentAt: DateTime(2026, 10, 15, 9));
      final timeline = compute(
        birthDate: birth,
        visits: const [],
        appointments: [rdv],
        now: DateTime(2026, 9, 10),
      );
      final index = timeline.items.indexWhere(
        (i) => i is AppointmentItem && i.appointment.id == rdv.id,
      );
      expect(stageOf(timeline.items[index - 1]), MedicalStageId.m1);
      expect(stageOf(timeline.items[index + 1]), MedicalStageId.m2);
      expect(timeline.items[index].status, MedicalStageStatus.scheduled);
      expect(timeline.items[index].anchorDate, rdv.appointmentAt);
    });

    test('un RDV libre le jour du début d\'une étape passe après elle', () {
      final rdv = makeAppointment(appointmentAt: DateTime(2026, 11, 1, 9));
      final timeline = compute(
        birthDate: birth,
        visits: const [],
        appointments: [rdv],
        now: DateTime(2026, 9, 10),
      );
      final index = timeline.items.indexWhere((i) => i is AppointmentItem);
      expect(stageOf(timeline.items[index - 1]), MedicalStageId.m2);
      expect(stageOf(timeline.items[index + 1]), MedicalStageId.m3);
    });

    test('un RDV libre après la dernière étape va en fin de liste', () {
      final timeline = compute(
        birthDate: birth,
        visits: const [],
        appointments: [makeAppointment(appointmentAt: DateTime(2031, 1, 1))],
        now: DateTime(2026, 9, 10),
      );
      expect(timeline.items.last, isA<AppointmentItem>());
    });

    test('deux RDV libres : ordre chronologique puis identifiant', () {
      final timeline = compute(
        birthDate: birth,
        visits: const [],
        appointments: [
          makeAppointment(id: 'b', appointmentAt: DateTime(2026, 10, 15, 9)),
          makeAppointment(id: 'a', appointmentAt: DateTime(2026, 10, 15, 9)),
          makeAppointment(id: 'c', appointmentAt: DateTime(2026, 10, 14, 9)),
        ],
        now: DateTime(2026, 9, 10),
      );
      final ids = [
        for (final item in timeline.items)
          if (item case AppointmentItem(:final appointment)) appointment.id,
      ];
      expect(ids, ['c', 'a', 'b']);
    });

    test('next : un RDV libre non fait passe avant une étape non faite', () {
      final rdv = makeAppointment(appointmentAt: DateTime(2026, 9, 5, 9));
      final timeline = compute(
        birthDate: birth,
        visits: [makeVisit(MedicalStageId.day8, doneAt: DateTime(2026, 9, 4))],
        appointments: [rdv],
        now: DateTime(2026, 9, 10),
      );
      expect(timeline.next, isA<AppointmentItem>());
    });

    test('next : un RDV libre fait est ignoré', () {
      final rdv = makeAppointment(
        appointmentAt: DateTime(2026, 9, 5, 9),
        doneAt: DateTime(2026, 9, 5),
      );
      final timeline = compute(
        birthDate: birth,
        visits: [makeVisit(MedicalStageId.day8, doneAt: DateTime(2026, 9, 4))],
        appointments: [rdv],
        now: DateTime(2026, 9, 10),
      );
      expect(stageOf(timeline.next!), MedicalStageId.week2);
    });
  });
}
