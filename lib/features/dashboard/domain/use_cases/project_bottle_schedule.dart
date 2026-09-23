import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/dashboard/domain/entities/feeding_plan.dart';
import 'package:colette/features/dashboard/domain/entities/projected_bottle.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_feeding_plan.dart';

/// Projette les biberons des 24 prochaines heures à partir du plan du jour.
///
/// Le premier est le prochain biberon du plan ; les suivants partent de
/// `max(nextBottleAt, now)` et sont espacés de l'intervalle. Les prises du
/// lendemain suivent la cible de demain répartie sur `feedsPerDay`.
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
    final interval = ComputeFeedingPlan.intervalFor(plan.feedsPerDay);
    final end = now.add(horizon);
    final tomorrowMl = _tomorrowSuggestedMl(
      feedsPerDay: plan.feedsPerDay,
      birthDate: birthDate,
      latestWeightGrams: latestWeightGrams,
      now: now,
      dailyTargetMlOverride: dailyTargetMlOverride,
    );
    final anchor = plan.nextBottleAt.isAfter(now) ? plan.nextBottleAt : now;
    final bottles = [
      ProjectedBottle(
        at: plan.nextBottleAt,
        windowStart: plan.windowStart,
        windowEnd: plan.windowEnd,
        suggestedMl: plan.suggestedMl,
      ),
    ];
    for (
      var at = anchor.add(interval);
      at.isBefore(end);
      at = at.add(interval)
    ) {
      final (windowStart, windowEnd) = ComputeFeedingPlan.windowAround(
        at,
        interval,
      );
      bottles.add(
        ProjectedBottle(
          at: at,
          windowStart: windowStart,
          windowEnd: windowEnd,
          suggestedMl: at.dateOnly == now.dateOnly
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
