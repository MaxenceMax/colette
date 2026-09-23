import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:fpdart/fpdart.dart';

/// Aliments ajoutés par le foyer.
abstract interface class CustomFoodsRepository {
  Stream<List<Food>> watchAll(String householdCode);

  /// Crée ou remplace l'aliment (clé : `food.id`).
  Future<Either<Failure, void>> save(String householdCode, Food food);

  Future<Either<Failure, void>> delete(String householdCode, String foodId);
}
