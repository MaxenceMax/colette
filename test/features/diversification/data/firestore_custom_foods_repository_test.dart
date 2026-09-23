import 'package:colette/features/diversification/data/repositories/firestore_custom_foods_repository.dart';
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const code = 'ABCDEFGH';
  late FakeFirebaseFirestore db;
  late FirestoreCustomFoodsRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreCustomFoodsRepository(db);
  });

  const kaki = Food(
    id: 'c1',
    name: 'Kaki séché',
    group: FoodGroup.vitaminAFruitsVeg,
    allergens: {Allergen.sulphites},
    isCustom: true,
  );

  test('save puis watchAll', () async {
    await repo.save(code, kaki);
    expect(await repo.watchAll(code).first, [kaki]);
  });

  test(
    'lecture tolérante : groupe et allergène inconnus, nom vide ignoré',
    () async {
      final foods = db
          .collection('households')
          .doc(code)
          .collection('customFoods');
      await foods.doc('a').set({
        'name': 'Datte',
        'group': 'fruits',
        'allergens': ['milk', 'nuts'],
      });
      await foods.doc('b').set({'name': '  ', 'group': 'dairy'});
      final list = await repo.watchAll(code).first;
      expect(list.single.name, 'Datte');
      expect(list.single.group, FoodGroup.outsideGroups);
      expect(list.single.allergens, {Allergen.milk});
      expect(list.single.isCustom, isTrue);
    },
  );

  test('delete', () async {
    await repo.save(code, kaki);
    await repo.delete(code, 'c1');
    expect(await repo.watchAll(code).first, isEmpty);
  });
}
