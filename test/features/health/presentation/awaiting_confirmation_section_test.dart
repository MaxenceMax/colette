import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/widgets/awaiting_confirmation_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../health_factories.dart';

void main() {
  testWidgets('étape et RDV libre passés, statut en warning', (tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: ListView(
          children: [
            AwaitingConfirmationSection(
              items: [
                MedicalTimelineItem.stage(
                  entry(
                    MedicalStageId.m1,
                    MedicalStageStatus.appointmentPassed,
                    appointmentAt: DateTime(2026, 9, 18, 9),
                  ),
                ),
                AppointmentItem(
                  makeAppointment(appointmentAt: DateTime(2026, 9, 10, 9)),
                  MedicalStageStatus.appointmentPassed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
    expect(find.text('RDV passé, à confirmer'), findsOneWidget);
    expect(find.text('Examen du 1er mois'), findsOneWidget);
    expect(find.text('Ostéopathe'), findsOneWidget);
    final stageStatus = tester.widget<Text>(
      find.text('RDV du 18 sept. 2026 passé · à marquer comme faite'),
    );
    final rdvStatus = tester.widget<Text>(
      find.text('RDV du 10 sept. 2026 passé · à marquer comme faite'),
    );
    expect(stageStatus.style?.color, AppColors.warning.light);
    expect(rdvStatus.style?.color, AppColors.warning.light);
  });

  testWidgets('rien si vide', (tester) async {
    await pumpApp(
      tester,
      const Scaffold(body: AwaitingConfirmationSection(items: [])),
    );
    expect(find.text('RDV passé, à confirmer'), findsNothing);
  });
}
