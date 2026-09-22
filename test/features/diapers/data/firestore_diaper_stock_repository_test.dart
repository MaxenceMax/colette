import 'package:colette/features/diapers/data/repositories/firestore_diaper_stock_repository.dart';
import 'package:colette/features/diapers/domain/entities/diaper_stock.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const code = 'ABCDEFGH';
  final stock = DiaperStock(count: 44, countedAt: DateTime(2026, 9, 20, 10));

  test('watchStock émet null tant que rien n\'est écrit', () async {
    final repo = FirestoreDiaperStockRepository(FakeFirebaseFirestore());
    expect(await repo.watchStock(code).first, isNull);
  });

  test('saveStock puis watchStock renvoie le stock', () async {
    final repo = FirestoreDiaperStockRepository(FakeFirebaseFirestore());
    await repo.saveStock(code, stock);
    expect(await repo.watchStock(code).first, stock);
  });

  test('saveStock fusionne sans effacer les autres champs du foyer', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('households').doc(code).set({
      'baby': {'name': 'Colette'},
    });
    final repo = FirestoreDiaperStockRepository(db);
    await repo.saveStock(code, stock);
    final data = (await db.collection('households').doc(code).get()).data()!;
    expect((data['baby'] as Map)['name'], 'Colette');
    expect((data['diaperStock'] as Map)['count'], 44);
  });
}
