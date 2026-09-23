import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:colette/features/sleep/domain/entities/sleep_status.dart';

/// Fenêtre du total glissant.
const sleepSummaryWindow = Duration(hours: 24);

/// Au-delà, un sommeil en cours est signalé comme réveil oublié.
const forgottenWakeAfter = Duration(hours: 16);

/// Réunit [recent] et [latest] par identifiant, [latest] ayant priorité.
Map<String, SleepSession> _byId(
  List<SleepSession> recent,
  SleepSession? latest,
) {
  final byId = {for (final s in recent) s.id: s};
  if (latest != null) byId[latest.id] = latest;
  return byId;
}

/// Sommeils ouverts, du plus ancien au plus récent, doublons compris.
List<SleepSession> openSleeps(
  List<SleepSession> recent,
  SleepSession? latest,
) =>
    _byId(recent, latest).values.where((s) => s.isOngoing).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

/// Réunit [recent] et [latest] sans doublon d'identifiant, en ne gardant que le
/// plus ancien sommeil ouvert (les autres sont des doublons d'appuis simultanés).
List<SleepSession> mergeSleeps(
  List<SleepSession> recent,
  SleepSession? latest,
) {
  final duplicates = openSleeps(
    recent,
    latest,
  ).skip(1).map((s) => s.id).toSet();
  return _byId(
    recent,
    latest,
  ).values.where((s) => !duplicates.contains(s.id)).toList();
}

/// État actuel et total sur les dernières 24 h.
SleepSummary computeSleepSummary({
  required List<SleepSession> recent,
  required SleepSession? latest,
  required DateTime now,
}) {
  final sleeps = mergeSleeps(recent, latest);
  final windowStart = now.subtract(sleepSummaryWindow);
  var total = Duration.zero;
  for (final sleep in sleeps) {
    final start = sleep.startAt.isAfter(windowStart)
        ? sleep.startAt
        : windowStart;
    final rawEnd = sleep.endOr(now);
    final end = rawEnd.isBefore(now) ? rawEnd : now;
    if (end.isAfter(start)) total += end.difference(start);
  }
  final ongoing = sleeps.where((s) => s.isOngoing).firstOrNull;
  final SleepStatus status;
  if (ongoing != null) {
    status = now.difference(ongoing.startAt) > forgottenWakeAfter
        ? SleepStatus.forgottenWake(ongoing)
        : SleepStatus.asleep(ongoing);
  } else {
    final ends = sleeps.map((s) => s.endAt).nonNulls.toList()..sort();
    status = SleepStatus.awake(since: ends.lastOrNull);
  }
  return SleepSummary(status: status, last24h: total);
}
