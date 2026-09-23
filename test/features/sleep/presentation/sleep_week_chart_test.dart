import 'package:colette/features/sleep/presentation/widgets/sleep_week_chart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dayFraction place une heure sur la journée', () {
    final day = DateTime(2026, 9, 23);
    final next = DateTime(2026, 9, 24);
    expect(SleepRowPainter.dayFraction(day, day, next), 0);
    expect(
      SleepRowPainter.dayFraction(DateTime(2026, 9, 23, 6), day, next),
      0.25,
    );
    expect(SleepRowPainter.dayFraction(next, day, next), 1);
  });
}
