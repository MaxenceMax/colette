/// Tranches d'âge des repères OMS : cible journalière indicative sans pesée.
enum FeedingAgeBand {
  day1(240),
  day2(320),
  day3(400),
  day4(440),
  day5(480),
  day6ToMonth1(480),
  month1To2(630),
  month2To4(720),
  month4To6(900),
  month6Plus(900);

  const FeedingAgeBand(this.dailyMl);

  /// Repère journalier en ml.
  final int dailyMl;

  /// Tranche d'un jour de vie (1 = jour de naissance) ; tout jour inférieur à 1
  /// est ramené au jour 1.
  static FeedingAgeBand forDayOfLife(int dayOfLife) => switch (dayOfLife) {
    <= 1 => day1,
    2 => day2,
    3 => day3,
    4 => day4,
    5 => day5,
    <= 30 => day6ToMonth1,
    <= 60 => month1To2,
    <= 120 => month2To4,
    <= 180 => month4To6,
    _ => month6Plus,
  };
}
