import 'package:colette/features/dashboard/domain/entities/feeding_age_band.dart';
import 'package:colette/features/dashboard/domain/entities/feeding_reference.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_feeding_plan.dart';

/// Repères OMS du jour pour la feuille d'information.
class ComputeFeedingReference {
  const ComputeFeedingReference();

  FeedingReference call({
    required DateTime birthDate,
    required int? latestWeightGrams,
    required DateTime now,
  }) {
    final day = ComputeFeedingPlan.dayOfLife(birthDate, now);
    final mlPerKg = ComputeFeedingPlan.mlPerKg(day);
    return FeedingReference(
      dayOfLife: day,
      ageBand: FeedingAgeBand.forDayOfLife(day),
      mlPerKg: mlPerKg,
      weightGrams: latestWeightGrams,
      weightTargetMl: switch (latestWeightGrams) {
        null => null,
        final grams => ComputeFeedingPlan.weightTargetMl(day, grams),
      },
    );
  }
}
