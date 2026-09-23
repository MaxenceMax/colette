import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/sleep_session_factory.dart';

void main() {
  final start = DateTime(2026, 9, 23, 14);

  test('un sommeil sans fin est en cours et dure jusqu\'à maintenant', () {
    final sleep = makeSleep(startAt: start);
    expect(sleep.isOngoing, isTrue);
    expect(
      sleep.durationUntil(DateTime(2026, 9, 23, 14, 42)),
      const Duration(minutes: 42),
    );
  });

  test('un sommeil terminé garde sa durée', () {
    final sleep = makeSleep(
      startAt: start,
      endAt: DateTime(2026, 9, 23, 15, 30),
    );
    expect(sleep.isOngoing, isFalse);
    expect(
      sleep.durationUntil(DateTime(2026, 9, 23, 20)),
      const Duration(minutes: 90),
    );
  });
}
