import 'dart:math';

import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/dashboard/domain/entities/feeding_plan.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';

/// Plan biberons selon l'OMS : 150 ml/kg/jour (montée progressive la 1re semaine),
/// réparti sur `feedsPerDay` prises ; repères par âge sans pesée.
///
/// `feedsPerDay` est borné à 1 minimum pour ne jamais diviser par zéro.
class ComputeFeedingPlan {
  const ComputeFeedingPlan();

  static const minSuggestedMl = 30;
  static const maxSuggestedMl = 240;

  FeedingPlan call({
    required DateTime birthDate,
    required int? latestWeightGrams,
    required int feedsPerDay,
    required List<CareEvent> todayBottles,
    required CareEvent? lastBottle,
    required DateTime now,
  }) {
    final safeFeedsPerDay = max(1, feedsPerDay);
    final day = dayOfLife(birthDate, now);
    final (dailyTargetMl, estimated) = switch (latestWeightGrams) {
      null => (dailyTargetFromAge(day), true),
      final grams => (_roundTo10(mlPerKg(day) * grams / 1000), false),
    };
    final interval = Duration(minutes: (24 * 60 / safeFeedsPerDay).round());
    final nextBottleAt = lastBottle == null
        ? now
        : lastBottle.startAt.add(interval);
    final givenMl = todayBottles.fold(0, (sum, e) => sum + (e.bottleMl ?? 0));
    final bottlesGiven = todayBottles.length;
    final bottlesRemaining = max(0, safeFeedsPerDay - bottlesGiven);
    final remainingMl = max(0, dailyTargetMl - givenMl);
    final raw = bottlesRemaining > 0
        ? remainingMl / bottlesRemaining
        : dailyTargetMl / safeFeedsPerDay;
    final suggestedMl = _roundTo10(raw).clamp(minSuggestedMl, maxSuggestedMl);
    return FeedingPlan(
      dailyTargetMl: dailyTargetMl,
      feedsPerDay: safeFeedsPerDay,
      nextBottleAt: nextBottleAt,
      suggestedMl: suggestedMl,
      bottlesGiven: bottlesGiven,
      givenMl: givenMl,
      isEstimatedFromAge: estimated,
    );
  }

  /// Jour de vie en jours civils ; 1 le jour de la naissance, jamais moins.
  static int dayOfLife(DateTime birthDate, DateTime now) =>
      max(1, now.dateOnly.difference(birthDate.dateOnly).inDays + 1);

  /// 60 ml/kg le jour 1, +20 ml/kg par jour, plafonné à 150 ml/kg.
  static int mlPerKg(int dayOfLife) => min(150, 60 + 20 * (dayOfLife - 1));

  /// Cible journalière indicative quand aucune pesée n'est connue.
  static int dailyTargetFromAge(int dayOfLife) {
    if (dayOfLife <= 5) return const [240, 320, 400, 440, 480][dayOfLife - 1];
    if (dayOfLife <= 30) return 480;
    if (dayOfLife <= 60) return 630;
    if (dayOfLife <= 120) return 720;
    return 900;
  }

  static int _roundTo10(double value) => (value / 10).round() * 10;
}
