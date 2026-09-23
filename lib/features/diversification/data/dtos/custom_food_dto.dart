import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';

/// Conversion aliment perso ↔ document `customFoods/{id}`.
abstract final class CustomFoodDto {
  static Map<String, dynamic> toMap(Food food) => {
    'name': food.name,
    'group': food.group.name,
    'allergens': [for (final allergen in food.allergens) allergen.name],
  };

  /// `null` (journalisé) sans nom ; groupe inconnu lu « hors groupes »,
  /// allergènes inconnus ignorés.
  static Food? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final name = data?['name'];
    if (data == null || name is! String || name.trim().isEmpty) {
      developer.log('Aliment perso ${doc.id} ignoré', name: 'colette');
      return null;
    }
    final allergens = data['allergens'];
    return Food(
      id: doc.id,
      name: name.trim(),
      group:
          FoodGroup.values.asNameMap()[data['group']] ??
          FoodGroup.outsideGroups,
      allergens: {
        if (allergens is List)
          for (final value in allergens) ?Allergen.values.asNameMap()[value],
      },
      isCustom: true,
    );
  }
}
