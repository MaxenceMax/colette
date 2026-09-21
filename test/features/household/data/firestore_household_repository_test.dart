import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/household/data/firestore_household_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 21, 10);

  test('create écrit le document du foyer avec createdAt', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreHouseholdRepository(db, FixedClock(now));
    final result = await repo.create('ABCDEFGH');
    expect(result.getRight().toNullable()?.code, 'ABCDEFGH');
    final doc = await db.collection('households').doc('ABCDEFGH').get();
    expect(doc.exists, isTrue);
  });

  test('join renvoie NotFoundFailure pour un code inconnu', () async {
    final repo = FirestoreHouseholdRepository(
      FakeFirebaseFirestore(),
      FixedClock(now),
    );
    final result = await repo.join('ZZZZZZZZ');
    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
  });

  test('join renvoie le foyer existant', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreHouseholdRepository(db, FixedClock(now));
    await repo.create('ABCDEFGH');
    final result = await repo.join('ABCDEFGH');
    expect(result.getRight().toNullable()?.createdAt, now);
  });
}
