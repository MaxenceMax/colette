import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/dashboard/presentation/widgets/feeding_reference_sheet.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

class MockBabyRepository extends Mock implements BabyRepository {}

void main() {
  final now = DateTime(2026, 9, 10, 12);
  final profile = BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1));

  setUpAll(() => registerFallbackValue(profile));

  List<Override> overridesFor(
    MockBabyRepository repo, {
    BabyProfile? baby,
    int? weightGrams = 4200,
  }) => [
    clockProvider.overrideWithValue(FixedClock(now)),
    minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
    householdLocalStoreProvider.overrideWithValue(
      InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
    ),
    babyRepositoryProvider.overrideWithValue(repo),
    babyProfileProvider.overrideWith((ref) => Stream.value(baby ?? profile)),
    weightsProvider.overrideWith(
      (ref) => Stream.value([
        if (weightGrams != null)
          WeightEntry(
            id: 'w',
            measuredAt: DateTime(2026, 9, 9),
            grams: weightGrams,
          ),
      ]),
    ),
    todayEventsProvider.overrideWith((ref) => Stream.value(const [])),
    latestBottleProvider.overrideWith((ref) => Stream.value(null)),
    feedingPlanSyncProvider.overrideWithValue(const NoopFeedingPlanSync()),
  ];

  // La feuille est une longue liste défilante ; on agrandit la surface de test
  // pour que tout son contenu soit visible sans avoir à défiler explicitement
  // (sinon `find.text` ignore par défaut les widgets hors du viewport visible).
  Future<void> pumpSheet(WidgetTester tester, List<Override> overrides) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpApp(
      tester,
      const Scaffold(body: FeedingReferenceSheet()),
      overrides: overrides,
    );
  }

  // index 0 = table par âge, index 1 = règle au poids (ordre de l'arbre) :
  // un même libellé (« Jour 1 »...) apparaît dans les deux tables.
  bool isHighlighted(WidgetTester tester, String label, {int index = 0}) {
    final container = find
        .ancestor(
          of: find.text(label).at(index),
          matching: find.byType(Container),
        )
        .first;
    final decoration =
        tester.widget<Container>(container).decoration as BoxDecoration?;
    return decoration?.color != null;
  }

  testWidgets('surligne la ligne du jour et montre le calcul au poids', (
    tester,
  ) async {
    final repo = MockBabyRepository();
    await pumpSheet(tester, overridesFor(repo));
    expect(find.text('Repères OMS'), findsOneWidget);
    expect(find.text('Jour 6 à 1 mois'), findsOneWidget);
    expect(isHighlighted(tester, 'Jour 6 à 1 mois'), isTrue);
    expect(isHighlighted(tester, '1 à 2 mois'), isFalse);
    expect(isHighlighted(tester, 'Jour 6 et plus'), isTrue);
    expect(isHighlighted(tester, 'Jour 1'), isFalse);
    expect(isHighlighted(tester, 'Jour 1', index: 1), isFalse);
    expect(find.text('150 ml/kg × 4,2 kg = 630 ml'), findsOneWidget);
    expect(find.text('Calcul OMS : 630 ml'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Ajuster'), findsOneWidget);
  });

  testWidgets('sans pesée, invite à ajouter une pesée', (tester) async {
    final repo = MockBabyRepository();
    await pumpSheet(tester, overridesFor(repo, weightGrams: null));
    expect(
      find.text('Repères par âge : ajoute une pesée pour un calcul au poids.'),
      findsOneWidget,
    );
    expect(find.textContaining('× '), findsNothing);
  });

  testWidgets('Ajuster pose la cible OMS, + ajoute 10, Revenir remet null', (
    tester,
  ) async {
    final repo = MockBabyRepository();
    when(() => repo.saveProfile(any(), any()))
        .thenAnswer((_) async => right(null));
    await pumpSheet(tester, overridesFor(repo));

    await tester.tap(find.widgetWithText(FilledButton, 'Ajuster'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Revenir au calcul OMS'));
    await tester.pumpAndSettle();

    final saved = verify(() => repo.saveProfile('ABCDEFGH', captureAny()))
        .captured
        .cast<BabyProfile>();
    expect(saved.map((p) => p.careSettings.dailyTargetMl).toList(), [
      630,
      640,
      null,
    ]);
    expect(find.widgetWithText(FilledButton, 'Ajuster'), findsOneWidget);
  });

  testWidgets('une cible déjà ajustée affiche le stepper', (tester) async {
    final repo = MockBabyRepository();
    await pumpSheet(
      tester,
      overridesFor(
        repo,
        baby: profile.copyWith(
          careSettings: const CareSettings(dailyTargetMl: 600),
        ),
      ),
    );
    expect(find.text('Cible ajustée'), findsOneWidget);
    expect(find.text('600 ml'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Ajuster'), findsNothing);
  });

  testWidgets(
    'une erreur d\'écriture s\'affiche dans la feuille et annule l\'ajustement',
    (tester) async {
      final repo = MockBabyRepository();
      when(() => repo.saveProfile(any(), any()))
          .thenAnswer((_) async => left(const NetworkFailure()));
      await pumpSheet(tester, overridesFor(repo));
      await tester.tap(find.widgetWithText(FilledButton, 'Ajuster'));
      await tester.pumpAndSettle();
      expect(
        find.text('Pas de connexion. Réessaie dans un instant.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Ajuster'), findsOneWidget);
    },
  );

  testWidgets('adopte une cible poussée par l\'autre appareil', (tester) async {
    final repo = MockBabyRepository();
    final profileController = StreamController<BabyProfile?>.broadcast();
    addTearDown(profileController.close);
    await pumpSheet(tester, [
      clockProvider.overrideWithValue(FixedClock(now)),
      minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
      householdLocalStoreProvider.overrideWithValue(
        InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
      ),
      babyRepositoryProvider.overrideWithValue(repo),
      babyProfileProvider.overrideWith((ref) => profileController.stream),
      weightsProvider.overrideWith(
        (ref) => Stream.value([
          WeightEntry(id: 'w', measuredAt: DateTime(2026, 9, 9), grams: 4200),
        ]),
      ),
      todayEventsProvider.overrideWith((ref) => Stream.value(const [])),
      latestBottleProvider.overrideWith((ref) => Stream.value(null)),
      feedingPlanSyncProvider.overrideWithValue(const NoopFeedingPlanSync()),
    ]);

    profileController.add(profile);
    await tester.pumpAndSettle();
    profileController.add(
      profile.copyWith(careSettings: const CareSettings(dailyTargetMl: 700)),
    );
    await tester.pumpAndSettle();

    expect(find.text('700 ml'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Ajuster'), findsNothing);
  });
}
