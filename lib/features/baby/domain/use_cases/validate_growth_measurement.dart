import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:fpdart/fpdart.dart';

/// Règles de validité d'une mesure de croissance avant enregistrement.
class ValidateGrowthMeasurement {
  const ValidateGrowthMeasurement();

  static const minWeightGrams = 1000;
  static const maxWeightGrams = 20000;
  static const minLengthMm = 300;
  static const maxLengthMm = 1200;
  static const minHeadCircumferenceMm = 250;
  static const maxHeadCircumferenceMm = 600;

  Either<ValidationFailure, GrowthMeasurement> call(GrowthMeasurement m) {
    if (m.grams == null &&
        m.lengthMm == null &&
        m.headCircumferenceMm == null) {
      return left(const ValidationFailure(ValidationReason.emptyMeasurement));
    }
    if (_outside(m.grams, minWeightGrams, maxWeightGrams)) {
      return left(const ValidationFailure(ValidationReason.invalidWeight));
    }
    if (_outside(m.lengthMm, minLengthMm, maxLengthMm)) {
      return left(const ValidationFailure(ValidationReason.invalidLength));
    }
    if (_outside(
      m.headCircumferenceMm,
      minHeadCircumferenceMm,
      maxHeadCircumferenceMm,
    )) {
      return left(
        const ValidationFailure(ValidationReason.invalidHeadCircumference),
      );
    }
    return right(m);
  }

  static bool _outside(int? value, int min, int max) =>
      value != null && (value < min || value > max);
}
