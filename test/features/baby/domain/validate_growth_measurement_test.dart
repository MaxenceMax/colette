import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/either_extensions.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/domain/use_cases/validate_growth_measurement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validate = ValidateGrowthMeasurement();

  GrowthMeasurement measurement({int? grams, int? lengthMm, int? headMm}) =>
      GrowthMeasurement(
        id: 'm',
        measuredAt: DateTime(2026, 9, 10),
        grams: grams,
        lengthMm: lengthMm,
        headCircumferenceMm: headMm,
      );

  ValidationReason? reasonOf(GrowthMeasurement m) =>
      validate(m).leftOrNull?.reason;

  test('refuse une mesure sans aucune valeur', () {
    expect(reasonOf(measurement()), ValidationReason.emptyMeasurement);
  });

  test('accepte une mesure partielle', () {
    final onlyLength = measurement(lengthMm: 545);
    expect(validate(onlyLength).getRight().toNullable(), onlyLength);
  });

  test('bornes du poids : 1 000 à 20 000 g', () {
    expect(reasonOf(measurement(grams: 999)), ValidationReason.invalidWeight);
    expect(reasonOf(measurement(grams: 1000)), isNull);
    expect(reasonOf(measurement(grams: 20000)), isNull);
    expect(reasonOf(measurement(grams: 20001)), ValidationReason.invalidWeight);
  });

  test('bornes de la taille : 30 à 120 cm', () {
    expect(
      reasonOf(measurement(lengthMm: 299)),
      ValidationReason.invalidLength,
    );
    expect(reasonOf(measurement(lengthMm: 300)), isNull);
    expect(reasonOf(measurement(lengthMm: 1200)), isNull);
    expect(
      reasonOf(measurement(lengthMm: 1201)),
      ValidationReason.invalidLength,
    );
  });

  test('bornes du périmètre crânien : 25 à 60 cm', () {
    expect(
      reasonOf(measurement(headMm: 249)),
      ValidationReason.invalidHeadCircumference,
    );
    expect(reasonOf(measurement(headMm: 250)), isNull);
    expect(reasonOf(measurement(headMm: 600)), isNull);
    expect(
      reasonOf(measurement(headMm: 601)),
      ValidationReason.invalidHeadCircumference,
    );
  });

  test('une saisie illisible (-1) est refusée pour son champ', () {
    expect(
      reasonOf(measurement(grams: 3600, lengthMm: -1)),
      ValidationReason.invalidLength,
    );
  });
}
