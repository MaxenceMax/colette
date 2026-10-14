import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/teeth/data/repositories/firestore_teeth_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../teeth_factories.dart';

void main() {
  const code = 'ABCDEFGH';
  late FakeFirebaseFirestore db;
  late FirestoreTeethRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreTeethRepository(db);
  });

  CollectionReference<Map<String, dynamic>> teeth() =>
      db.collection('households').doc(code).collection('teeth');

  test('aller-retour d\'une dent complète', () async {
    final record = makeTooth(
      51,
      eruptedAt: DateTime(2027, 1, 10, 12),
      lostAt: DateTime(2033, 5, 2, 12),
      note: 'Nuit agitée',
    );
    expect((await repo.saveTooth(code, record)).isRight(), isTrue);
    expect(await repo.watchTeeth(code).first, [record]);
    expect((await teeth().doc('51').get()).exists, isTrue);
  });

  test('dent partielle : clés absentes plutôt que nulles', () async {
    await repo.saveTooth(
      code,
      makeTooth(71, eruptedAt: DateTime(2027, 1, 10, 12)),
    );
    final data = (await teeth().doc('71').get()).data()!;
    expect(data.keys.toSet(), {'eruptedAt', 'updatedAt', 'updatedByDeviceId'});
  });

  test('ignore un numéro inconnu et un document illisible', () async {
    await teeth().doc('99').set({
      'updatedAt': Timestamp.fromDate(DateTime(2026, 10, 14)),
    });
    await teeth().doc('52').set({'note': 'sans date de mise à jour'});
    await repo.saveTooth(
      code,
      makeTooth(61, eruptedAt: DateTime(2027, 2, 1, 12)),
    );
    final records = await repo.watchTeeth(code).first;
    expect([for (final r in records) r.toothId], [tooth(61)]);
  });

  test('supprime une dent', () async {
    await repo.saveTooth(code, makeTooth(51, note: 'x'));
    expect((await repo.deleteTooth(code, tooth(51))).isRight(), isTrue);
    expect(await repo.watchTeeth(code).first, isEmpty);
    expect((await teeth().doc('51').get()).exists, isFalse);
  });
}
