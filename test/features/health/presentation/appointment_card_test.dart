import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/connectivity/connectivity_provider.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/theme_service.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/widgets/appointment_card.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../health_factories.dart';

void main() {
  final now = DateTime(2026, 10, 20, 9);

  Future<void> pumpCard(WidgetTester tester, MedicalTimeline? timeline) async {
    final router = GoRouter(
      initialLocation: AppRoutes.today,
      routes: [
        GoRoute(
          path: AppRoutes.today,
          builder: (_, _) => const Scaffold(body: AppointmentCard()),
        ),
        GoRoute(
          path: AppRoutes.health,
          builder: (_, _) => const Scaffold(body: Text('page santé')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isOnlineProvider.overrideWith((ref) => Stream.value(true)),
          clockProvider.overrideWithValue(FixedClock(now)),
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

  MedicalTimeline scheduledAt(DateTime at, {String? practitioner}) =>
      MedicalTimeline(
        entries: [
          entry(
            MedicalStageId.m2,
            MedicalStageStatus.scheduled,
            appointmentAt: at,
            practitioner: practitioner,
          ),
        ],
      );

  ColetteCardSurface surface(WidgetTester tester) =>
      tester.widget<ColetteCardSurface>(find.byType(ColetteCardSurface));

  testWidgets('frise en chargement : en-tête seul, sans fausse absence', (
    tester,
  ) async {
    await pumpCard(tester, null);
    expect(find.text('Rendez-vous'), findsOneWidget);
    expect(find.text('Pas de rendez-vous programmé'), findsNothing);
    expect(find.byIcon(Icons.event_outlined), findsOneWidget);
    expect(surface(tester).borderColor, AppColors.border);
    expect(surface(tester).backgroundColor, AppColors.surface);
  });

  testWidgets('sans RDV : « Pas de rendez-vous programmé »', (tester) async {
    await pumpCard(
      tester,
      MedicalTimeline(
        entries: [entry(MedicalStageId.m2, MedicalStageStatus.due)],
      ),
    );
    expect(find.text('Rendez-vous'), findsOneWidget);
    expect(find.text('Pas de rendez-vous programmé'), findsOneWidget);
    expect(find.byIcon(Icons.event_busy_outlined), findsOneWidget);
  });

  testWidgets('éloigné : neutre, date et praticien', (tester) async {
    await pumpCard(
      tester,
      scheduledAt(DateTime(2026, 11, 3, 10), practitioner: 'Dr Martin'),
    );
    expect(find.text('Rendez-vous'), findsOneWidget);
    expect(find.text('Examen et vaccins des 2 mois'), findsOneWidget);
    expect(find.text('mar. 3 nov., 10h00 · Dr Martin'), findsOneWidget);
    expect(surface(tester).borderColor, AppColors.border);
    expect(surface(tester).backgroundColor, AppColors.surface);
  });

  testWidgets('bientôt : bordure primary et « dans N jours »', (tester) async {
    await pumpCard(tester, scheduledAt(DateTime(2026, 10, 23, 10)));
    expect(find.text('Rendez-vous dans 3 jours'), findsOneWidget);
    expect(find.text('ven. 23 oct., 10h00'), findsOneWidget);
    expect(surface(tester).borderColor, AppColors.primary);
    expect(surface(tester).backgroundColor, AppColors.surface);
  });

  testWidgets('aujourd\'hui et demain : fond primaryContainer, heure en gros', (
    tester,
  ) async {
    await pumpCard(tester, scheduledAt(DateTime(2026, 10, 20, 15, 30)));
    expect(find.text('Aujourd\'hui à 15h30'), findsOneWidget);
    expect(surface(tester).backgroundColor, AppColors.primaryContainer);

    await pumpCard(tester, scheduledAt(DateTime(2026, 10, 21, 8)));
    expect(find.text('Demain à 08h00'), findsOneWidget);
    expect(surface(tester).backgroundColor, AppColors.primaryContainer);
  });

  testWidgets('RDV passé non confirmé prime sur le prochain RDV', (
    tester,
  ) async {
    await pumpCard(
      tester,
      MedicalTimeline(
        entries: [
          entry(
            MedicalStageId.m1,
            MedicalStageStatus.appointmentPassed,
            appointmentAt: DateTime(2026, 9, 18, 9),
          ),
          entry(
            MedicalStageId.m2,
            MedicalStageStatus.scheduled,
            appointmentAt: DateTime(2026, 10, 20, 15),
          ),
        ],
      ),
    );
    expect(find.text('RDV passé · à marquer comme faite'), findsOneWidget);
    expect(find.text('Examen du 1er mois'), findsOneWidget);
    expect(find.text('ven. 18 sept., 09h00'), findsOneWidget);
    expect(find.textContaining('Aujourd\'hui'), findsNothing);
    expect(surface(tester).borderColor, AppColors.warning);
  });

  testWidgets('tap : va sur l\'onglet Santé', (tester) async {
    await pumpCard(tester, null);
    await tester.tap(find.byType(AppointmentCard));
    await tester.pumpAndSettle();
    expect(find.text('page santé'), findsOneWidget);
  });
}
