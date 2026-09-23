import 'package:colette/features/sleep/data/repositories/firestore_sleep_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/sleep_session_factory.dart';

void main() {
  const code = 'ABCDEFGH';
  final a = makeSleep(
    id: 'a',
    startAt: DateTime(2026, 9, 22, 13),
    endAt: DateTime(2026, 9, 22, 14),
  );
  final b = makeSleep(
    id: 'b',
    startAt: DateTime(2026, 9, 23, 9),
    endAt: DateTime(2026, 9, 23, 10),
  );
  final c = makeSleep(id: 'c', startAt: DateTime(2026, 9, 23, 15));

  Future<FirestoreSleepRepository> seeded() async {
    final repo = FirestoreSleepRepository(FakeFirebaseFirestore());
    for (final s in [a, b, c]) {
      await repo.save(code, s);
    }
    return repo;
  }

  test(
    'watchStartedSince filtre et trie du plus récent au plus ancien',
    () async {
      final repo = await seeded();
      final list = await repo
          .watchStartedSince(code, DateTime(2026, 9, 23))
          .first;
      expect(list.map((s) => s.id), ['c', 'b']);
    },
  );

  test(
    'watchLatest renvoie le dernier par startAt, null sans sommeil',
    () async {
      expect(
        await FirestoreSleepRepository(FakeFirebaseFirestore())
            .watchLatest(code)
            .first,
        isNull,
      );
      final repo = await seeded();
      expect(await repo.watchLatest(code).first, c);
    },
  );

  test('getStartedBetween borne [from, to[', () async {
    final repo = await seeded();
    final result = await repo.getStartedBetween(
      code,
      from: DateTime(2026, 9, 22, 13),
      to: DateTime(2026, 9, 23, 15),
    );
    expect(result.getRight().toNullable()!.map((s) => s.id), ['b', 'a']);
  });

  test('wakeUp ferme un sommeil et supprime les doublons en lot', () async {
    final repo = await seeded();
    final dup = makeSleep(id: 'd', startAt: DateTime(2026, 9, 23, 15, 1));
    await repo.save(code, dup);
    final closed = c.copyWith(endAt: DateTime(2026, 9, 23, 16));
    final result = await repo.wakeUp(code, close: closed, deleteIds: ['d']);
    expect(result.isRight(), isTrue);
    final list = await repo
        .watchStartedSince(code, DateTime(2026, 9, 23))
        .first;
    expect(list, [closed, b]);
  });

  test('delete retire le sommeil', () async {
    final repo = await seeded();
    await repo.delete(code, 'b');
    final list = await repo.watchStartedSince(code, DateTime(2026, 9, 1)).first;
    expect(list.map((s) => s.id), ['c', 'a']);
  });
}
