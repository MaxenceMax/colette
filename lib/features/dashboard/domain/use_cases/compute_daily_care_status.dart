import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/dashboard/domain/entities/care_task.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/shared/domain/care_type.dart';

/// Soins attendus aujourd'hui, avec leur avancement.
class ComputeDailyCareStatus {
  const ComputeDailyCareStatus();

  List<CareTask> call({
    required CareSettings settings,
    required List<CareEvent> todayEvents,
    required CareEvent? lastBath,
    required DateTime now,
  }) {
    CareTask task(CareType type, int target) {
      final matching = todayEvents.where((e) => e.has(type)).toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt));
      return CareTask(
        type: type,
        target: target,
        done: matching.length,
        lastDoneAt: matching.isEmpty ? null : matching.last.startAt,
      );
    }

    final bathToday = todayEvents.any((e) => e.bath);
    final bathExpected = isBathExpected(
      lastBath: lastBath,
      bathEveryDays: settings.bathEveryDays,
      now: now,
    );

    return [
      if (settings.adrigylPerDay > 0)
        task(CareType.adrigyl, settings.adrigylPerDay),
      if (settings.eyeCarePerDay > 0)
        task(CareType.eyeCare, settings.eyeCarePerDay),
      if (settings.noseCarePerDay > 0)
        task(CareType.noseCare, settings.noseCarePerDay),
      if (settings.umbilicalCareEnabled) task(CareType.umbilicalCare, 1),
      if (bathExpected || bathToday) task(CareType.bath, 1),
    ];
  }

  /// Bain attendu si aucun bain, ou si le dernier date d'au moins [bathEveryDays] jours civils.
  static bool isBathExpected({
    required CareEvent? lastBath,
    required int bathEveryDays,
    required DateTime now,
  }) {
    if (lastBath == null) return true;
    final daysSince = now.dateOnly.difference(lastBath.startAt.dateOnly).inDays;
    return daysSince >= bathEveryDays;
  }
}
