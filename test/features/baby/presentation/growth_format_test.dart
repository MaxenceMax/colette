import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:colette/features/baby/presentation/widgets/growth_format.dart';
import 'package:colette/l10n/generated/app_localizations_fr.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final s = SFr();

  test('centimètres à une décimale, virgule française', () {
    expect(GrowthFormat.centimetres(545), '54,5');
    expect(GrowthFormat.centimetres(370), '37,0');
  });

  test('valeur avec unité selon la grandeur', () {
    expect(GrowthFormat.value(s, GrowthMetric.weight, 3650), '3650 g');
    expect(GrowthFormat.value(s, GrowthMetric.length, 545), '54,5 cm');
  });

  test('écart signé', () {
    expect(GrowthFormat.signedDelta(GrowthMetric.weight, 180), '+180');
    expect(GrowthFormat.signedDelta(GrowthMetric.weight, -40), '−40');
    expect(GrowthFormat.signedDelta(GrowthMetric.length, 20), '+2,0');
    expect(GrowthFormat.signedDelta(GrowthMetric.length, -5), '−0,5');
    expect(GrowthFormat.signedDelta(GrowthMetric.length, 0), '0');
  });

  test(
    'ligne d\'une mesure : valeurs présentes séparées par un point médian',
    () {
      expect(
        GrowthFormat.measurementLine(
          s,
          GrowthMeasurement(
            id: 'm',
            measuredAt: DateTime(2026, 9, 2),
            grams: 3650,
            lengthMm: 545,
            headCircumferenceMm: 370,
          ),
        ),
        '3650 g · 54,5 cm · PC 37,0 cm',
      );
      expect(
        GrowthFormat.measurementLine(
          s,
          GrowthMeasurement(
            id: 'm',
            measuredAt: DateTime(2026, 9, 2),
            lengthMm: 520,
          ),
        ),
        '52,0 cm',
      );
    },
  );
}
