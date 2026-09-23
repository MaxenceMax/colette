import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_catalog.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/domain/repositories/custom_foods_repository.dart';
import 'package:colette/features/diversification/domain/repositories/tastings_repository.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import 'catalog_fixture.dart';

/// Repository de dégustations simulé.
class MockTastingsRepository extends Mock implements TastingsRepository {}

/// Repository d'aliments perso simulé.
class MockCustomFoodsRepository extends Mock implements CustomFoodsRepository {}

/// Née le 15 septembre 2026.
final testBirthDate = DateTime(2026, 9, 15);

/// 10 avril 2027 à 18 h : 6 mois révolus.
final testNow = DateTime(2027, 4, 10, 18);

/// Enregistre les valeurs de repli mocktail ; à appeler dans `setUpAll`.
void registerDiversificationFallbacks() {
  registerFallbackValue(Tasting(id: '', foodId: '', at: DateTime(2000)));
  registerFallbackValue(Food.unknown(''));
}

/// Mocks dont `save` et `delete` réussissent.
(MockTastingsRepository, MockCustomFoodsRepository) succeedingRepositories() {
  final tastings = MockTastingsRepository();
  final foods = MockCustomFoodsRepository();
  when(() => tastings.save(any(), any())).thenAnswer((_) async => right(null));
  when(() => tastings.delete(any(), any()))
      .thenAnswer((_) async => right(null));
  when(() => foods.save(any(), any())).thenAnswer((_) async => right(null));
  when(() => foods.delete(any(), any())).thenAnswer((_) async => right(null));
  return (tastings, foods);
}

/// Overrides pour monter un écran de la diversification en test.
List<Override> diversificationOverrides({
  DateTime? now,
  DateTime? birthDate,
  bool withProfile = true,
  List<Tasting> tastings = const [],
  List<Food> customFoods = const [],
  FoodCatalog? catalog,
  Object? catalogError,
  TastingsRepository? tastingsRepository,
  CustomFoodsRepository? customFoodsRepository,
}) => [
  foodCatalogProvider.overrideWith(
    (ref) async =>
        catalogError != null ? throw catalogError : catalog ?? catalogFixture(),
  ),
  tastingsProvider.overrideWith((ref) => Stream.value(tastings)),
  customFoodsProvider.overrideWith((ref) => Stream.value(customFoods)),
  babyProfileProvider.overrideWith(
    (ref) => Stream.value(
      withProfile
          ? BabyProfile(name: 'Colette', birthDate: birthDate ?? testBirthDate)
          : null,
    ),
  ),
  clockProvider.overrideWithValue(FixedClock(now ?? testNow)),
  minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
  idGeneratorProvider.overrideWithValue(const FixedIdGenerator('new-id')),
  householdLocalStoreProvider.overrideWithValue(
    InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
  ),
  if (tastingsRepository != null)
    tastingsRepositoryProvider.overrideWithValue(tastingsRepository),
  if (customFoodsRepository != null)
    customFoodsRepositoryProvider.overrideWithValue(customFoodsRepository),
];
