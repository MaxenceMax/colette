import 'package:colette/features/baby/domain/reference/who_head_circumference_for_age.dart';
import 'package:colette/features/baby/domain/reference/who_length_for_age.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('731 jours par sexe pour la taille et le périmètre', () {
    for (final table in [
      whoLengthForAgeGirls,
      whoLengthForAgeBoys,
      whoHeadCircumferenceForAgeGirls,
      whoHeadCircumferenceForAgeBoys,
    ]) {
      expect(table, hasLength(731));
    }
  });

  test('premier et dernier jour conformes aux fichiers OMS', () {
    expect(whoLengthForAgeBoys.first, (1.0, 49.8842, 0.03795));
    expect(whoLengthForAgeGirls.first, (1.0, 49.1477, 0.0379));
    expect(whoLengthForAgeBoys.last, (1.0, 87.8018, 0.03479));
    expect(whoLengthForAgeGirls.last, (1.0, 86.4008, 0.03733));
    expect(whoHeadCircumferenceForAgeBoys.first, (1.0, 34.4618, 0.03686));
    expect(whoHeadCircumferenceForAgeGirls.first, (1.0, 33.8787, 0.03496));
    expect(whoHeadCircumferenceForAgeBoys.last, (1.0, 48.2494, 0.02821));
    expect(whoHeadCircumferenceForAgeGirls.last, (1.0, 47.1799, 0.02958));
  });
}
