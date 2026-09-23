import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/liking.dart';
import 'package:colette/features/diversification/domain/entities/rule_source.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Libellés des groupes alimentaires.
extension FoodGroupLabels on FoodGroup {
  String label(S s) => switch (this) {
    FoodGroup.grainsRootsTubers => s.foodGroupGrains,
    FoodGroup.legumesNutsSeeds => s.foodGroupLegumes,
    FoodGroup.dairy => s.foodGroupDairy,
    FoodGroup.fleshFoods => s.foodGroupFlesh,
    FoodGroup.eggs => s.foodGroupEggs,
    FoodGroup.vitaminAFruitsVeg => s.foodGroupVitaminA,
    FoodGroup.otherFruitsVeg => s.foodGroupOtherFruitsVeg,
    FoodGroup.outsideGroups => s.foodGroupOutside,
  };

  /// Libellé court, pour les puces.
  String shortLabel(S s) => switch (this) {
    FoodGroup.grainsRootsTubers => s.foodGroupShortGrains,
    FoodGroup.legumesNutsSeeds => s.foodGroupShortLegumes,
    FoodGroup.dairy => s.foodGroupShortDairy,
    FoodGroup.fleshFoods => s.foodGroupShortFlesh,
    FoodGroup.eggs => s.foodGroupShortEggs,
    FoodGroup.vitaminAFruitsVeg => s.foodGroupShortVitaminA,
    FoodGroup.otherFruitsVeg => s.foodGroupShortOtherFruitsVeg,
    FoodGroup.outsideGroups => s.foodGroupShortOutside,
  };
}

/// Libellés des allergènes.
extension AllergenLabels on Allergen {
  String label(S s) => switch (this) {
    Allergen.milk => s.allergenMilk,
    Allergen.eggs => s.allergenEggs,
    Allergen.gluten => s.allergenGluten,
    Allergen.peanut => s.allergenPeanut,
    Allergen.treeNuts => s.allergenTreeNuts,
    Allergen.fish => s.allergenFish,
    Allergen.crustaceans => s.allergenCrustaceans,
    Allergen.sesame => s.allergenSesame,
    Allergen.soy => s.allergenSoy,
    Allergen.celery => s.allergenCelery,
    Allergen.mustard => s.allergenMustard,
    Allergen.sulphites => s.allergenSulphites,
    Allergen.lupin => s.allergenLupin,
    Allergen.molluscs => s.allergenMolluscs,
  };
}

/// Libellés et icônes des appréciations.
extension LikingLabels on Liking {
  String label(S s) => switch (this) {
    Liking.loved => s.likingLoved,
    Liking.meh => s.likingMeh,
    Liking.refused => s.likingRefused,
  };

  IconData get icon => switch (this) {
    Liking.loved => Icons.sentiment_satisfied_alt_outlined,
    Liking.meh => Icons.sentiment_neutral_outlined,
    Liking.refused => Icons.sentiment_dissatisfied_outlined,
  };
}

/// Libellés courts des sources.
extension RuleSourceLabels on RuleSource {
  String label(S s) => switch (this) {
    RuleSource.oms => s.sourceOms,
    RuleSource.anses => s.sourceAnses,
    RuleSource.spf => s.sourceSpf,
    RuleSource.espghan => s.sourceEspghan,
    RuleSource.agriculture => s.sourceAgriculture,
    RuleSource.efsa => s.sourceEfsa,
  };
}

/// « OMS, Anses ».
String sourcesLabel(Iterable<RuleSource> sources, S s) =>
    sources.map((source) => source.label(s)).join(', ');

/// « 1 an », « 5 ans » ou « 8 mois ».
String ageLimitLabel(int months, S s) =>
    months % 12 == 0 ? s.ageYears(months ~/ 12) : s.ageMonths(months);

/// Nom affiché : « Aliment inconnu » pour un aliment introuvable.
String foodDisplayName(Food food, S s) =>
    food.isUnknown ? s.foodUnknown : food.name;
