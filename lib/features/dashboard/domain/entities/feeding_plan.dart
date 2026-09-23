import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'feeding_plan.freezed.dart';

/// Plan biberons du jour : cible, progression, fourchette du prochain biberon.
@freezed
abstract class FeedingPlan with _$FeedingPlan {
  const FeedingPlan._();

  const factory FeedingPlan({
    /// Cible effective : ajustée si renseignée, sinon OMS.
    required int dailyTargetMl,

    /// Cible calculée selon l'OMS, toujours disponible.
    required int omsTargetMl,

    /// Vrai dès qu'une cible ajustée est fournie, même égale à la cible OMS.
    required bool isTargetOverridden,
    required int feedsPerDay,

    /// Heure centrale du prochain biberon.
    required DateTime nextBottleAt,

    /// Début de la fourchette du prochain biberon.
    required DateTime windowStart,

    /// Fin de la fourchette ; égale au début sans biberon enregistré.
    required DateTime windowEnd,
    required int suggestedMl,
    required int bottlesGiven,
    required int givenMl,
    required bool isEstimatedFromAge,
  }) = _FeedingPlan;

  int get bottlesRemaining => max(0, feedsPerDay - bottlesGiven);

  int get remainingMl => max(0, dailyTargetMl - givenMl);

  /// Vrai si la fourchette a une largeur (au moins un biberon enregistré).
  bool get hasWindow => windowStart.isBefore(windowEnd);

  /// Retard compté depuis la fin de la fourchette, ou zéro.
  Duration lateBy(DateTime now) =>
      now.isAfter(windowEnd) ? now.difference(windowEnd) : Duration.zero;
}
