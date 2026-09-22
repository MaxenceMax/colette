import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock_status.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_providers.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/features/events/domain/repositories/events_repository.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncData, AsyncValue;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/care_event_factory.dart';
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

  List<Override> overridesFor(
    MockEventsRepository repo, {
    List<CareEvent>? recent,
    AsyncValue<DiaperStockStatus?> diaperStatus = const AsyncData(null),
  }) => [
    clockProvider.overrideWithValue(FixedClock(now)),
    minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
    householdLocalStoreProvider.overrideWithValue(
      InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
    ),
    babyProfileProvider.overrideWith((ref) => Stream.value(profile)),
    weightsProvider.overrideWith(
      (ref) => Stream.value([
        WeightEntry(id: 'w', measuredAt: DateTime(2026, 9, 9), grams: 3600),
      ]),
    ),
    todayEventsProvider.overrideWith((ref) => Stream.value([adrigyl, bottle])),
    recentEventsProvider.overrideWith(
      (ref) => Stream.value(recent ?? [adrigyl, bottle, lateBottle]),
    ),
    latestBottleProvider.overrideWith((ref) => Stream.value(bottle)),
    latestBathProvider.overrideWith((ref) => Stream.value(null)),
    eventsRepositoryProvider.overrideWithValue(repo),
    idGeneratorProvider.overrideWithValue(const FixedIdGenerator('e-new')),
    feedingPlanSyncProvider.overrideWithValue(const NoopFeedingPlanSync()),
    diaperStockStatusProvider.overrideWithValue(diaperStatus),
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
      expect(find.text('en retard de 60 min'), findsOneWidget);
      expect(find.text('fait à 09h00'), findsOneWidget);
      expect(
        find.text('2 biberons · 150 ml sur les dernières 24 h'),
        findsOneWidget,
      );
      expect(find.text('Soin des yeux'), findsOneWidget);
      expect(find.text('Bain'), findsOneWidget);
      expect(find.text('couches'), findsOneWidget);
    },
  );

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
}
