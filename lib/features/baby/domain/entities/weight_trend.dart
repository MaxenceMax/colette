import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'weight_trend.freezed.dart';

/// Dernière pesée et évolution depuis la pesée d'un jour précédent.
@freezed
abstract class WeightTrend with _$WeightTrend {
  const factory WeightTrend({
    required WeightEntry latest,
    WeightEntry? previous,
  }) = _WeightTrend;

  const WeightTrend._();

  /// Écart en grammes depuis [previous], négatif en cas de perte.
  int? get deltaGrams => switch (previous) {
    final previous? => latest.grams - previous.grams,
    null => null,
  };

  /// Jours civils écoulés depuis [previous], au moins 1.
  int? get days => switch (previous) {
    final previous? => calendarDaysBetween(
      previous.measuredAt,
      latest.measuredAt,
    ),
    null => null,
  };

  /// Gain moyen par jour, arrondi au gramme.
  int? get gramsPerDay => switch ((deltaGrams, days)) {
    (final delta?, final days?) => (delta / days).round(),
    _ => null,
  };
}
