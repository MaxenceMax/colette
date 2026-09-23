import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/allergen_state.dart';
import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_catalog.dart';
import 'package:colette/features/diversification/domain/entities/food_filter.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/food_status.dart';
import 'package:colette/features/diversification/domain/entities/liking.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/domain/repositories/food_catalog_repository.dart';
import 'package:colette/features/diversification/presentation/providers/catalog_filter.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_overview_providers.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../helpers/catalog_fixture.dart';

/// Repository de test : échoue toujours au chargement.
class _FailingFoodCatalogRepository implements FoodCatalogRepository {
  @override
  Future<Either<Failure, FoodCatalog>> load() async =>
      left(const UnknownFailure('x'));
}

void main() {
  final now = DateTime(2027, 4, 10, 18);
  const kaki = Food(
    id: 'c1',
    name: 'Kaki',
    group: FoodGroup.vitaminAFruitsVeg,
    isCustom: true,
  );
  final tastings = [
    Tasting(
      id: '1',
      foodId: 'carotte',
      at: DateTime(2027, 4, 10, 12),
      liking: Liking.loved,
    ),
    Tasting(
      id: '2',
      foodId: 'oeuf-cuit',
      at: DateTime(2027, 4, 10, 8),
      hadReaction: true,
    ),
    Tasting(
      id: '3',
      foodId: 'brocoli',
      at: DateTime(2027, 4, 9),
      liking: Liking.refused,
    ),
    Tasting(id: '4', foodId: 'carotte', at: DateTime(2027, 4, 2)),
  ];

  Future<ProviderContainer> container({BabyProfile? profile}) async {
    final c = ProviderContainer(
      overrides: [
        foodCatalogProvider.overrideWith((ref) async => catalogFixture()),
        customFoodsProvider.overrideWith((ref) => Stream.value(const [kaki])),
        tastingsProvider.overrideWith((ref) => Stream.value(tastings)),
        babyProfileProvider.overrideWith((ref) => Stream.value(profile)),
        clockProvider.overrideWithValue(FixedClock(now)),
        minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
      ],
    );
    addTearDown(c.dispose);
    // Garde les providers autoDispose en vie et attend les premières valeurs.
    // `tastingsProvider` n'est watché par aucun des deux (foods ne fusionne
    // que le catalogue et les aliments perso) : sans écoute directe, il est
    // disposé pendant son chargement avant d'avoir pu émettre.
    c.listen(foodsProvider, (_, _) {});
    c.listen(diversificationTimelineProvider, (_, _) {});
    c.listen(tastingsProvider, (_, _) {});
    await c.read(foodCatalogProvider.future);
    await c.read(customFoodsProvider.future);
    await c.read(tastingsProvider.future);
    await c.read(babyProfileProvider.future);
    return c;
  }

  final profile = BabyProfile(
    name: 'Colette',
    birthDate: DateTime(2026, 9, 15),
  );

  test('foods fusionne catalogue et aliments perso', () async {
    final c = await container();
    final foods = c.read(foodsProvider).value!;
    expect(foods, hasLength(9));
    expect(foods['c1'], kaki);
    expect(foods['miel']?.isCustom, isFalse);
  });

  test('timeline : null sans profil, phase selon l\'âge sinon', () async {
    expect((await container()).read(diversificationTimelineProvider), isNull);
    final c = await container(profile: profile);
    final timeline = c.read(diversificationTimelineProvider)!;
    expect(timeline.phase, DiversificationPhase.months6To8);
    expect(timeline.ageMonths, 6);
  });

  test('indicateurs dérivés', () async {
    final c = await container(profile: profile);
    expect(c.read(tastingCountsProvider), {
      'carotte': 2,
      'oeuf-cuit': 1,
      'brocoli': 1,
    });
    expect(c.read(dailyDiversityProvider).coveredGroups, {
      FoodGroup.vitaminAFruitsVeg,
      FoodGroup.eggs,
    });
    expect(
      c.read(allergenProgressProvider)[Allergen.eggs],
      AllergenState.reaction,
    );
    expect(c.read(foodsToRetryProvider).single.food.id, 'brocoli');
    expect(c.read(tastingsForFoodProvider('carotte')).map((t) => t.id), [
      '1',
      '4',
    ]);
  });

  test('statuts selon l\'âge', () async {
    final c = await container(profile: profile);
    final statuses = c.read(foodStatusesProvider);
    expect(statuses['miel'], isA<FoodStatusAvoid>());
    expect(
      statuses['carotte'],
      const FoodStatus.tasted(count: 2, needsPreparation: false),
    );
    expect(statuses['c1'], const FoodStatus.notTasted(needsPreparation: false));
  });

  test('catalogue filtré selon CatalogFilter', () async {
    final c = await container(profile: profile);
    c.listen(filteredCatalogProvider, (_, _) {});
    expect(
      c.read(filteredCatalogProvider).expand((s) => s.foods),
      hasLength(9),
    );
    c.read(catalogFilterProvider.notifier).setAllergen(Allergen.eggs);
    expect(c.read(filteredCatalogProvider).single.foods.single.id, 'oeuf-cuit');
    c.read(catalogFilterProvider.notifier)
      ..setAllergen(null)
      ..setMode(CatalogMode.avoid);
    expect(
      c.read(filteredCatalogProvider).expand((s) => s.foods).map((f) => f.id),
      unorderedEquals(['miel', 'lait-de-vache']),
    );
    c.read(catalogFilterProvider.notifier)
      ..setMode(CatalogMode.all)
      ..setQuery('kak');
    expect(c.read(filteredCatalogProvider).single.foods.single, kaki);
  });

  test('erreur du catalogue propagée par foods', () async {
    final c = ProviderContainer(
      overrides: [
        foodCatalogProvider.overrideWith((ref) async => throw StateError('KO')),
        customFoodsProvider.overrideWith((ref) => Stream.value(const [])),
      ],
    );
    addTearDown(c.dispose);
    c.listen(foodsProvider, (_, _) {});
    await expectLater(c.read(foodCatalogProvider.future), throwsStateError);
    await c.read(customFoodsProvider.future);
    expect(c.read(foodsProvider), isA<AsyncError<Map<String, Food>>>());
  });

  test('erreur du repository catalogue propagée par foods', () async {
    final c = ProviderContainer(
      overrides: [
        foodCatalogRepositoryProvider.overrideWithValue(
          _FailingFoodCatalogRepository(),
        ),
        customFoodsProvider.overrideWith((ref) => Stream.value(const [])),
      ],
    );
    addTearDown(c.dispose);
    c.listen(foodsProvider, (_, _) {});
    await expectLater(
      c.read(foodCatalogProvider.future),
      throwsA(isA<Failure>()),
    );
    await c.read(customFoodsProvider.future);
    final result = c.read(foodsProvider);
    expect(result, isA<AsyncError<Map<String, Food>>>());
    expect((result as AsyncError<Map<String, Food>>).error, isA<Failure>());
  });

  test('erreur du flux customFoods propagée par foods', () async {
    final c = ProviderContainer(
      overrides: [
        foodCatalogProvider.overrideWith((ref) async => catalogFixture()),
        customFoodsProvider.overrideWith(
          (ref) => Stream<List<Food>>.error(StateError('KO')),
        ),
      ],
    );
    addTearDown(c.dispose);
    c.listen(foodsProvider, (_, _) {});
    await c.read(foodCatalogProvider.future);
    await expectLater(c.read(customFoodsProvider.future), throwsStateError);
    expect(c.read(foodsProvider), isA<AsyncError<Map<String, Food>>>());
  });
}
