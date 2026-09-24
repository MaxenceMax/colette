import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../health_factories.dart';

void main() {
  AppointmentItem custom(
    String id,
    DateTime at,
    MedicalStageStatus status, {
    String? practitioner,
  }) => AppointmentItem(
    makeAppointment(id: id, appointmentAt: at, practitioner: practitioner),
    status,
  );

  group('MedicalTimelineItem', () {
    test('appointmentAt : RDV de la visite ou date du RDV libre', () {
      final stage = MedicalTimelineItem.stage(
        entry(
          MedicalStageId.m2,
          MedicalStageStatus.scheduled,
          appointmentAt: DateTime(2026, 11, 3, 10),
        ),
      );
      final noVisit = MedicalTimelineItem.stage(
        entry(MedicalStageId.m2, MedicalStageStatus.due),
      );
      final rdv = custom('a', DateTime(2026, 10, 15, 9), .scheduled);
      expect(stage.appointmentAt, DateTime(2026, 11, 3, 10));
      expect(noVisit.appointmentAt, isNull);
      expect(rdv.appointmentAt, DateTime(2026, 10, 15, 9));
    });

    test('practitioner : null si absent ou vide', () {
      final withName = MedicalTimelineItem.stage(
        entry(
          MedicalStageId.m2,
          MedicalStageStatus.scheduled,
          appointmentAt: DateTime(2026, 11, 3, 10),
          practitioner: '  Dr Martin ',
        ),
      );
      final blank = custom(
        'a',
        DateTime(2026, 10, 15, 9),
        .scheduled,
        practitioner: '   ',
      );
      expect(withName.practitioner, 'Dr Martin');
      expect(blank.practitioner, isNull);
    });
  });

  group('MedicalTimeline', () {
    final timeline = MedicalTimeline(
      entries: [
        entry(MedicalStageId.day8, MedicalStageStatus.done),
        entry(MedicalStageId.week2, MedicalStageStatus.late),
        entry(
          MedicalStageId.m1,
          MedicalStageStatus.appointmentPassed,
          appointmentAt: DateTime(2026, 9, 18, 9),
        ),
        entry(
          MedicalStageId.m2,
          MedicalStageStatus.scheduled,
          appointmentAt: DateTime(2026, 11, 3, 10),
        ),
        entry(MedicalStageId.m3, MedicalStageStatus.due),
        entry(MedicalStageId.m4, MedicalStageStatus.upcoming),
      ],
      appointments: [
        custom('osteo', DateTime(2026, 10, 15, 9), .scheduled),
        custom('orl', DateTime(2026, 11, 3, 10), .scheduled),
        custom('passe', DateTime(2026, 9, 10, 9), .appointmentPassed),
      ],
    );

    test('scheduled : par date, puis ordre de la frise à date égale', () {
      final ids = [
        for (final i in timeline.scheduled)
          switch (i) {
            StageItem(:final entry) => entry.stage.id.name,
            AppointmentItem(:final appointment) => appointment.id,
          },
      ];
      // Toutes les entrées de la fabrique ont dueFrom = 1er nov. : « osteo »
      // (15 oct.) est inséré avant, « orl » (3 nov.) après les étapes. À date
      // égale (m2 et orl, 3 nov. 10h00), l'ordre de `items` est gardé.
      expect(ids, ['osteo', 'm2', 'orl']);
    });

    test('nextAppointment : le premier programmé, ou null', () {
      expect(
        timeline.nextAppointment?.appointmentAt,
        DateTime(2026, 10, 15, 9),
      );
      expect(const MedicalTimeline(entries: []).nextAppointment, isNull);
    });

    test('awaitingConfirmation : RDV passés par date', () {
      expect(timeline.awaitingConfirmation.map((i) => i.appointmentAt), [
        DateTime(2026, 9, 10, 9),
        DateTime(2026, 9, 18, 9),
      ]);
    });

    test('toSchedule : retards puis à faire, ordre de la frise', () {
      expect(timeline.toSchedule.map((i) => (i as StageItem).entry.stage.id), [
        MedicalStageId.week2,
        MedicalStageId.m3,
      ]);
    });

    test('upcoming et done', () {
      expect(timeline.upcoming.map((i) => (i as StageItem).entry.stage.id), [
        MedicalStageId.m4,
      ]);
      expect(timeline.done.map((i) => (i as StageItem).entry.stage.id), [
        MedicalStageId.day8,
      ]);
    });
  });
}
