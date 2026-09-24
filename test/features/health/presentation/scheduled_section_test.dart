import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/widgets/scheduled_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../health_factories.dart';

void main() {
  Future<void> pumpSection(
    WidgetTester tester,
    List<MedicalTimelineItem> items,
  ) => pumpApp(
    tester,
    Scaffold(
      body: ListView(children: [ScheduledSection(items: items)]),
    ),
  );

  testWidgets('rien avec moins de deux RDV programmés', (tester) async {
    await pumpSection(tester, [
      MedicalTimelineItem.stage(
        entry(
          MedicalStageId.m2,
          MedicalStageStatus.scheduled,
          appointmentAt: DateTime(2026, 11, 3, 10),
        ),
      ),
    ]);
    expect(find.text('Aussi programmés'), findsNothing);
  });

  testWidgets('liste les RDV sauf le premier, avec bloc date et détail', (
    tester,
  ) async {
    await pumpSection(tester, [
      MedicalTimelineItem.stage(
        entry(
          MedicalStageId.m2,
          MedicalStageStatus.scheduled,
          appointmentAt: DateTime(2026, 11, 3, 10),
        ),
      ),
      AppointmentItem(
        makeAppointment(id: 'osteo', appointmentAt: DateTime(2026, 11, 14, 15)),
        MedicalStageStatus.scheduled,
      ),
      MedicalTimelineItem.stage(
        entry(
          MedicalStageId.m3,
          MedicalStageStatus.scheduled,
          appointmentAt: DateTime(2026, 12, 2, 9, 30),
          practitioner: 'Dr Martin',
        ),
      ),
    ]);
    expect(find.text('Aussi programmés'), findsOneWidget);
    expect(find.text('Examen et vaccins des 2 mois'), findsNothing);
    expect(find.text('14'), findsOneWidget);
    expect(find.text('nov.'), findsOneWidget);
    expect(find.text('Ostéopathe'), findsOneWidget);
    expect(find.text('15h00 · RDV libre'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('déc.'), findsOneWidget);
    expect(find.text('09h30 · Dr Martin'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
  });
}
