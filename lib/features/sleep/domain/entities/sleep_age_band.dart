import 'package:colette/core/dates/date_extensions.dart';

/// Durée de sommeil recommandée sur 24 h, siestes comprises (OMS 2019).
enum SleepAgeBand {
  under4Months(minHours: 14, maxHours: 17, untilMonths: 4),
  months4To11(minHours: 12, maxHours: 16, untilMonths: 12),
  months12To23(minHours: 11, maxHours: 14, untilMonths: 24);

  const SleepAgeBand({
    required this.minHours,
    required this.maxHours,
    required this.untilMonths,
  });

  final int minHours;
  final int maxHours;
  final int untilMonths;

  /// Tranche selon l'âge en mois révolus ; `null` à partir de 24 mois.
  static SleepAgeBand? forAge({
    required DateTime birthDate,
    required DateTime now,
  }) {
    final months = completedMonthsBetween(birthDate, now);
    return values.where((band) => months < band.untilMonths).firstOrNull;
  }
}
