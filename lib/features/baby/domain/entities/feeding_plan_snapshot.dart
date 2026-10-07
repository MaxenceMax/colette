import 'package:freezed_annotation/freezed_annotation.dart';

part 'feeding_plan_snapshot.freezed.dart';

/// Résumé du plan biberons écrit dans le foyer, lu par les Cloud Functions.
@freezed
abstract class FeedingPlanSnapshot with _$FeedingPlanSnapshot {
  const factory FeedingPlanSnapshot({
    required DateTime nextBottleAt,
    required int suggestedMl,
    required DateTime computedAt,

    /// Premier biberon du matin après [nextBottleAt] : rappel de secours si
    /// aucun biberon n'est noté d'ici là ; `null` sans biberon.
    DateTime? morningBottleAt,

    /// Biberons des 24 prochaines heures, rappelés un par un par la Cloud
    /// Function.
    @Default([]) List<UpcomingBottle> upcomingBottles,
  }) = _FeedingPlanSnapshot;
}

/// Biberon prévu dans le snapshot : heure et quantité conseillée.
@freezed
abstract class UpcomingBottle with _$UpcomingBottle {
  const factory UpcomingBottle({
    required DateTime at,
    required int suggestedMl,
  }) = _UpcomingBottle;
}
