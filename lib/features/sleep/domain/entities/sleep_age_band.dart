import 'package:colette/core/dates/date_extensions.dart';

/// Durée de sommeil recommandée sur 24 h, siestes comprises (OMS 2019).
enum SleepAgeBand {
  under4Months(minHours: 14, maxHours: 17),
  months4To11(minHours: 12, maxHours: 16),
  months12To23(minHours: 11, maxHours: 14);

  const SleepAgeBand({required this.minHours, required this.maxHours});

  final int minHours;
  final int maxHours;

  /// Tranche selon l'âge en mois révolus ; `null` à partir de 24 mois.
  static SleepAgeBand? forAge({
    required DateTime birthDate,
    required DateTime now,
  }) {
    final months = completedMonthsBetween(birthDate, now);
    if (months < 4) return under4Months;
    if (months < 12) return months4To11;
    if (months < 24) return months12To23;
    return null;
  }
}
