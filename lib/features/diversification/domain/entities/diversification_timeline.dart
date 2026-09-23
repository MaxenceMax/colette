import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'diversification_timeline.freezed.dart';

/// Phase courante, âge en mois révolus et échéance des 6 mois.
@freezed
abstract class DiversificationTimeline with _$DiversificationTimeline {
  const factory DiversificationTimeline({
    required DiversificationPhase phase,
    required int ageMonths,
    required DateTime sixMonthsDate,
    required int daysUntilSixMonths,
  }) = _DiversificationTimeline;
}
