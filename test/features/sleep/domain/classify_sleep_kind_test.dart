import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:colette/features/sleep/domain/use_cases/classify_sleep_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SleepKind at(int hour, int minute, {int start = 20, int end = 7}) =>
      classifySleepKind(
        DateTime(2026, 9, 23, hour, minute),
        nightStartHour: start,
        nightEndHour: end,
      );

  test('fenêtre qui passe minuit (20 → 7)', () {
    expect(at(19, 59), SleepKind.nap);
    expect(at(20, 0), SleepKind.night);
    expect(at(2, 30), SleepKind.night);
    expect(at(6, 59), SleepKind.night);
    expect(at(7, 0), SleepKind.nap);
    expect(at(14, 0), SleepKind.nap);
  });

  test('fenêtre dans la même journée (1 → 9)', () {
    expect(at(0, 59, start: 1, end: 9), SleepKind.nap);
    expect(at(1, 0, start: 1, end: 9), SleepKind.night);
    expect(at(8, 59, start: 1, end: 9), SleepKind.night);
    expect(at(9, 0, start: 1, end: 9), SleepKind.nap);
  });

  test('début égal à la fin : toujours sieste', () {
    expect(at(20, 0, start: 20, end: 20), SleepKind.nap);
    expect(at(3, 0, start: 20, end: 20), SleepKind.nap);
  });
}
