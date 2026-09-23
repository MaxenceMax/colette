import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/domain/reference/medical_schedule.dart';
import 'package:colette/features/health/presentation/widgets/health_status_text.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../health_factories.dart';

void main() {
  final s = lookupS(const Locale('fr'));

  MedicalTimelineEntry entryFor(
    MedicalStageStatus status, {
    bool visit = true,
  }) => MedicalTimelineEntry(
    stage: stageById(MedicalStageId.m2),
    dueFrom: DateTime(2026, 11, 1),
    dueUntil: DateTime(2026, 12, 1),
    status: status,
    visit: visit
        ? switch (status) {
            MedicalStageStatus.done => makeVisit(
              MedicalStageId.m2,
              doneAt: DateTime(2026, 9, 4),
            ),
            MedicalStageStatus.appointmentPassed => makeVisit(
              MedicalStageId.m2,
              appointmentAt: DateTime(2026, 9, 4, 10),
            ),
            MedicalStageStatus.scheduled => makeVisit(
              MedicalStageId.m2,
              appointmentAt: DateTime(2026, 11, 3, 10),
              practitioner: 'Dr Martin',
            ),
            _ => null,
          }
        : null,
  );

  test('done : date de la visite', () {
    expect(
      healthStatusText(s, entryFor(MedicalStageStatus.done)),
      'Faite le 4 sept. 2026',
    );
  });

  test('appointmentPassed : RDV passé', () {
    expect(
      healthStatusText(s, entryFor(MedicalStageStatus.appointmentPassed)),
      'RDV du 4 sept. 2026 passé · à marquer comme faite',
    );
  });

  test('scheduled avec praticien', () {
    expect(
      healthStatusText(s, entryFor(MedicalStageStatus.scheduled)),
      'RDV le mar. 3 nov., 10h00 · Dr Martin',
    );
  });

  test('scheduled sans praticien', () {
    final entry = MedicalTimelineEntry(
      stage: stageById(MedicalStageId.m2),
      dueFrom: DateTime(2026, 11, 1),
      dueUntil: DateTime(2026, 12, 1),
      status: MedicalStageStatus.scheduled,
      visit: makeVisit(
        MedicalStageId.m2,
        appointmentAt: DateTime(2026, 11, 3, 10),
      ),
    );
    expect(healthStatusText(s, entry), 'RDV le mar. 3 nov., 10h00');
  });

  test('late : en retard depuis la fin de fenêtre', () {
    expect(
      healthStatusText(s, entryFor(MedicalStageStatus.late)),
      'En retard depuis le 1 déc. 2026',
    );
  });

  test('due : fenêtre de l\'étape', () {
    expect(
      healthStatusText(s, entryFor(MedicalStageStatus.due)),
      'À faire du 1 nov. 2026 au 30 nov. 2026',
    );
  });

  test('upcoming : fenêtre de l\'étape', () {
    expect(
      healthStatusText(s, entryFor(MedicalStageStatus.upcoming)),
      'À faire du 1 nov. 2026 au 30 nov. 2026',
    );
  });

  test('incohérence : done sans visite se rabat sur la fenêtre', () {
    expect(
      healthStatusText(s, entryFor(MedicalStageStatus.done, visit: false)),
      'À faire du 1 nov. 2026 au 30 nov. 2026',
    );
  });
}
