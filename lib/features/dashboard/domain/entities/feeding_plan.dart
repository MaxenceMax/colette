import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'feeding_plan.freezed.dart';

/// Plan biberons du jour : cible, progression, prochain biberon.
@freezed
abstract class FeedingPlan with _$FeedingPlan {
  const FeedingPlan._();

  const factory FeedingPlan({
    required int dailyTargetMl,
    required int feedsPerDay,
    required DateTime nextBottleAt,
    required int suggestedMl,
    required int bottlesGiven,
    required int givenMl,
    required bool isEstimatedFromAge,
  }) = _FeedingPlan;

  int get bottlesRemaining => max(0, feedsPerDay - bottlesGiven);

  int get remainingMl => max(0, dailyTargetMl - givenMl);

  /// Retard sur le prochain biberon, ou zéro.
  Duration lateBy(DateTime now) =>
      now.isAfter(nextBottleAt) ? now.difference(nextBottleAt) : Duration.zero;
}
