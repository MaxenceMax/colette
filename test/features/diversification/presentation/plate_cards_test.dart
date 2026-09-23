import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/allergen_state.dart';
import 'package:colette/features/diversification/domain/entities/daily_diversity.dart';
import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/domain/entities/diversification_timeline.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/liking.dart';
import 'package:colette/features/diversification/domain/entities/retry_item.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_overview_providers.dart';
import 'package:colette/features/diversification/presentation/widgets/allergens_card.dart';
import 'package:colette/features/diversification/presentation/widgets/preparation_card.dart';
import 'package:colette/features/diversification/presentation/widgets/retry_card.dart';
import 'package:colette/features/diversification/presentation/widgets/today_diversity_card.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../helpers/diversification_overrides.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, [
    List<Override> extra = const [],
  ]) => pumpApp(
    tester,
    Scaffold(body: SingleChildScrollView(child: child)),
    overrides: [...diversificationOverrides(), ...extra],
  );

  testWidgets('préparation : compte à rebours, repères, signes', (
    tester,
  ) async {
    await pump(
      tester,
      PreparationCard(
        timeline: DiversificationTimeline(
          phase: DiversificationPhase.preparation,
          ageMonths: 0,
          sixMonthsDate: DateTime(2027, 3, 15),
          daysUntilSixMonths: 173,
        ),
      ),
    );
    expect(find.text('Bientôt la diversification'), findsOneWidget);
    expect(find.text('6 mois dans 173 jours'), findsOneWidget);
    expect(
      find.text(
        'OMS : à 6 mois · France : entre 4 et 6 mois, jamais avant 4 mois',
      ),
      findsOneWidget,
    );
    expect(find.text('Tient sa tête et son dos droits.'), findsOneWidget);
    expect(find.text('Noter une dégustation'), findsOneWidget);
  });

  testWidgets('aujourd\'hui : groupes couverts et dégustations', (
    tester,
  ) async {
    await pump(tester, const TodayDiversityCard(), [
      dailyDiversityProvider.overrideWithValue(
        const DailyDiversity(
          coveredGroups: {FoodGroup.eggs, FoodGroup.vitaminAFruitsVeg},
          tastingCount: 3,
        ),
      ),
    ]);
    expect(find.text('2 groupes sur 7'), findsOneWidget);
    expect(find.text('3 dégustations'), findsOneWidget);
    expect(find.text('Œufs'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNWidgets(2));
    expect(
      find.text(
        'Repère OMS : au moins 5 groupes sur 8 par jour, lait compris.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('allergènes : décompte et tap', (tester) async {
    Allergen? tapped;
    await pump(tester, AllergensCard(onAllergenTap: (a) => tapped = a), [
      allergenProgressProvider.overrideWithValue({
        for (final a in Allergen.tracked)
          a: switch (a) {
            Allergen.milk => AllergenState.introduced,
            Allergen.eggs => AllergenState.reaction,
            _ => AllergenState.notYet,
          },
      }),
    ]);
    expect(find.text('2 introduits sur 9'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    await tester.tap(find.text('Œuf'));
    expect(tapped, Allergen.eggs);
  });

  testWidgets('à reproposer : liste, masquée si vide', (tester) async {
    const broccoli = Food(
      id: 'brocoli',
      name: 'Brocoli',
      group: FoodGroup.otherFruitsVeg,
    );
    await pump(tester, const RetryCard(), [
      foodsToRetryProvider.overrideWithValue(const [
        RetryItem(food: broccoli, lastLiking: Liking.refused, tastingCount: 3),
      ]),
    ]);
    expect(find.text('À reproposer'), findsOneWidget);
    expect(find.text('Brocoli'), findsOneWidget);
    expect(find.text('Refusé · 3 essais'), findsOneWidget);
  });

  testWidgets('à reproposer vide : rien', (tester) async {
    await pump(tester, const RetryCard(), [
      foodsToRetryProvider.overrideWithValue(const []),
    ]);
    expect(find.byType(ColetteCardSurface), findsNothing);
  });
}
