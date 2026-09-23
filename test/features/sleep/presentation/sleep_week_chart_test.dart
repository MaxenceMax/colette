import 'package:colette/features/sleep/domain/entities/sleep_day.dart';
import 'package:colette/features/sleep/presentation/widgets/sleep_week_chart.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

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

  testWidgets(
    'la ligne d\'un jour porte un label d\'accessibilité "jour : total"',
    (tester) async {
      final handle = tester.ensureSemantics();
      final day = SleepDay(
        day: DateTime(2026, 9, 23),
        segments: const [],
        total: const Duration(hours: 1, minutes: 30),
        napCount: 0,
        longest: const Duration(hours: 1, minutes: 30),
      );
      await pumpApp(
        tester,
        SleepWeekRow(day: day, selected: false, onTap: () {}),
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^Mercredi 23 septembre : 1 h 30')),
        findsOneWidget,
      );
      handle.dispose();
    },
  );
}
