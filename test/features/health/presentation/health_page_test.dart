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
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/pump_app.dart';
import 'health_card_test.dart' show entry;

void main() {
  testWidgets('sections par statut, faites repliées', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await pumpApp(
      tester,
      const HealthPage(),
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        healthSyncProvider.overrideWithValue(const NoopHealthSync()),
        medicalTimelineProvider.overrideWithValue(
          MedicalTimeline(
            entries: [
              entry(MedicalStageId.day8, MedicalStageStatus.done),
              entry(MedicalStageId.week2, MedicalStageStatus.late),
              entry(MedicalStageId.m2, MedicalStageStatus.due),
              entry(MedicalStageId.m3, MedicalStageStatus.upcoming),
            ],
          ),
        ),
      ],
    );
    expect(find.text('Santé'), findsOneWidget);
    expect(find.text('En retard'), findsOneWidget);
    expect(find.text('Examen de la 2e semaine'), findsOneWidget);
    expect(find.text('À faire'), findsOneWidget);
    expect(find.text('À venir'), findsOneWidget);
    expect(find.text('Faites (1)'), findsOneWidget);
    expect(find.text('Examen des 8 jours'), findsNothing);
    expect(
      find.text('RDV non ajoutés au Calendrier (à régler dans Réglages)'),
      findsOneWidget,
    );

    await tester.tap(find.text('Faites (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Examen des 8 jours'), findsOneWidget);
  });

  testWidgets('alerte quand le calendrier n\'est plus synchronisé', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      SelectedCalendar.idKey: 'c1',
      SelectedCalendar.titleKey: 'Famille',
    });
    final prefs = await SharedPreferences.getInstance();
    await pumpApp(
      tester,
      const HealthPage(),
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        healthSyncProvider.overrideWithValue(const NoopHealthSync()),
        medicalTimelineProvider.overrideWithValue(null),
        calendarSyncIssueProvider.overrideWithValue(
          CalendarReason.accessDenied,
        ),
      ],
    );
    expect(
      find.text(
        "Colette n'a pas accès au Calendrier. Autorise-le dans Réglages iOS › Colette › Calendriers.",
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.sync_problem), findsOneWidget);
    expect(find.textContaining('Famille'), findsNothing);
  });
}
