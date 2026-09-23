import 'package:colette/features/sleep/domain/entities/sleep_age_band.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final birth = DateTime(2026, 1, 15);
  SleepAgeBand? at(DateTime now) =>
      SleepAgeBand.forAge(birthDate: birth, now: now);

  test('moins de 4 mois : 14 à 17 h', () {
    expect(at(DateTime(2026, 1, 15)), SleepAgeBand.under4Months);
    expect(at(DateTime(2026, 5, 14)), SleepAgeBand.under4Months);
    expect(SleepAgeBand.under4Months.minHours, 14);
    expect(SleepAgeBand.under4Months.maxHours, 17);
  });

  test('4 à 11 mois : 12 à 16 h', () {
    expect(at(DateTime(2026, 5, 15)), SleepAgeBand.months4To11);
    expect(at(DateTime(2027, 1, 14)), SleepAgeBand.months4To11);
    expect(SleepAgeBand.months4To11.minHours, 12);
    expect(SleepAgeBand.months4To11.maxHours, 16);
  });

  test('12 à 23 mois : 11 à 14 h', () {
    expect(at(DateTime(2027, 1, 15)), SleepAgeBand.months12To23);
    expect(at(DateTime(2028, 1, 14)), SleepAgeBand.months12To23);
    expect(SleepAgeBand.months12To23.minHours, 11);
    expect(SleepAgeBand.months12To23.maxHours, 14);
  });

  test('24 mois et plus : aucun repère', () {
    expect(at(DateTime(2028, 1, 15)), isNull);
  });
}
