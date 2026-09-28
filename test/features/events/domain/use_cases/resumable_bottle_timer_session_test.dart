import 'package:colette/features/events/domain/entities/bottle_timer_run.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_session.dart';
import 'package:colette/features/events/domain/use_cases/resumable_bottle_timer_session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/care_event_factory.dart';
import '../../../../helpers/in_memory_bottle_timer_session_repository.dart';

void main() {
  final start = DateTime(2026, 9, 28, 2);
  final session = BottleTimerSession(
    run: BottleTimerRun.startingAt(start),
    draft: makeEvent(startAt: start),
    editing: false,
  );

  test('aucune session : null, rien effacé', () async {
    final repo = InMemoryBottleTimerSessionRepository();
    final result = await resumableBottleTimerSession(
      repository: repo,
      now: start,
    );
    expect(result, isNull);
    expect(repo.clears, 0);
  });

  test('session récente : renvoyée et conservée', () async {
    final repo = InMemoryBottleTimerSessionRepository(session: session);
    final result = await resumableBottleTimerSession(
      repository: repo,
      now: start.add(const Duration(hours: 1)),
    );
    expect(result, session);
    expect(repo.session, session);
  });

  test('session expirée : null et effacée', () async {
    final repo = InMemoryBottleTimerSessionRepository(session: session);
    final result = await resumableBottleTimerSession(
      repository: repo,
      now: start.add(const Duration(hours: 13)),
    );
    expect(result, isNull);
    expect(repo.session, isNull);
  });

  test('session illisible : null et effacée', () async {
    final repo = InMemoryBottleTimerSessionRepository(failLoad: true);
    final result = await resumableBottleTimerSession(
      repository: repo,
      now: start,
    );
    expect(result, isNull);
    expect(repo.clears, 1);
  });
}
