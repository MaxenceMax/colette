import 'package:colette/features/diversification/data/repositories/firestore_tastings_repository.dart';
import 'package:colette/features/diversification/domain/entities/liking.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const code = 'ABCDEFGH';
  late FakeFirebaseFirestore db;
  late FirestoreTastingsRepository repo;

  CollectionReference<Map<String, dynamic>> tastings() =>
      db.collection('households').doc(code).collection('tastings');

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreTastingsRepository(db);
  });

  final full = Tasting(
    id: 't1',
    foodId: 'carotte',
    at: DateTime(2027, 4, 10, 12, 5),
    liking: Liking.loved,
    hadReaction: true,
    note: 'Rougeurs',
  );

  test('save puis watchAll : aller-retour complet', () async {
    await repo.save(code, full);
    expect(await repo.watchAll(code).first, [full]);
  });

  test('champs optionnels absents du document', () async {
    await repo.save(
      code,
      Tasting(id: 't2', foodId: 'miel', at: DateTime(2027, 4, 10)),
    );
    final data = (await tastings().doc('t2').get()).data()!;
    expect(data.containsKey('liking'), isFalse);
    expect(data.containsKey('note'), isFalse);
    expect(data['hadReaction'], isFalse);
    expect(data['at'], isA<Timestamp>());
  });

  test('save remplace : retirer l\'appréciation l\'efface', () async {
    await repo.save(code, full);
    await repo.save(code, full.copyWith(liking: null));
    expect((await repo.watchAll(code).first).single.liking, isNull);
  });

  test('tri par at décroissant', () async {
    await repo.save(code, full.copyWith(id: 'a', at: DateTime(2027, 4, 1)));
    await repo.save(code, full.copyWith(id: 'b', at: DateTime(2027, 4, 3)));
    expect((await repo.watchAll(code).first).map((t) => t.id), ['b', 'a']);
  });

  test(
    'lecture tolérante : liking inconnu, document invalide ignoré',
    () async {
      await tastings().doc('x').set({
        'foodId': 'carotte',
        'at': Timestamp.fromDate(DateTime(2027, 4, 2)),
        'liking': 'adored',
      });
      await tastings().doc('y').set({'foodId': 'carotte', 'at': 'hier'});
      final list = await repo.watchAll(code).first;
      expect(list.single.id, 'x');
      expect(list.single.liking, isNull);
      expect(list.single.hadReaction, isFalse);
    },
  );

  test('delete', () async {
    await repo.save(code, full);
    await repo.delete(code, 't1');
    expect(await repo.watchAll(code).first, isEmpty);
  });
}
