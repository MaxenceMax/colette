import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'feeding_plan.freezed.dart';

/// Plan biberons du jour : cible, progression, heure du prochain biberon.
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

    /// Heure prévue du prochain biberon ; `now` sans biberon enregistré.
    required DateTime nextBottleAt,
    required int suggestedMl,
    required int bottlesGiven,
    required int givenMl,
    required bool isEstimatedFromAge,
  }) = _FeedingPlan;

  int get bottlesRemaining => max(0, feedsPerDay - bottlesGiven);

  int get remainingMl => max(0, dailyTargetMl - givenMl);

  /// Retard sur l'heure prévue du prochain biberon, ou zéro.
  Duration lateBy(DateTime now) => latenessAt(nextBottleAt, now);

  /// Retard de [now] sur [at] ; zéro sous une minute, pour ne pas afficher
  /// « en retard de 0 min » quand l'heure prévue porte des secondes.
  static Duration latenessAt(DateTime at, DateTime now) {
    final late = now.difference(at);
    return late >= const Duration(minutes: 1) ? late : Duration.zero;
  }
}
