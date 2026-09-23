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
  FutureOr<void> build() {}

  /// Crée ([id] `null`) ou remplace l'aliment ; le nom doit être unique parmi
  /// le catalogue et les autres aliments perso.
  Future<bool> save({
    String? id,
    required String name,
    required FoodGroup group,
    required Set<Allergen> allergens,
  }) async {
    final foods = ref.read(foodsProvider).value ?? const <String, Food>{};
    final reason = const ValidateCustomFood()(
      name: name,
      existingNames: [
        for (final food in foods.values)
          if (food.id != id && !food.isUnknown) food.name,
      ],
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
    final tastings = ref.read(tastingsProvider).value ?? const <Tasting>[];
    if (tastings.any((tasting) => tasting.foodId == foodId)) {
      return _reject(ValidationReason.customFoodInUse);
    }
    return _run(
      (code) => ref.read(customFoodsRepositoryProvider).delete(code, foodId),
    );
  }

  bool _reject(ValidationReason reason) {
    state = AsyncError(ValidationFailure(reason), StackTrace.current);
    return false;
  }

  Future<bool> _run(
    Future<Either<Failure, void>> Function(String code) action,
  ) async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return false;
    state = const AsyncLoading();
    final result = await action(code);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    return result.isRight();
  }
}
