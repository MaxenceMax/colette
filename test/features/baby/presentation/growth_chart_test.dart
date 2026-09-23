import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:colette/features/baby/presentation/widgets/growth_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  GrowthPoint point(DateTime at, int value) => (at: at, value: value);

  Future<void> pumpChart(
    WidgetTester tester,
    GrowthMetric metric,
    List<GrowthPoint> points,
  ) async {
    await pumpApp(
      tester,
      Scaffold(
        // Taille fixe pour ce test uniquement : le graphe a besoin de
        // contraintes bornées pour se rendre hors d'un écran complet.
        body: SizedBox(
          width: 400,
          height: 300,
          child: GrowthChart(metric: metric, points: points),
        ),
      ),
    );
  }

  testWidgets('taille : pas de 20 mm, libellés sans décimale', (tester) async {
    await pumpChart(tester, GrowthMetric.length, [
      point(DateTime(2026, 9, 1), 500),
      point(DateTime(2026, 9, 20), 545),
    ]);
    expect(find.text('50 cm'), findsOneWidget);
    expect(find.textContaining(','), findsNothing);
  });

  testWidgets('périmètre : pas de 5 mm, libellés avec une décimale', (
    tester,
  ) async {
    await pumpChart(tester, GrowthMetric.headCircumference, [
      point(DateTime(2026, 9, 1), 345),
      point(DateTime(2026, 9, 8), 350),
    ]);
    expect(find.text('34,5 cm'), findsOneWidget);
  });
}
