import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/pages/health_page.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
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
}
