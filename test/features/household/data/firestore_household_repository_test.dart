import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/household/data/firestore_household_repository.dart';
import 'package:colette/features/household/domain/entities/household.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ignore: subtype_of_sealed_class
class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockSnapshotMetadata extends Mock implements SnapshotMetadata {}

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

  // fake_cloud_firestore ne simule pas `isFromCache` sur un simple `.get()`
  // (il faudrait un vrai SDK ou une connexion) : la fonction de mapping est
  // testée séparément avec un instantané construit à la main.
  group('mapJoinSnapshot', () {
    test('hors ligne sans document en cache local : NetworkFailure', () {
      final snap = MockDocumentSnapshot();
      final metadata = MockSnapshotMetadata();
      when(() => snap.exists).thenReturn(false);
      when(() => snap.metadata).thenReturn(metadata);
      when(() => metadata.isFromCache).thenReturn(true);
      final result = FirestoreHouseholdRepository.mapJoinSnapshot(
        'ABCDEFGH',
        snap,
        FixedClock(now),
      );
      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    });

    test('en ligne sans document : NotFoundFailure', () {
      final snap = MockDocumentSnapshot();
      final metadata = MockSnapshotMetadata();
      when(() => snap.exists).thenReturn(false);
      when(() => snap.metadata).thenReturn(metadata);
      when(() => metadata.isFromCache).thenReturn(false);
      final result = FirestoreHouseholdRepository.mapJoinSnapshot(
        'ABCDEFGH',
        snap,
        FixedClock(now),
      );
      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });

    test('document sans createdAt : utilise l\'horloge au lieu de planter', () {
      final snap = MockDocumentSnapshot();
      when(() => snap.exists).thenReturn(true);
      when(() => snap.data()).thenReturn(<String, dynamic>{});
      final result = FirestoreHouseholdRepository.mapJoinSnapshot(
        'ABCDEFGH',
        snap,
        FixedClock(now),
      );
      expect(
        result.getRight().toNullable(),
        Household(code: 'ABCDEFGH', createdAt: now),
      );
    });

    test('document avec createdAt : le convertit', () {
      final snap = MockDocumentSnapshot();
      when(() => snap.exists).thenReturn(true);
      when(() => snap.data())
          .thenReturn(<String, dynamic>{'createdAt': Timestamp.fromDate(now)});
      final result = FirestoreHouseholdRepository.mapJoinSnapshot(
        'ABCDEFGH',
        snap,
        FixedClock(DateTime(2099)),
      );
      expect(
        result.getRight().toNullable(),
        Household(code: 'ABCDEFGH', createdAt: now),
      );
    });
  });
}
