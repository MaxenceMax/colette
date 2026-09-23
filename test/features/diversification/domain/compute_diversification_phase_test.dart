import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/domain/use_cases/compute_diversification_phase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const compute = ComputeDiversificationPhase();
  final birth = DateTime(2026, 9, 15);

  test('nouveau-né : préparation, compte à rebours jusqu\'aux 6 mois', () {
    final t = compute(birthDate: birth, now: DateTime(2026, 9, 23, 8));
    expect(t.phase, DiversificationPhase.preparation);
    expect(t.ageMonths, 0);
    expect(t.sixMonthsDate, DateTime(2027, 3, 15));
    expect(t.daysUntilSixMonths, 173);
  });

  test('la veille des 6 mois : encore préparation, 1 jour', () {
    final t = compute(birthDate: birth, now: DateTime(2027, 3, 14, 23));
    expect(t.phase, DiversificationPhase.preparation);
    expect(t.daysUntilSixMonths, 1);
  });

  test('le jour des 6 mois : phase 6–8 mois, 0 jour', () {
    final t = compute(birthDate: birth, now: DateTime(2027, 3, 15));
    expect(t.phase, DiversificationPhase.months6To8);
    expect(t.ageMonths, 6);
    expect(t.daysUntilSixMonths, 0);
  });

  test('après les 6 mois, le compte à rebours reste à 0', () {
    final t = compute(birthDate: birth, now: DateTime(2027, 7, 1));
    expect(t.phase, DiversificationPhase.months9To11);
    expect(t.daysUntilSixMonths, 0);
  });

  test('date de naissance dans le futur : âge 0', () {
    final t = compute(birthDate: birth, now: DateTime(2026, 9, 1));
    expect(t.ageMonths, 0);
  });
}
