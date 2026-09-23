import 'package:colette/features/sleep/domain/use_cases/plan_wake_up.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/sleep_session_factory.dart';

void main() {
  final now = DateTime(2026, 9, 23, 16);

  test('aucun sommeil ouvert : rien à faire', () {
    expect(planWakeUp(const [], now), isNull);
  });

  test('ferme le plus ancien et supprime les doublons', () {
    final first = makeSleep(id: 'a', startAt: DateTime(2026, 9, 23, 15));
    final dup = makeSleep(id: 'b', startAt: DateTime(2026, 9, 23, 15, 1));
    final plan = planWakeUp([dup, first], now)!;
    expect(plan.close, first.copyWith(endAt: now, updatedAt: now));
    expect(plan.deleteIds, ['b']);
  });

  test('un seul ouvert : aucune suppression', () {
    final only = makeSleep(id: 'a', startAt: DateTime(2026, 9, 23, 15));
    expect(planWakeUp([only], now)!.deleteIds, isEmpty);
  });
}
