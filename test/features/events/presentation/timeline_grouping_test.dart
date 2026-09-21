import 'package:colette/features/events/presentation/timeline_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/care_event_factory.dart';

void main() {
  test('groupe par jour civil en conservant l\'ordre', () {
    final events = [
      makeEvent(id: 'c', startAt: DateTime(2026, 9, 21, 14), pee: true),
      makeEvent(id: 'b', startAt: DateTime(2026, 9, 21, 8), pee: true),
      makeEvent(id: 'a', startAt: DateTime(2026, 9, 20, 23), pee: true),
    ];
    final groups = groupEventsByDay(events);
    expect(groups.map((g) => g.day), [
      DateTime(2026, 9, 21),
      DateTime(2026, 9, 20),
    ]);
    expect(groups.first.events.map((e) => e.id), ['c', 'b']);
    expect(groups.last.events.map((e) => e.id), ['a']);
  });

  test('liste vide donne aucun groupe', () {
    expect(groupEventsByDay(const []), isEmpty);
  });
}
