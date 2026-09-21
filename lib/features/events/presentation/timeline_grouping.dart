import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';

/// Un jour du journal et ses événements, dans l'ordre reçu.
typedef TimelineDay = ({DateTime day, List<CareEvent> events});

/// Regroupe des événements déjà triés par jour civil.
List<TimelineDay> groupEventsByDay(List<CareEvent> events) {
  final groups = <TimelineDay>[];
  for (final event in events) {
    final day = event.startAt.dateOnly;
    if (groups.isNotEmpty && groups.last.day == day) {
      groups.last.events.add(event);
    } else {
      groups.add((day: day, events: [event]));
    }
  }
  return groups;
}
