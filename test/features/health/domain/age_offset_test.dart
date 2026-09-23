import 'package:colette/features/health/domain/entities/age_offset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('jours : date civile, minuit', () {
    expect(
      const AgeOffset.days(8).from(DateTime(2026, 9, 28, 14, 30)),
      DateTime(2026, 10, 6),
    );
  });

  test('mois : même jour du mois', () {
    expect(
      const AgeOffset.months(2).from(DateTime(2026, 9, 1)),
      DateTime(2026, 11, 1),
    );
    expect(
      const AgeOffset.months(12).from(DateTime(2026, 9, 15)),
      DateTime(2027, 9, 15),
    );
  });

  test('mois : jour borné à la fin du mois', () {
    expect(
      const AgeOffset.months(1).from(DateTime(2027, 1, 31)),
      DateTime(2027, 2, 28),
    );
    expect(
      const AgeOffset.months(1).from(DateTime(2028, 1, 31)),
      DateTime(2028, 2, 29),
    );
    expect(
      const AgeOffset.months(3).from(DateTime(2026, 11, 30)),
      DateTime(2027, 2, 28),
    );
  });
}
