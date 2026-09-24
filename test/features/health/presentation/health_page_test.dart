import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/pages/health_page.dart';
import 'package:colette/features/health/presentation/providers/calendar_sync_issue.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/health/presentation/providers/selected_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/pump_app.dart';
import '../health_factories.dart';

void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    required MedicalTimeline? timeline,
    Map<String, Object> prefs = const {},
    List<Override> extra = const [],
    // Assez haut pour que la ListView construise tous les blocs.
    Size viewSize = const Size(390, 1800),
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final sharedPrefs = await SharedPreferences.getInstance();
    await pumpApp(
      tester,
      const HealthPage(),
      viewSize: viewSize,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        healthSyncProvider.overrideWithValue(const NoopHealthSync()),
        clockProvider.overrideWithValue(FixedClock(DateTime(2026, 10, 20, 9))),
        minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
        medicalTimelineProvider.overrideWithValue(timeline),
        ...extra,
      ],
    );
  }

  final fullTimeline = MedicalTimeline(
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
        practitioner: 'Dr Martin',
      ),
      entry(MedicalStageId.m3, MedicalStageStatus.due),
      entry(MedicalStageId.m4, MedicalStageStatus.upcoming),
      entry(MedicalStageId.m5, MedicalStageStatus.upcoming),
    ],
    appointments: [
      AppointmentItem(
        makeAppointment(appointmentAt: DateTime(2026, 10, 25, 15)),
        MedicalStageStatus.scheduled,
      ),
    ],
  );

  testWidgets(
    'ordre des blocs : prochain RDV, programmés, à confirmer, à programmer, repliés',
    (tester) async {
      await pumpPage(tester, timeline: fullTimeline);
      expect(find.text('Santé'), findsOneWidget);
      expect(find.text('Prochain rendez-vous'), findsOneWidget);
      // Le RDV libre du 25 octobre précède l'étape du 3 novembre.
      expect(find.text('dim. 25 oct., 15h00'), findsOneWidget);
      expect(find.text('Ostéopathe'), findsOneWidget);
      expect(find.text('Aussi programmés'), findsOneWidget);
      expect(find.text('10h00 · Dr Martin'), findsOneWidget);
      expect(find.text('RDV passé, à confirmer'), findsOneWidget);
      expect(find.text('Examen du 1er mois'), findsOneWidget);
      expect(find.text('À programmer'), findsOneWidget);
      expect(find.text('en retard'), findsOneWidget);
      expect(find.text('À venir (2)'), findsOneWidget);
      expect(find.text('Faites (1)'), findsOneWidget);
      expect(find.text('Examen des 8 jours'), findsNothing);
      expect(find.text('Examen et vaccins des 4 mois'), findsNothing);

      double top(String text) => tester.getTopLeft(find.text(text)).dy;
      expect(top('Prochain rendez-vous'), lessThan(top('Aussi programmés')));
      expect(top('Aussi programmés'), lessThan(top('RDV passé, à confirmer')));
      expect(top('RDV passé, à confirmer'), lessThan(top('À programmer')));
      expect(top('À programmer'), lessThan(top('À venir (2)')));
      expect(top('À venir (2)'), lessThan(top('Faites (1)')));

      await tester.scrollUntilVisible(find.text('À venir (2)'), 200);
      await tester.tap(find.text('À venir (2)'));
      await tester.pumpAndSettle();
      expect(find.text('Examen et vaccins des 4 mois'), findsOneWidget);
    },
  );

  testWidgets(
    'sans RDV : carte grise, sections programmés et à confirmer absentes',
    (tester) async {
      await pumpPage(
        tester,
        timeline: MedicalTimeline(
          entries: [entry(MedicalStageId.m2, MedicalStageStatus.due)],
        ),
      );
      expect(find.text('Pas de rendez-vous programmé'), findsOneWidget);
      expect(find.text('Aussi programmés'), findsNothing);
      expect(find.text('RDV passé, à confirmer'), findsNothing);
      expect(find.text('À programmer'), findsOneWidget);
    },
  );

  testWidgets('calendrier non configuré : ligne en pied de page seulement', (
    tester,
  ) async {
    await pumpPage(
      tester,
      timeline: MedicalTimeline(
        entries: [entry(MedicalStageId.m2, MedicalStageStatus.due)],
      ),
    );
    final footer = find.text(
      'RDV non ajoutés au Calendrier (à régler dans Réglages)',
    );
    await tester.scrollUntilVisible(footer, 200);
    expect(footer, findsOneWidget);
    expect(
      tester.getTopLeft(footer).dy,
      greaterThan(tester.getTopLeft(find.text('À programmer')).dy),
    );
    expect(find.byIcon(Icons.sync_problem), findsNothing);
  });

  testWidgets('calendrier synchronisé : pied de page avec son nom', (
    tester,
  ) async {
    await pumpPage(
      tester,
      timeline: const MedicalTimeline(entries: []),
      prefs: {
        SelectedCalendar.idKey: 'c1',
        SelectedCalendar.titleKey: 'Famille',
      },
    );
    expect(find.text('Synchronisé avec Famille'), findsOneWidget);
  });

  testWidgets('problème de sync : alerte en haut, pas de pied de page', (
    tester,
  ) async {
    await pumpPage(
      tester,
      timeline: const MedicalTimeline(entries: []),
      prefs: {
        SelectedCalendar.idKey: 'c1',
        SelectedCalendar.titleKey: 'Famille',
      },
      extra: [
        calendarSyncIssueProvider.overrideWithValue(
          CalendarReason.accessDenied,
        ),
      ],
    );
    final alert = find.text(
      "Colette n'a pas accès au Calendrier. Autorise-le dans Réglages iOS › Colette › Calendriers.",
    );
    expect(alert, findsOneWidget);
    expect(find.byIcon(Icons.sync_problem), findsOneWidget);
    expect(
      tester.getTopLeft(alert).dy,
      lessThan(tester.getTopLeft(find.text('Prochain rendez-vous')).dy),
    );
    expect(find.textContaining('Famille'), findsNothing);
  });

  testWidgets('bouton d\'ajout ouvre la feuille de RDV libre', (tester) async {
    // Plus large : la police de test (Ahem) déborde des champs de date
    // de la feuille à 390 points.
    await pumpPage(
      tester,
      timeline: const MedicalTimeline(entries: []),
      viewSize: const Size(800, 1800),
    );
    expect(find.byTooltip('Ajouter un rendez-vous'), findsOneWidget);
    await tester.tap(find.byTooltip('Ajouter un rendez-vous'));
    await tester.pumpAndSettle();
    expect(find.text('Nouveau rendez-vous'), findsOneWidget);
  });

  testWidgets(
    'frise en chargement : ni carte ni état vide, pied de page présent',
    (tester) async {
      await pumpPage(tester, timeline: null);
      expect(find.text('Santé'), findsOneWidget);
      expect(find.text('Prochain rendez-vous'), findsNothing);
      expect(find.text('Pas de rendez-vous programmé'), findsNothing);
      expect(
        find.text('RDV non ajoutés au Calendrier (à régler dans Réglages)'),
        findsOneWidget,
      );
    },
  );
}
