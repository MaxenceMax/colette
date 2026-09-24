import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/baby/domain/entities/care_frequency.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/dashboard/domain/entities/care_task.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/shared/domain/care_type.dart';

/// Soins attendus aujourd'hui, avec leur avancement.
class ComputeDailyCareStatus {
  const ComputeDailyCareStatus();

  /// [events] : les 7 derniers jours civils, aujourd'hui inclus
  /// (fenêtre de [CareFrequency.maxEveryDays] jours).
  List<CareTask> call({
    required CareSettings settings,
    required List<CareEvent> events,
    required DateTime now,
  }) => [
    for (final type in CareType.scheduled)
      ?_task(type, settings.frequencyOf(type), events, now),
  ];

  /// Tâche présente si le suivi est actif et que le soin est dû ou déjà fait aujourd'hui.
  CareTask? _task(
    CareType type,
    CareFrequency frequency,
    List<CareEvent> events,
    DateTime now,
  ) {
    if (!frequency.enabled) return null;
    final matching = events.where((e) => e.has(type)).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final today = matching.where((e) => e.startAt.isSameDay(now)).toList();
    final lastDoneAt = matching.isEmpty ? null : matching.last.startAt;
    final expected = frequency.isExpected(lastDoneAt: lastDoneAt, now: now);
    if (!expected && today.isEmpty) return null;
    return CareTask(
      type: type,
      target: frequency.timesPerDay,
      done: today.length,
      lastDoneAt: today.isEmpty ? null : today.last.startAt,
    );
  }
}
