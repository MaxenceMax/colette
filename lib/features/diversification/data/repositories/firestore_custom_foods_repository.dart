import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/firebase/firestore_paths.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/diversification/data/dtos/custom_food_dto.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/repositories/custom_foods_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Aliments perso dans `households/{code}/customFoods`.
class FirestoreCustomFoodsRepository implements CustomFoodsRepository {
  FirestoreCustomFoodsRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _foods(String code) => _db
      .collection(FirestorePaths.households)
      .doc(code)
      .collection(FirestorePaths.customFoods);

  @override
  Stream<List<Food>> watchAll(String householdCode) => _foods(householdCode)
      .snapshots()
      .map(
        (snap) => [for (final doc in snap.docs) ?CustomFoodDto.fromDoc(doc)],
      );

  @override
  Future<Either<Failure, void>> save(String householdCode, Food food) => guard(
    () => _foods(householdCode).doc(food.id).set(CustomFoodDto.toMap(food)),
  );

  @override
  Future<Either<Failure, void>> delete(String householdCode, String foodId) =>
      guard(() => _foods(householdCode).doc(foodId).delete());
}
