import 'package:colette/features/events/domain/entities/care_day_summary.dart';
import 'package:colette/features/events/domain/use_cases/summarize_care_days.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/care_event_factory.dart';

void main() {
  test('additionne le lait et compte biberons, couches et pipis par jour', () {
    final summaries = summarizeCareDays([
      makeEvent(id: 'a', startAt: DateTime(2026, 10, 20, 14), bottleMl: 120),
      makeEvent(
        id: 'b',
        startAt: DateTime(2026, 10, 20, 11),
        bottleMl: 90,
        diaperChange: true,
        pee: true,
      ),
      makeEvent(
        id: 'c',
        startAt: DateTime(2026, 10, 20, 0, 5),
        diaperChange: true,
      ),
      makeEvent(id: 'd', startAt: DateTime(2026, 10, 19, 23, 55), pee: true),
    ]);
    expect(summaries, {
      DateTime(2026, 10, 20): const CareDaySummary(
        bottleMl: 210,
        bottleCount: 2,
        diapers: 2,
        pee: 1,
      ),
      DateTime(2026, 10, 19): const CareDaySummary(pee: 1),
    });
  });

  test('un jour sans biberon, couche ni pipi a un bilan vide', () {
    final summaries = summarizeCareDays([
      makeEvent(startAt: DateTime(2026, 10, 20, 9), poop: true, bath: true),
    ]);
    expect(summaries[DateTime(2026, 10, 20)]!.isEmpty, isTrue);
  });

  test('aucun soin donne une carte vide', () {
    expect(summarizeCareDays(const []), isEmpty);
  });
}
