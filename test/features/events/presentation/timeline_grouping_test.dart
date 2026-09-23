import 'package:colette/features/events/presentation/timeline_entry.dart';
import 'package:colette/features/events/presentation/timeline_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/care_event_factory.dart';
import '../../../helpers/sleep_session_factory.dart';

void main() {
  test('fusionne soins et sommeils du plus récent au plus ancien', () {
    final entries = mergeTimelineEntries(
      [
        makeEvent(id: 'c', startAt: DateTime(2026, 9, 21, 14), pee: true),
        makeEvent(id: 'a', startAt: DateTime(2026, 9, 20, 23), pee: true),
      ],
      [
        makeSleep(
          id: 's',
          startAt: DateTime(2026, 9, 21, 8),
          endAt: DateTime(2026, 9, 21, 9),
        ),
      ],
    );
    expect(entries.map((e) => e.id), ['c', 's', 'a']);
    expect(entries[1], isA<SleepEntry>());
  });

  test('groupe par jour civil en conservant l\'ordre', () {
    final entries = mergeTimelineEntries([
      makeEvent(id: 'c', startAt: DateTime(2026, 9, 21, 14), pee: true),
      makeEvent(id: 'b', startAt: DateTime(2026, 9, 21, 8), pee: true),
      makeEvent(id: 'a', startAt: DateTime(2026, 9, 20, 23), pee: true),
    ], const []);
    final groups = groupEntriesByDay(entries);
    expect(groups.map((g) => g.day), [
      DateTime(2026, 9, 21),
      DateTime(2026, 9, 20),
    ]);
    expect(groups.first.entries.map((e) => e.id), ['c', 'b']);
    expect(groups.last.entries.map((e) => e.id), ['a']);
  });

  test('liste vide donne aucun groupe', () {
    expect(groupEntriesByDay(const []), isEmpty);
  });
}
