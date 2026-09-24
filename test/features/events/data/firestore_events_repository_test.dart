import 'package:colette/features/events/data/repositories/firestore_events_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/care_event_factory.dart';

void main() {
  const code = 'ABCDEFGH';
  final day = DateTime(2026, 9, 21);

  test(
    'watchLatest trie du plus récent au plus ancien et respecte la limite',
    () async {
      final repo = FirestoreEventsRepository(FakeFirebaseFirestore());
      await repo.save(
        code,
        makeEvent(
          id: 'a',
          startAt: day.add(const Duration(hours: 8)),
          pee: true,
        ),
      );
      await repo.save(
        code,
        makeEvent(
          id: 'b',
          startAt: day.add(const Duration(hours: 11)),
          pee: true,
        ),
      );
      await repo.save(
        code,
        makeEvent(
          id: 'c',
          startAt: day.add(const Duration(hours: 14)),
          pee: true,
        ),
      );
      final latest = await repo.watchLatest(code, limit: 2).first;
      expect(latest.map((e) => e.id), ['c', 'b']);
    },
  );

  test('watchBetween ne renvoie que les événements du jour', () async {
    final repo = FirestoreEventsRepository(FakeFirebaseFirestore());
    await repo.save(
      code,
      makeEvent(
        id: 'hier',
        startAt: day.subtract(const Duration(hours: 2)),
        pee: true,
      ),
    );
    await repo.save(
      code,
      makeEvent(
        id: 'today',
        startAt: day.add(const Duration(hours: 9)),
        pee: true,
      ),
    );
    await repo.save(
      code,
      makeEvent(
        id: 'demain',
        startAt: day.add(const Duration(hours: 25)),
        pee: true,
      ),
    );
    final today = await repo
        .watchBetween(code, from: day, to: day.add(const Duration(days: 1)))
        .first;
    expect(today.map((e) => e.id), ['today']);
  });

  test(
    'watchLatestBottle et getLatestBottle renvoient le dernier biberon',
    () async {
      final repo = FirestoreEventsRepository(FakeFirebaseFirestore());
      await repo.save(
        code,
        makeEvent(
          id: 'b1',
          startAt: day.add(const Duration(hours: 8)),
          bottleMl: 90,
        ),
      );
      await repo.save(
        code,
        makeEvent(
          id: 'bath',
          startAt: day.add(const Duration(hours: 9)),
          bath: true,
        ),
      );
      await repo.save(
        code,
        makeEvent(
          id: 'b2',
          startAt: day.add(const Duration(hours: 11)),
          bottleMl: 120,
        ),
      );
      expect((await repo.watchLatestBottle(code).first)?.id, 'b2');
      expect(
        (await repo.getLatestBottle(code)).getRight().toNullable()?.id,
        'b2',
      );
    },
  );

  test('save écrase un événement existant et delete le retire', () async {
    final repo = FirestoreEventsRepository(FakeFirebaseFirestore());
    final event = makeEvent(
      id: 'e',
      startAt: day.add(const Duration(hours: 8)),
      pee: true,
    );
    await repo.save(code, event);
    await repo.save(code, event.copyWith(poop: true, note: 'ok'));
    var latest = await repo.watchLatest(code, limit: 10).first;
    expect(latest.single.poop, isTrue);
    expect(latest.single.note, 'ok');
    await repo.delete(code, 'e');
    latest = await repo.watchLatest(code, limit: 10).first;
    expect(latest, isEmpty);
  });

  test(
    'watchDiaperChangeCountSince ne compte que les changes à partir de from',
    () async {
      final repo = FirestoreEventsRepository(FakeFirebaseFirestore());
      final from = day.add(const Duration(hours: 10));
      await repo.save(
        code,
        makeEvent(
          id: 'avant',
          startAt: day.add(const Duration(hours: 8)),
          diaperChange: true,
        ),
      );
      await repo.save(
        code,
        makeEvent(id: 'pile', startAt: from, diaperChange: true),
      );
      await repo.save(
        code,
        makeEvent(
          id: 'apres',
          startAt: day.add(const Duration(hours: 14)),
          diaperChange: true,
        ),
      );
      await repo.save(
        code,
        makeEvent(
          id: 'pipi',
          startAt: day.add(const Duration(hours: 15)),
          pee: true,
        ),
      );
      expect(await repo.watchDiaperChangeCountSince(code, from: from).first, 2);
    },
  );

  test(
    'watchDiaperChangeCountSince se met à jour à l\'ajout et à la suppression',
    () async {
      final repo = FirestoreEventsRepository(FakeFirebaseFirestore());
      final from = day.add(const Duration(hours: 10));
      final stream = repo.watchDiaperChangeCountSince(code, from: from);
      final expectation = expectLater(stream, emitsInOrder([0, 1, 0]));
      await repo.save(
        code,
        makeEvent(
          id: 'c1',
          startAt: day.add(const Duration(hours: 12)),
          diaperChange: true,
        ),
      );
      await repo.delete(code, 'c1');
      await expectation;
    },
  );
}
