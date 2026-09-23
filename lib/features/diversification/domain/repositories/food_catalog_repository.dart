import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diversification/domain/entities/food_catalog.dart';
import 'package:fpdart/fpdart.dart';

/// Catalogue d'aliments embarqué.
abstract interface class FoodCatalogRepository {
  Future<Either<Failure, FoodCatalog>> load();
}
