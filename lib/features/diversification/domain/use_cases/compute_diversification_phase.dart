import 'dart:math';

import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/domain/entities/diversification_timeline.dart';

/// Phase OMS, mois révolus et jours restants avant 6 mois.
class ComputeDiversificationPhase {
  const ComputeDiversificationPhase();

  DiversificationTimeline call({
    required DateTime birthDate,
    required DateTime now,
  }) {
    final ageMonths = max(0, completedMonthsBetween(birthDate, now));
    final sixMonths = dateAfterCompletedMonths(
      birthDate,
      DiversificationAges.whoStartMonths,
    );
    return DiversificationTimeline(
      phase: DiversificationPhase.forAgeMonths(ageMonths),
      ageMonths: ageMonths,
      sixMonthsDate: sixMonths,
      daysUntilSixMonths: max(0, calendarDaysBetween(now, sixMonths)),
    );
  }
}
