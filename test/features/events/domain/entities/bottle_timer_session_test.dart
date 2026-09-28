import 'package:colette/features/events/domain/entities/bottle_timer_run.dart';
import 'package:colette/features/events/domain/entities/bottle_timer_session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/care_event_factory.dart';

void main() {
  final start = DateTime(2026, 9, 28, 2);
  final session = BottleTimerSession(
    run: BottleTimerRun.startingAt(start),
    draft: makeEvent(startAt: start),
    editing: false,
  );

  test('pas expirée à 12 h pile', () {
    expect(session.isExpiredAt(start.add(const Duration(hours: 12))), isFalse);
  });

  test('expirée au-delà de 12 h', () {
    expect(
      session.isExpiredAt(start.add(const Duration(hours: 12, minutes: 1))),
      isTrue,
    );
  });
}
