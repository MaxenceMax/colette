import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_growth_metric.g.dart';

/// Grandeur affichée sur la page Croissance ; revient au poids à chaque ouverture.
@riverpod
class SelectedGrowthMetric extends _$SelectedGrowthMetric {
  @override
  GrowthMetric build() => GrowthMetric.weight;

  void set(GrowthMetric metric) => state = metric;
}
