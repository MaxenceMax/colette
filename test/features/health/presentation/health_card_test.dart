import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/connectivity/connectivity_provider.dart';
import 'package:colette/core/theme/theme_service.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/domain/reference/medical_schedule.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/widgets/health_card.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../health_factories.dart';

MedicalTimelineEntry entry(
  MedicalStageId id,
  MedicalStageStatus status, {
  DateTime? appointmentAt,
  String? practitioner,
}) => MedicalTimelineEntry(
  stage: stageById(id),
  dueFrom: DateTime(2026, 11, 1),
  dueUntil: DateTime(2026, 12, 1),
  status: status,
  visit: switch (status) {
    MedicalStageStatus.done => makeVisit(id, doneAt: DateTime(2026, 9, 4)),
    _ when appointmentAt != null => makeVisit(
      id,
      appointmentAt: appointmentAt,
      practitioner: practitioner,
    ),
    _ => null,
  },
);

void main() {
  Future<void> pumpCard(WidgetTester tester, MedicalTimeline? timeline) async {
    final router = GoRouter(
      initialLocation: AppRoutes.today,
      routes: [
        GoRoute(
          path: AppRoutes.today,
          builder: (_, _) => const Scaffold(body: HealthCard()),
          routes: [
            GoRoute(
              path: 'health',
              builder: (_, _) => const Scaffold(body: Text('page santé')),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isOnlineProvider.overrideWith((ref) => Stream.value(true)),
          clockProvider.overrideWithValue(FixedClock(DateTime(2026, 10, 20))),
          minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
          medicalTimelineProvider.overrideWithValue(timeline),
        ],
        child: MaterialApp.router(
          theme: const ThemeService().light(),
          locale: const Locale('fr'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('étape à faire : libellé et fenêtre', (tester) async {
    await pumpCard(
      tester,
      MedicalTimeline(
        entries: [entry(MedicalStageId.m2, MedicalStageStatus.due)],
      ),
    );
    expect(find.text('Examen et vaccins des 2 mois'), findsOneWidget);
    expect(find.text('À faire du 1 nov. 2026 au 30 nov. 2026'), findsOneWidget);
  });

  testWidgets('RDV pris : date, heure et praticien', (tester) async {
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
    expect(find.text('RDV le mar. 3 nov., 10h00 · Dr Martin'), findsOneWidget);
  });

  testWidgets('en retard', (tester) async {
    await pumpCard(
      tester,
      MedicalTimeline(
        entries: [entry(MedicalStageId.m2, MedicalStageStatus.late)],
      ),
    );
    expect(find.text('En retard depuis le 1 déc. 2026'), findsOneWidget);
  });

  testWidgets('tap : ouvre la page Santé', (tester) async {
    await pumpCard(
      tester,
      MedicalTimeline(
        entries: [entry(MedicalStageId.m2, MedicalStageStatus.due)],
      ),
    );
    await tester.tap(find.byType(HealthCard));
    await tester.pumpAndSettle();
    expect(find.text('page santé'), findsOneWidget);
  });

  testWidgets('sans profil : rien', (tester) async {
    await pumpCard(tester, null);
    expect(find.text('Santé'), findsNothing);
  });
}
