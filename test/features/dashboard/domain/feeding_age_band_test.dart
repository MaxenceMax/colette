import 'package:colette/features/dashboard/domain/entities/feeding_age_band.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('jours 1 à 5 : une tranche par jour', () {
    expect(FeedingAgeBand.forDayOfLife(1), FeedingAgeBand.day1);
    expect(FeedingAgeBand.forDayOfLife(2), FeedingAgeBand.day2);
    expect(FeedingAgeBand.forDayOfLife(3), FeedingAgeBand.day3);
    expect(FeedingAgeBand.forDayOfLife(4), FeedingAgeBand.day4);
    expect(FeedingAgeBand.forDayOfLife(5), FeedingAgeBand.day5);
  });

  test('bornes des tranches suivantes', () {
    expect(FeedingAgeBand.forDayOfLife(6), FeedingAgeBand.day6ToMonth1);
    expect(FeedingAgeBand.forDayOfLife(30), FeedingAgeBand.day6ToMonth1);
    expect(FeedingAgeBand.forDayOfLife(31), FeedingAgeBand.month1To2);
    expect(FeedingAgeBand.forDayOfLife(60), FeedingAgeBand.month1To2);
    expect(FeedingAgeBand.forDayOfLife(61), FeedingAgeBand.month2To4);
    expect(FeedingAgeBand.forDayOfLife(120), FeedingAgeBand.month2To4);
    expect(FeedingAgeBand.forDayOfLife(121), FeedingAgeBand.month4To6);
    expect(FeedingAgeBand.forDayOfLife(180), FeedingAgeBand.month4To6);
    expect(FeedingAgeBand.forDayOfLife(181), FeedingAgeBand.month6Plus);
  });

  test('un jour de vie inférieur à 1 est traité comme le jour 1', () {
    expect(FeedingAgeBand.forDayOfLife(0), FeedingAgeBand.day1);
  });

  test('repères en ml par jour', () {
    expect(FeedingAgeBand.day1.dailyMl, 240);
    expect(FeedingAgeBand.day5.dailyMl, 480);
    expect(FeedingAgeBand.day6ToMonth1.dailyMl, 480);
    expect(FeedingAgeBand.month1To2.dailyMl, 630);
    expect(FeedingAgeBand.month2To4.dailyMl, 720);
    expect(FeedingAgeBand.month4To6.dailyMl, 900);
    expect(FeedingAgeBand.month6Plus.dailyMl, 900);
  });
}
