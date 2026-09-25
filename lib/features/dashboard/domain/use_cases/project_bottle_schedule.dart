import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/dashboard/domain/entities/feeding_plan.dart';
import 'package:colette/features/dashboard/domain/entities/projected_bottle.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_feeding_plan.dart';

/// Projette les biberons des 24 prochaines heures à partir du plan du jour.
///
/// Le premier est le prochain biberon du plan. Les suivants supposent chaque
/// biberon donné au plus tôt : la fourchette suivante (2 h 30 – 5 h) part du
/// début de la précédente, la première de `max(windowStart, now)`. Les prises
/// du lendemain suivent la cible de demain répartie sur `feedsPerDay`.
class ProjectBottleSchedule {
  const ProjectBottleSchedule();

  static const horizon = Duration(hours: 24);

  List<ProjectedBottle> call({
    required FeedingPlan plan,
    required DateTime birthDate,
    required int? latestWeightGrams,
    required DateTime now,
    int? dailyTargetMlOverride,
  }) {
    final end = now.add(horizon);
    final tomorrowMl = _tomorrowSuggestedMl(
      feedsPerDay: plan.feedsPerDay,
      birthDate: birthDate,
      latestWeightGrams: latestWeightGrams,
      now: now,
      dailyTargetMlOverride: dailyTargetMlOverride,
    );
    final firstGiven = plan.windowStart.isAfter(now) ? plan.windowStart : now;
    final bottles = [
      ProjectedBottle(
        at: plan.nextBottleAt,
        windowStart: plan.windowStart,
        windowEnd: plan.windowEnd,
        suggestedMl: plan.suggestedMl,
      ),
    ];
    for (
      var (windowStart, windowEnd) = ComputeFeedingPlan.windowAfter(firstGiven);
      windowStart.isBefore(end);
      (windowStart, windowEnd) = ComputeFeedingPlan.windowAfter(windowStart)
    ) {
      bottles.add(
        ProjectedBottle(
          at: windowStart,
          windowStart: windowStart,
          windowEnd: windowEnd,
          suggestedMl: windowStart.dateOnly == now.dateOnly
              ? plan.suggestedMl
              : tomorrowMl,
        ),
      );
    }
    return bottles;
  }

  /// Cible de demain (ajustée, sinon OMS) répartie sur les prises, bornée.
  static int _tomorrowSuggestedMl({
    required int feedsPerDay,
    required DateTime birthDate,
    required int? latestWeightGrams,
    required DateTime now,
    required int? dailyTargetMlOverride,
  }) {
    final day = ComputeFeedingPlan.dayOfLife(birthDate, now.startOfNextDay);
    final target =
        dailyTargetMlOverride ??
        ComputeFeedingPlan.dailyTargetFor(
          dayOfLife: day,
          latestWeightGrams: latestWeightGrams,
        );
    return ComputeFeedingPlan.roundTo10(target / feedsPerDay).clamp(
      ComputeFeedingPlan.minSuggestedMl,
      ComputeFeedingPlan.maxSuggestedMl,
    );
  }
}
