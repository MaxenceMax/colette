import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/widgets/medical_stage_tile.dart';
import 'package:colette/features/health/presentation/widgets/to_schedule_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../health_factories.dart';

void main() {
  testWidgets(
    'lignes compactes : retard en warning, fenêtre courte, sans pastille',
    (tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: ListView(
            children: [
              ToScheduleSection(
                items: [
                  MedicalTimelineItem.stage(
                    entry(MedicalStageId.week2, MedicalStageStatus.late),
                  ),
                  MedicalTimelineItem.stage(
                    entry(MedicalStageId.m2, MedicalStageStatus.due),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      expect(find.text('À programmer'), findsOneWidget);
      expect(find.text('Examen de la 2e semaine'), findsOneWidget);
      expect(find.text('en retard'), findsOneWidget);
      expect(find.text('Examen et vaccins des 2 mois'), findsOneWidget);
      expect(find.text('du 1 nov. au 30 nov.'), findsOneWidget);
      expect(find.byType(MedicalChip), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
      final late = tester.widget<Text>(find.text('en retard'));
      expect(late.style?.color, AppColors.warning.light);
    },
  );

  testWidgets('hauteur tactile minimale de 48 pt', (tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: ToScheduleSection(
          items: [
            MedicalTimelineItem.stage(
              entry(MedicalStageId.m2, MedicalStageStatus.due),
            ),
          ],
        ),
      ),
    );
    final height = tester.getSize(find.byType(CompactStageRow)).height;
    expect(height, greaterThanOrEqualTo(AppSize.xl.value));
  });

  testWidgets('rien si vide', (tester) async {
    await pumpApp(tester, const Scaffold(body: ToScheduleSection(items: [])));
    expect(find.text('À programmer'), findsNothing);
  });

  testWidgets('tap : ouvre la feuille de l\'étape', (tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: ToScheduleSection(
          items: [
            MedicalTimelineItem.stage(
              entry(MedicalStageId.m2, MedicalStageStatus.due),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Examen et vaccins des 2 mois'));
    await tester.pumpAndSettle();
    expect(find.text('Rendez-vous'), findsWidgets);
  });
}
