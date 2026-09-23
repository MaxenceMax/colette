import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:colette/features/baby/domain/entities/growth_trend.dart';

/// Dernière valeur d'une grandeur comparée à la plus récente d'un jour civil antérieur.
class ComputeGrowthTrend {
  const ComputeGrowthTrend();

  GrowthTrend? call(GrowthMetric metric, List<GrowthMeasurement> measurements) {
    final series = metric.seriesOf(measurements);
    if (series.isEmpty) return null;
    final latest = series.last;
    final latestDay = latest.at.dateOnly;
    final previous = series.where((p) => p.at.isBefore(latestDay)).lastOrNull;
    return GrowthTrend(
      metric: metric,
      latestValue: latest.value,
      latestAt: latest.at,
      previousValue: previous?.value,
      previousAt: previous?.at,
    );
  }
}
