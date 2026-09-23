import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/allergen_state.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';

/// État des 9 allergènes suivis : une réaction signalée l'emporte toujours,
/// sinon une dégustation sans réaction suffit à « introduit ».
class ComputeAllergenProgress {
  const ComputeAllergenProgress();

  Map<Allergen, AllergenState> call({
    required List<Tasting> tastings,
    required Map<String, Food> foodsById,
  }) {
    final states = {
      for (final allergen in Allergen.tracked) allergen: AllergenState.notYet,
    };
    for (final tasting in tastings) {
      final allergens = foodsById[tasting.foodId]?.allergens ?? const {};
      for (final allergen in allergens) {
        final current = states[allergen];
        if (current == null) continue;
        if (tasting.hadReaction) {
          states[allergen] = AllergenState.reaction;
        } else if (current == AllergenState.notYet) {
          states[allergen] = AllergenState.introduced;
        }
      }
    }
    return states;
  }
}
