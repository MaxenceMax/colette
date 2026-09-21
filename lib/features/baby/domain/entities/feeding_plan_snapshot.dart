import 'package:freezed_annotation/freezed_annotation.dart';

part 'feeding_plan_snapshot.freezed.dart';

/// Résumé du plan biberons écrit dans le foyer, lu par les Cloud Functions.
@freezed
abstract class FeedingPlanSnapshot with _$FeedingPlanSnapshot {
  const factory FeedingPlanSnapshot({
    required DateTime nextBottleAt,
    required int suggestedMl,
    required DateTime computedAt,
  }) = _FeedingPlanSnapshot;
}
