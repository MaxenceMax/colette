import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/widgets/awaiting_appointment_card.dart';
import 'package:colette/features/health/presentation/widgets/medical_stage_sheet.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../health_factories.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, MedicalTimeline? timeline) =>
      pumpApp(
        tester,
        const Scaffold(body: AwaitingAppointmentCard()),
        overrides: [
          clockProvider.overrideWithValue(
            FixedClock(DateTime(2026, 10, 20, 9)),
          ),
          minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
          babyProfileProvider.overrideWith(
            (ref) => Stream.value(
              BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1)),
            ),
          ),
          medicalTimelineProvider.overrideWithValue(timeline),
        ],
      );

  final awaiting = MedicalTimeline(
    entries: [
      entry(
        MedicalStageId.m1,
        MedicalStageStatus.appointmentPassed,
        appointmentAt: DateTime(2026, 9, 18, 9),
      ),
      entry(
        MedicalStageId.m2,
        MedicalStageStatus.scheduled,
        appointmentAt: DateTime(2026, 10, 23, 10),
      ),
    ],
  );

  testWidgets('frise en chargement ou sans RDV passé : rien', (tester) async {
    await pumpCard(tester, null);
    expect(find.byType(ColetteCardSurface), findsNothing);

    await pumpCard(
      tester,
      MedicalTimeline(
        entries: [
          entry(
            MedicalStageId.m2,
            MedicalStageStatus.scheduled,
            appointmentAt: DateTime(2026, 10, 23, 10),
          ),
        ],
      ),
    );
    expect(find.byType(ColetteCardSurface), findsNothing);
  });

  testWidgets('RDV passé non confirmé : alerte warning, étape et date', (
    tester,
  ) async {
    await pumpCard(tester, awaiting);
    expect(find.text('RDV passé · à marquer comme faite'), findsOneWidget);
    expect(find.text('Examen du 1er mois'), findsOneWidget);
    expect(find.text('ven. 18 sept., 09h00'), findsOneWidget);
    expect(find.text('Examen et vaccins des 2 mois'), findsNothing);
    expect(
      tester
          .widget<ColetteCardSurface>(find.byType(ColetteCardSurface))
          .borderColor,
      AppColors.warning,
    );
  });

  testWidgets('tap : ouvre la feuille de l\'étape', (tester) async {
    await pumpCard(tester, awaiting);
    await tester.tap(find.byType(AwaitingAppointmentCard));
    await tester.pumpAndSettle();
    expect(find.byType(MedicalStageSheet), findsOneWidget);
  });
}
