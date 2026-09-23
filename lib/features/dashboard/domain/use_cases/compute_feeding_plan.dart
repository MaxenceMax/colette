import 'dart:math';

import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/dashboard/domain/entities/feeding_age_band.dart';
import 'package:colette/features/dashboard/domain/entities/feeding_plan.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';

/// Plan biberons selon l'OMS : 150 ml/kg/jour (montée progressive la 1re semaine),
/// réparti sur `feedsPerDay` prises ; repères par âge sans pesée.
/// Une cible ajustée (`dailyTargetMlOverride`) remplace la cible OMS.
/// Le prochain biberon est possible de 2 h 30 à 5 h après le dernier.
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
    int? dailyTargetMlOverride,
  }) {
    final safeFeedsPerDay = max(1, feedsPerDay);
    final day = dayOfLife(birthDate, now);
    final omsTargetMl = dailyTargetFor(
      dayOfLife: day,
      latestWeightGrams: latestWeightGrams,
    );
    final dailyTargetMl = dailyTargetMlOverride ?? omsTargetMl;
    final interval = intervalFor(safeFeedsPerDay);
    final nextBottleAt = lastBottle == null
        ? now
        : lastBottle.startAt.add(interval);
    final (windowStart, windowEnd) = lastBottle == null
        ? (now, now)
        : windowAfter(lastBottle.startAt);
    final givenMl = todayBottles.fold(0, (sum, e) => sum + (e.bottleMl ?? 0));
    final bottlesGiven = todayBottles.length;
    final bottlesRemaining = max(0, safeFeedsPerDay - bottlesGiven);
    final remainingMl = max(0, dailyTargetMl - givenMl);
    final raw = bottlesRemaining > 0
        ? remainingMl / bottlesRemaining
        : dailyTargetMl / safeFeedsPerDay;
    final suggestedMl = roundTo10(raw).clamp(minSuggestedMl, maxSuggestedMl);
    return FeedingPlan(
      dailyTargetMl: dailyTargetMl,
      omsTargetMl: omsTargetMl,
      isTargetOverridden: dailyTargetMlOverride != null,
      feedsPerDay: safeFeedsPerDay,
      nextBottleAt: nextBottleAt,
      windowStart: windowStart,
      windowEnd: windowEnd,
      suggestedMl: suggestedMl,
      bottlesGiven: bottlesGiven,
      givenMl: givenMl,
      isEstimatedFromAge: latestWeightGrams == null,
    );
  }

  /// Intervalle entre deux prises ; `feedsPerDay` borné à 1 minimum.
  static Duration intervalFor(int feedsPerDay) =>
      Duration(minutes: (24 * 60 / max(1, feedsPerDay)).round());

  /// Délai minimal entre deux biberons : début de la fenêtre de tir.
  static const minGap = Duration(hours: 2, minutes: 30);

  /// Délai maximal entre deux biberons : fin de la fenêtre de tir.
  static const maxGap = Duration(hours: 5);

  /// Fenêtre de tir après un biberon donné à `lastBottleAt`.
  static (DateTime, DateTime) windowAfter(DateTime lastBottleAt) =>
      (lastBottleAt.add(minGap), lastBottleAt.add(maxGap));

  /// Cible OMS : au poids si une pesée est connue, sinon repères par âge.
  static int dailyTargetFor({
    required int dayOfLife,
    required int? latestWeightGrams,
  }) => switch (latestWeightGrams) {
    null => dailyTargetFromAge(dayOfLife),
    final grams => weightTargetMl(dayOfLife, grams),
  };

  /// Jour de vie en jours civils ; 1 le jour de la naissance, jamais moins.
  static int dayOfLife(DateTime birthDate, DateTime now) =>
      max(1, calendarDaysBetween(birthDate, now) + 1);

  /// 60 ml/kg le jour 1, +20 ml/kg par jour, plafonné à 150 ml/kg.
  static int mlPerKg(int dayOfLife) => min(150, 60 + 20 * (dayOfLife - 1));

  /// Jour de vie à partir duquel `mlPerKg` atteint son plafond de 150.
  static const mlPerKgPlateauDay = 6;

  /// Cible journalière indicative quand aucune pesée n'est connue.
  static int dailyTargetFromAge(int dayOfLife) =>
      FeedingAgeBand.forDayOfLife(dayOfLife).dailyMl;

  /// Arrondi au multiple de 10 ml le plus proche.
  static int roundTo10(double value) => (value / 10).round() * 10;

  /// Cible journalière OMS calculée sur la dernière pesée, arrondie à 10 ml.
  static int weightTargetMl(int dayOfLife, int grams) =>
      roundTo10(mlPerKg(dayOfLife) * grams / 1000);
}
