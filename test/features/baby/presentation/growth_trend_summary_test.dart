import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:colette/features/baby/domain/entities/growth_trend.dart';
import 'package:colette/features/baby/presentation/widgets/growth_trend_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('taille : valeur, date et écart en cm et en jours', (
    tester,
  ) async {
    await pumpApp(
      tester,
      GrowthTrendSummary(
        trend: GrowthTrend(
          metric: GrowthMetric.length,
          latestValue: 545,
          latestAt: DateTime(2026, 9, 20),
          previousValue: 520,
          previousAt: DateTime(2026, 9, 2),
        ),
      ),
    );
    expect(find.text('54,5 cm'), findsOneWidget);
    expect(find.text('Mesure du 20 sept. 2026'), findsOneWidget);
    expect(find.text('+2,5 cm en 18 jours'), findsOneWidget);
  });

  testWidgets('périmètre sans mesure précédente : « Première mesure »', (
    tester,
  ) async {
    await pumpApp(
      tester,
      GrowthTrendSummary(
        trend: GrowthTrend(
          metric: GrowthMetric.headCircumference,
          latestValue: 350,
          latestAt: DateTime(2026, 9, 8),
        ),
      ),
    );
    expect(find.text('Première mesure'), findsOneWidget);
  });

  testWidgets('poids : date « Pesée du … » et écart en g/jour', (tester) async {
    await pumpApp(
      tester,
      GrowthTrendSummary(
        trend: GrowthTrend(
          metric: GrowthMetric.weight,
          latestValue: 3650,
          latestAt: DateTime(2026, 9, 14),
          previousValue: 3470,
          previousAt: DateTime(2026, 9, 10),
        ),
      ),
    );
    expect(find.text('Pesée du 14 sept. 2026'), findsOneWidget);
    expect(find.text('+180 g en 4 jours · +45 g/jour'), findsOneWidget);
  });
}
