import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';

/// Ligne du Journal : un soin ou un sommeil.
sealed class TimelineEntry {
  const TimelineEntry();

  String get id;
  DateTime get startAt;
}

/// Ligne de soin.
final class CareEntry extends TimelineEntry {
  const CareEntry(this.event);

  final CareEvent event;

  @override
  String get id => event.id;

  @override
  DateTime get startAt => event.startAt;
}

/// Ligne de sommeil.
final class SleepEntry extends TimelineEntry {
  const SleepEntry(this.session);

  final SleepSession session;

  @override
  String get id => session.id;

  @override
  DateTime get startAt => session.startAt;
}

/// Soins et sommeils mêlés, du plus récent au plus ancien.
List<TimelineEntry> mergeTimelineEntries(
  List<CareEvent> events,
  List<SleepSession> sleeps,
) => [
  for (final e in events) CareEntry(e),
  for (final s in sleeps) SleepEntry(s),
]..sort((a, b) => b.startAt.compareTo(a.startAt));
