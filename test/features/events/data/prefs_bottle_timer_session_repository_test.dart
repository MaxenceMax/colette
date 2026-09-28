import 'package:colette/features/events/data/repositories/prefs_bottle_timer_session_repository.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_run.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/care_event_factory.dart';

void main() {
  final start = DateTime(2026, 9, 28, 2, 5);
  final session = BottleTimerSession(
    run: BottleTimerRun(
      startedAt: start,
      feedingEndsAt: start.add(const Duration(minutes: 21)),
    ),
    draft: makeEvent(startAt: start, bottleMl: 150, pee: true, note: 'rot'),
    editing: true,
  );

  Future<PrefsBottleTimerSessionRepository> repoWith(
    Map<String, Object> values,
  ) async {
    SharedPreferences.setMockInitialValues(values);
    return PrefsBottleTimerSessionRepository(
      await SharedPreferences.getInstance(),
    );
  }

  test('sans session : Right(null)', () async {
    final repo = await repoWith({});
    final loaded = await repo.load();
    expect(loaded.isRight(), isTrue);
    expect(loaded.toNullable(), isNull);
  });

  test('save puis load : aller-retour complet', () async {
    final repo = await repoWith({});
    await repo.save(session);
    expect((await repo.load()).toNullable(), session);
  });

  test('clear efface la session', () async {
    final repo = await repoWith({});
    await repo.save(session);
    await repo.clear();
    expect((await repo.load()).toNullable(), isNull);
  });

  test('JSON corrompu : Left', () async {
    final repo = await repoWith({
      PrefsBottleTimerSessionRepository.key: '{"run":',
    });
    expect((await repo.load()).isLeft(), isTrue);
  });
}
