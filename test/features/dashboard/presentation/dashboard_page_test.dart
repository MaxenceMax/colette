import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock_status.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_providers.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/features/events/domain/repositories/events_repository.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/events/presentation/widgets/event_form_sheet.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncData, AsyncValue;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/care_event_factory.dart';
import '../../../helpers/documents_repository_override.dart';
import '../../../helpers/fake_sleep_repository.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

class MockEventsRepository extends Mock implements EventsRepository {}

void main() {
  final now = DateTime(2026, 9, 10, 12);
  final profile = BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1));
  final bottle = makeEvent(
    id: 'b',
    startAt: DateTime(2026, 9, 10, 8),
    bottleMl: 60,
  );
  final adrigyl = makeEvent(
    id: 'a',
    startAt: DateTime(2026, 9, 10, 9),
    adrigyl: true,
    diaperChange: true,
  );

  setUpAll(() => registerFallbackValue(makeEvent(startAt: DateTime(2026))));

  final lateBottle = makeEvent(
    id: 'y',
    startAt: DateTime(2026, 9, 9, 23, 50),
    bottleMl: 90,
  );

  final defaultMeasurements = [
    GrowthMeasurement(id: 'w', measuredAt: DateTime(2026, 9, 9), grams: 3600),
  ];

  List<Override> overridesFor(
    MockEventsRepository repo, {
    List<CareEvent>? recent,
    AsyncValue<DiaperStockStatus?> diaperStatus = const AsyncData(null),
    BabyProfile? baby,
    List<GrowthMeasurement>? measurements,
    CareEvent? latest,
  }) => [
    documentsRepositoryOverride(),
    clockProvider.overrideWithValue(FixedClock(now)),
    minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
    householdLocalStoreProvider.overrideWithValue(
      InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
    ),
    babyProfileProvider.overrideWith((ref) => Stream.value(baby ?? profile)),
    measurementsProvider.overrideWith(
      (ref) => Stream.value(measurements ?? defaultMeasurements),
    ),
    todayEventsProvider.overrideWith((ref) => Stream.value([adrigyl, bottle])),
    recentEventsProvider.overrideWith(
      (ref) => Stream.value(recent ?? [adrigyl, bottle, lateBottle]),
    ),
    latestBottleProvider.overrideWith((ref) => Stream.value(latest ?? bottle)),
    latestBathProvider.overrideWith((ref) => Stream.value(null)),
    eventsRepositoryProvider.overrideWithValue(repo),
    idGeneratorProvider.overrideWithValue(const FixedIdGenerator('e-new')),
    feedingPlanSyncProvider.overrideWithValue(const NoopFeedingPlanSync()),
    diaperStockStatusProvider.overrideWithValue(diaperStatus),
    sleepRepositoryProvider.overrideWithValue(FakeSleepRepository()),
  ];

  testWidgets(
    'affiche l\'âge, le prochain biberon, les tâches et les compteurs',
    (tester) async {
      final repo = MockEventsRepository();
      when(() => repo.save(any(), any())).thenAnswer((_) async => right(null));
      await pumpApp(
        tester,
        const DashboardPage(),
        overrides: overridesFor(repo),
      );

      expect(find.text('Colette a 9 jours'), findsOneWidget);
      expect(find.text('Prochain biberon'), findsOneWidget);
      expect(find.text('70 ml'), findsOneWidget);
      expect(find.text('en retard de 35 min'), findsOneWidget);
      expect(find.text('fait à 09h00'), findsOneWidget);
      expect(
        find.text('2 biberons · 150 ml sur les dernières 24 h'),
        findsOneWidget,
      );
      expect(find.text('Sommeil'), findsOneWidget);
      expect(find.text('Aucun sommeil noté'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Soin des yeux'), 200);
      expect(find.text('Bain'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('couches'), 200);
      await tester.scrollUntilVisible(find.text('Poids'), 200);
      expect(find.text('3600 g'), findsOneWidget);
    },
  );

  testWidgets('affiche la carte Sommeil sous le prochain biberon', (
    tester,
  ) async {
    final repo = MockEventsRepository();
    await pumpApp(tester, const DashboardPage(), overrides: overridesFor(repo));
    expect(find.text('Sommeil'), findsOneWidget);
    expect(find.text('Aucun sommeil noté'), findsOneWidget);
  });

  testWidgets(
    'taper une tâche à faire enregistre le soin et propose d\'annuler',
    (tester) async {
      final repo = MockEventsRepository();
      when(() => repo.save(any(), any())).thenAnswer((_) async => right(null));
      await pumpApp(
        tester,
        const DashboardPage(),
        overrides: overridesFor(repo),
      );
      await tester.tap(find.text('Soin des yeux'));
      await tester.pumpAndSettle();
      final saved =
          verify(() => repo.save('ABCDEFGH', captureAny())).captured.single
              as CareEvent;
      expect(saved.eyeCare, isTrue);
      expect(saved.startAt, now);
      expect(find.text('Enregistré'), findsOneWidget);
      expect(find.widgetWithText(SnackBarAction, 'Annuler'), findsOneWidget);
    },
  );

  testWidgets('avant la fourchette, la carte affiche ses bornes', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const DashboardPage(),
      overrides: overridesFor(
        MockEventsRepository(),
        latest: makeEvent(
          id: 'r',
          startAt: DateTime(2026, 9, 10, 11),
          bottleMl: 60,
        ),
      ),
    );
    expect(find.text('entre 13h35 et 14h25'), findsOneWidget);
  });

  testWidgets('dans la fourchette, la carte affiche sa fin', (tester) async {
    await pumpApp(
      tester,
      const DashboardPage(),
      overrides: overridesFor(
        MockEventsRepository(),
        latest: makeEvent(
          id: 'r',
          startAt: DateTime(2026, 9, 10, 9, 10),
          bottleMl: 60,
        ),
      ),
    );
    expect(find.text('maintenant, jusqu\'à 12h35'), findsOneWidget);
  });

  testWidgets('le bouton horloge ouvre la feuille des 24 prochaines heures', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const DashboardPage(),
      overrides: overridesFor(MockEventsRepository()),
    );
    await tester.tap(find.byTooltip('Prochaines 24 h'));
    await tester.pumpAndSettle();
    expect(find.text('Prochaines 24 h'), findsOneWidget);
    expect(find.text('Demain'), findsOneWidget);
  });

  testWidgets('affiche zéro biberon sur 24 h sans événement récent', (
    tester,
  ) async {
    final repo = MockEventsRepository();
    await pumpApp(
      tester,
      const DashboardPage(),
      overrides: overridesFor(repo, recent: const []),
    );
    expect(
      find.text('0 biberon · 0 ml sur les dernières 24 h'),
      findsOneWidget,
    );
  });

  testWidgets('affiche l\'alerte de stock de couches sous le seuil', (
    tester,
  ) async {
    final repo = MockEventsRepository();
    await pumpApp(
      tester,
      const DashboardPage(),
      overrides: overridesFor(
        repo,
        diaperStatus: const AsyncData(
          DiaperStockStatus(remaining: 4, isLow: true),
        ),
      ),
    );
    expect(find.text('Plus que 4 couches'), findsOneWidget);
  });

  testWidgets(
    'avec une cible ajustée, la carte l\'indique et la suggestion suit',
    (tester) async {
      final repo = MockEventsRepository();
      await pumpApp(
        tester,
        const DashboardPage(),
        overrides: overridesFor(
          repo,
          baby: profile.copyWith(
            careSettings: const CareSettings(dailyTargetMl: 600),
          ),
        ),
      );
      // (600 − 60) / 7 = 77,1 → 80 ; cible OMS : 150 × 3,6 = 540.
      expect(find.text('80 ml'), findsOneWidget);
      expect(
        find.text('Cible ajustée à 600 ml · OMS : 540 ml'),
        findsOneWidget,
      );
    },
  );

  testWidgets('sans cible ajustée, aucune mention d\'ajustement', (
    tester,
  ) async {
    final repo = MockEventsRepository();
    await pumpApp(tester, const DashboardPage(), overrides: overridesFor(repo));
    expect(find.textContaining('Cible ajustée'), findsNothing);
  });

  testWidgets('l\'icône info ouvre la feuille Repères OMS', (tester) async {
    final repo = MockEventsRepository();
    await pumpApp(tester, const DashboardPage(), overrides: overridesFor(repo));
    await tester.tap(find.byTooltip('Voir les repères OMS'));
    await tester.pumpAndSettle();
    expect(find.text('Repères OMS'), findsOneWidget);
    expect(find.text('Repères par âge'), findsOneWidget);
    expect(find.byType(EventFormSheet), findsNothing);
  });

  testWidgets('taper la carte ouvre le formulaire biberon prérempli', (
    tester,
  ) async {
    final repo = MockEventsRepository();
    await pumpApp(tester, const DashboardPage(), overrides: overridesFor(repo));
    await tester.tap(find.text('Prochain biberon'));
    await tester.pumpAndSettle();
    expect(find.byType(EventFormSheet), findsOneWidget);
    expect(find.text('Repères OMS'), findsNothing);
  });

  testWidgets(
    'cible ajustée sans pesée : mention d\'ajustement, pas d\'invitation à peser',
    (tester) async {
      final repo = MockEventsRepository();
      await pumpApp(
        tester,
        const DashboardPage(),
        overrides: overridesFor(
          repo,
          measurements: const [],
          baby: profile.copyWith(
            careSettings: const CareSettings(dailyTargetMl: 600),
          ),
        ),
      );
      expect(find.textContaining('Cible ajustée à 600 ml'), findsOneWidget);
      expect(
        find.text(
          'Repères par âge : ajoute une pesée pour un calcul au poids.',
        ),
        findsNothing,
      );
    },
  );
}
