import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/widgets/next_appointment_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../health_factories.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester,
    MedicalTimeline? timeline, {
    DateTime? now,
  }) => pumpApp(
    tester,
    Scaffold(body: ListView(children: const [NextAppointmentCard()])),
    overrides: [
      clockProvider.overrideWithValue(
        FixedClock(now ?? DateTime(2026, 10, 20, 9)),
      ),
      minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
      medicalTimelineProvider.overrideWithValue(timeline),
    ],
  );

  testWidgets('sans RDV : carte grise « Pas de rendez-vous programmé »', (
    tester,
  ) async {
    await pumpCard(
      tester,
      MedicalTimeline(
        entries: [entry(MedicalStageId.m2, MedicalStageStatus.due)],
      ),
    );
    expect(find.text('Prochain rendez-vous'), findsOneWidget);
    expect(find.text('Pas de rendez-vous programmé'), findsOneWidget);
    expect(find.byIcon(Icons.event_busy_outlined), findsOneWidget);
  });

  testWidgets(
    'RDV éloigné : date, libellé, praticien, compte à rebours, pastilles',
    (tester) async {
      await pumpCard(
        tester,
        MedicalTimeline(
          entries: [
            entry(
              MedicalStageId.m2,
              MedicalStageStatus.scheduled,
              appointmentAt: DateTime(2026, 11, 3, 10),
              practitioner: 'Dr Martin',
            ),
          ],
        ),
      );
      expect(find.text('mar. 3 nov., 10h00'), findsOneWidget);
      expect(find.text('Examen et vaccins des 2 mois'), findsOneWidget);
      expect(find.text('Dr Martin · dans 14 jours'), findsOneWidget);
      expect(find.text('Examen'), findsOneWidget);
      expect(find.text('Vaccins'), findsOneWidget);
    },
  );

  testWidgets(
    'RDV aujourd\'hui et demain : phrase dédiée, sans compte à rebours',
    (tester) async {
      await pumpCard(
        tester,
        MedicalTimeline(
          entries: [],
          appointments: [
            AppointmentItem(
              makeAppointment(appointmentAt: DateTime(2026, 10, 20, 15, 30)),
              MedicalStageStatus.scheduled,
            ),
          ],
        ),
      );
      expect(find.text('Aujourd\'hui à 15h30'), findsOneWidget);
      expect(find.text('Ostéopathe'), findsOneWidget);
      expect(find.text('RDV libre'), findsOneWidget);
      expect(find.textContaining('dans '), findsNothing);

      await pumpCard(
        tester,
        MedicalTimeline(
          entries: [],
          appointments: [
            AppointmentItem(
              makeAppointment(appointmentAt: DateTime(2026, 10, 21, 8)),
              MedicalStageStatus.scheduled,
            ),
          ],
        ),
      );
      expect(find.text('Demain à 08h00'), findsOneWidget);
    },
  );

  testWidgets('tap : ouvre la feuille du RDV libre', (tester) async {
    await pumpCard(
      tester,
      MedicalTimeline(
        entries: [],
        appointments: [
          AppointmentItem(
            makeAppointment(appointmentAt: DateTime(2026, 10, 25, 8)),
            MedicalStageStatus.scheduled,
          ),
        ],
      ),
    );
    await tester.tap(find.text('Ostéopathe'));
    await tester.pumpAndSettle();
    expect(find.text('Titre (ostéopathe, ORL, pédiatre…)'), findsOneWidget);
  });

  testWidgets('timeline en chargement : rien n\'est affiché', (tester) async {
    await pumpCard(tester, null);
    expect(find.text('Prochain rendez-vous'), findsNothing);
    expect(find.text('Pas de rendez-vous programmé'), findsNothing);
  });

  testWidgets('tap : ouvre la feuille de l\'étape', (tester) async {
    await pumpCard(
      tester,
      MedicalTimeline(
        entries: [
          entry(
            MedicalStageId.m2,
            MedicalStageStatus.scheduled,
            appointmentAt: DateTime(2026, 10, 25, 8),
          ),
        ],
      ),
    );
    expect(find.text('Rendez-vous'), findsNothing);
    await tester.tap(find.text('Examen et vaccins des 2 mois'));
    await tester.pumpAndSettle();
    expect(find.text('Rendez-vous'), findsWidgets);
  });
}
