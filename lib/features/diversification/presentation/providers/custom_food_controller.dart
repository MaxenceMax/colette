import 'dart:async';

import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/domain/use_cases/validate_custom_food.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'custom_food_controller.g.dart';

/// Création, modification et suppression d'un aliment perso.
@riverpod
class CustomFoodController extends _$CustomFoodController {
  @override
  FutureOr<void> build() {
    // Garde les sources en vie tant que le contrôleur est écouté : `save` et
    // `delete` en ont besoin même quand rien d'autre ne les watch (ex. feuille
    // ouverte depuis un Scaffold nu, cf. `CustomFoodSheet`).
    ref
      ..listen(customFoodsProvider, (_, _) {})
      ..listen(tastingsProvider, (_, _) {});
  }

  /// Crée ([id] `null`) ou remplace l'aliment ; le nom doit être unique parmi
  /// le catalogue et les autres aliments perso.
  Future<bool> save({
    String? id,
    required String name,
    required FoodGroup group,
    required Set<Allergen> allergens,
  }) async {
    final List<String> existingNames;
    try {
      final catalog = await ref.read(foodCatalogProvider.future);
      final custom = await ref.read(customFoodsProvider.future);
      existingNames = [
        for (final food in [...catalog.foods, ...custom])
          if (food.id != id && !food.isUnknown) food.name,
      ];
    } on Object catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
      return false;
    }
    final reason = const ValidateCustomFood()(
      name: name,
      existingNames: existingNames,
    );
    if (reason != null) return _reject(reason);
    final food = Food(
      id: id ?? ref.read(idGeneratorProvider).newId(),
      name: name.trim(),
      group: group,
      allergens: allergens,
      isCustom: true,
    );
    return _run(
      (code) => ref.read(customFoodsRepositoryProvider).save(code, food),
    );
  }

  /// Supprime l'aliment ; refusé s'il a au moins une dégustation.
  Future<bool> delete(String foodId) async {
    final List<Tasting> tastings;
    try {
      tastings = await ref.read(tastingsProvider.future);
    } on Object catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
      return false;
    }
    if (tastings.any((tasting) => tasting.foodId == foodId)) {
      return _reject(ValidationReason.customFoodInUse);
    }
    return _run(
      (code) => ref.read(customFoodsRepositoryProvider).delete(code, foodId),
    );
  }

  bool _reject(ValidationReason reason) {
    if (ref.mounted) {
      state = AsyncError(ValidationFailure(reason), StackTrace.current);
    }
    return false;
  }

  Future<bool> _run(
    Future<Either<Failure, void>> Function(String code) action,
  ) async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return false;
    state = const AsyncLoading();
    final result = await action(code);
    if (ref.mounted) {
      state = result.fold(
        (failure) => AsyncError(failure, StackTrace.current),
        (_) => const AsyncData(null),
      );
    }
    return result.isRight();
  }
}
