import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'growth_trend.freezed.dart';

/// Dernière valeur d'une grandeur et évolution depuis la valeur d'un jour précédent.
@freezed
abstract class GrowthTrend with _$GrowthTrend {
  const factory GrowthTrend({
    required GrowthMetric metric,
    required int latestValue,
    required DateTime latestAt,
    int? previousValue,
    DateTime? previousAt,
  }) = _GrowthTrend;

  const GrowthTrend._();

  /// Écart depuis la valeur précédente, négatif en cas de baisse.
  int? get delta => switch (previousValue) {
    final previous? => latestValue - previous,
    null => null,
  };

  /// Jours civils écoulés depuis la valeur précédente, au moins 1.
  int? get days => switch (previousAt) {
    final previous? => calendarDaysBetween(previous, latestAt),
    null => null,
  };

  /// Écart moyen par jour, arrondi ; affiché pour le poids seulement.
  int? get perDay => switch ((delta, days)) {
    (final delta?, final days?) when days > 0 => (delta / days).round(),
    _ => null,
  };
}
