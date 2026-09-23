import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/events/presentation/timeline_entry.dart';

/// Un jour du journal et ses lignes, dans l'ordre reçu.
typedef TimelineDay = ({DateTime day, List<TimelineEntry> entries});

/// Regroupe des lignes déjà triées par jour civil.
List<TimelineDay> groupEntriesByDay(List<TimelineEntry> entries) {
  final groups = <TimelineDay>[];
  for (final entry in entries) {
    final day = entry.startAt.dateOnly;
    if (groups.isNotEmpty && groups.last.day == day) {
      groups.last.entries.add(entry);
    } else {
      groups.add((day: day, entries: [entry]));
    }
  }
  return groups;
}
