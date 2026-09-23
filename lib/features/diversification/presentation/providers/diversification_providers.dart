import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/result/no_retry.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/diversification/data/data_sources/catalog_asset_data_source.dart';
import 'package:colette/features/diversification/data/repositories/asset_food_catalog_repository.dart';
import 'package:colette/features/diversification/data/repositories/firestore_custom_foods_repository.dart';
import 'package:colette/features/diversification/data/repositories/firestore_tastings_repository.dart';
import 'package:colette/features/diversification/domain/entities/diversification_timeline.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_catalog.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/domain/repositories/custom_foods_repository.dart';
import 'package:colette/features/diversification/domain/repositories/food_catalog_repository.dart';
import 'package:colette/features/diversification/domain/repositories/tastings_repository.dart';
import 'package:colette/features/diversification/domain/use_cases/compute_diversification_phase.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'diversification_providers.g.dart';

/// Sans état et partagé : `keepAlive`.
@Riverpod(keepAlive: true)
FoodCatalogRepository foodCatalogRepository(Ref ref) =>
    AssetFoodCatalogRepository(CatalogAssetDataSource(rootBundle));

/// Sans état et partagé : `keepAlive`.
@Riverpod(keepAlive: true)
TastingsRepository tastingsRepository(Ref ref) =>
    FirestoreTastingsRepository(ref.watch(firestoreProvider));

/// Sans état et partagé : `keepAlive`.
@Riverpod(keepAlive: true)
CustomFoodsRepository customFoodsRepository(Ref ref) =>
    FirestoreCustomFoodsRepository(ref.watch(firestoreProvider));

/// Catalogue embarqué, chargé une fois ; la `Failure` éventuelle devient l'erreur.
@Riverpod(keepAlive: true, retry: noRetry)
Future<FoodCatalog> foodCatalog(Ref ref) async {
  final result = await ref.watch(foodCatalogRepositoryProvider).load();
  return result.fold((failure) => throw failure, (catalog) => catalog);
}

/// Dégustations du foyer courant, de la plus récente à la plus ancienne.
@Riverpod(retry: noRetry)
Stream<List<Tasting>> tastings(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(const []);
  return ref.watch(tastingsRepositoryProvider).watchAll(code);
}

/// Aliments perso du foyer courant.
@Riverpod(retry: noRetry)
Stream<List<Food>> customFoods(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(const []);
  return ref.watch(customFoodsRepositoryProvider).watchAll(code);
}

/// Catalogue et aliments perso indexés par id ; en erreur si l'une des sources l'est.
@riverpod
AsyncValue<Map<String, Food>> foods(Ref ref) =>
    switch ((ref.watch(foodCatalogProvider), ref.watch(customFoodsProvider))) {
      (AsyncError(:final error, :final stackTrace), _) ||
      (
        _,
        AsyncError(:final error, :final stackTrace),
      ) => AsyncError(error, stackTrace),
      (AsyncData(value: final catalog), AsyncData(value: final custom)) =>
        AsyncData({
          for (final food in catalog.foods) food.id: food,
          for (final food in custom) food.id: food,
        }),
      _ => const AsyncLoading(),
    };

/// Phase et âge de diversification ; `null` sans profil.
@riverpod
DiversificationTimeline? diversificationTimeline(Ref ref) {
  final profile = ref.watch(babyProfileProvider).value;
  if (profile == null) return null;
  return const ComputeDiversificationPhase()(
    birthDate: profile.birthDate,
    now: ref.watch(todayProvider),
  );
}
