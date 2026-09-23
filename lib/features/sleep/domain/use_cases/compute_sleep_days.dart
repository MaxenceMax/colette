import 'package:colette/features/sleep/domain/entities/sleep_day.dart';
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';

/// Nombre de jours affichés par la page Sommeil.
const sleepWeekDayCount = 7;

/// Les [sleepWeekDayCount] jours civils se terminant par [today], du plus ancien
/// au plus récent. Un sommeil qui passe minuit est découpé ; siestes et plus
/// longue période sont rattachées au jour de début.
List<SleepDay> computeSleepDays(
  List<SleepSession> sleeps, {
  required DateTime today,
  required DateTime now,
}) => [
  for (var offset = sleepWeekDayCount - 1; offset >= 0; offset--)
    _day(sleeps, DateTime(today.year, today.month, today.day - offset), now),
];

SleepDay _day(List<SleepSession> sleeps, DateTime dayStart, DateTime now) {
  final dayEnd = DateTime(dayStart.year, dayStart.month, dayStart.day + 1);
  final segments = <SleepSegment>[];
  var total = Duration.zero;
  var napCount = 0;
  var longest = Duration.zero;
  for (final sleep in sleeps) {
    final start = sleep.startAt.isAfter(dayStart) ? sleep.startAt : dayStart;
    final rawEnd = sleep.endOr(now);
    final end = rawEnd.isBefore(dayEnd) ? rawEnd : dayEnd;
    if (end.isAfter(start)) {
      segments.add(SleepSegment(start: start, end: end, kind: sleep.kind));
      total += end.difference(start);
    }
    final startsToday =
        !sleep.startAt.isBefore(dayStart) && sleep.startAt.isBefore(dayEnd);
    if (!startsToday) continue;
    if (sleep.kind == SleepKind.nap) napCount++;
    final duration = sleep.durationUntil(now);
    if (duration > longest) longest = duration;
  }
  segments.sort((a, b) => a.start.compareTo(b.start));
  return SleepDay(
    day: dayStart,
    segments: segments,
    total: total,
    napCount: napCount,
    longest: longest,
  );
}

/// Moyenne des totaux des jours précédant le dernier, parmi ceux qui ont du
/// sommeil noté ; `null` s'il n'y en a aucun.
Duration? averageOfPreviousDays(List<SleepDay> days) {
  final noted = days
      .take(days.length - 1)
      .where((d) => d.total > Duration.zero)
      .toList();
  if (noted.isEmpty) return null;
  final minutes = noted.fold(0, (sum, d) => sum + d.total.inMinutes);
  return Duration(minutes: (minutes / noted.length).round());
}
