import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/baby/domain/entities/bottle_schedule.dart';
import 'package:colette/features/dashboard/domain/entities/feeding_plan.dart';
import 'package:colette/features/dashboard/domain/entities/projected_bottle.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_feeding_plan.dart';

/// Projette les biberons des 24 prochaines heures à partir du plan du jour.
///
/// Le premier est le prochain biberon du plan. Les suivants enchaînent la
/// grille du foyer ([BottleSchedule.nextAfter]), chacun supposé donné à son
/// heure prévue, en partant de `max(nextBottleAt, now)`. Si l'horaire le plus
/// proche de ce point de départ lui est postérieur (sans biberon noté, après le
/// milieu de l'intervalle), il est conservé au lieu d'être sauté. Les prises du
/// lendemain suivent la cible de demain répartie sur `feedsPerDay`.
class ProjectBottleSchedule {
  const ProjectBottleSchedule();

  static const horizon = Duration(hours: 24);

  List<ProjectedBottle> call({
    required FeedingPlan plan,
    required BottleSchedule schedule,
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
    final firstGiven = plan.nextBottleAt.isAfter(now) ? plan.nextBottleAt : now;
    final nearest = schedule.slotOf(firstGiven);
    final bottles = [
      ProjectedBottle(at: plan.nextBottleAt, suggestedMl: plan.suggestedMl),
    ];
    for (
      var at = nearest.isAfter(firstGiven)
          ? nearest
          : schedule.nextAfter(firstGiven);
      at.isBefore(end);
      at = schedule.nextAfter(at)
    ) {
      bottles.add(
        ProjectedBottle(
          at: at,
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
