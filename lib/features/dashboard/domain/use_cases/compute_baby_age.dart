import 'dart:math';

import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/dashboard/domain/entities/baby_age.dart';

/// Jours jusqu'à 2 semaines, semaines jusqu'à 2 mois, puis mois civils.
class ComputeBabyAge {
  const ComputeBabyAge();

  BabyAge call({required DateTime birthDate, required DateTime now}) {
    final days = max(0, calendarDaysBetween(birthDate, now));
    if (days < 14) return BabyAge(unit: BabyAgeUnit.days, count: days);
    // Bascule en mois civils seulement à partir de 2 mois révolus : un seuil
    // en jours ferait afficher « 1 mois » juste après « 8 semaines ».
    final months = completedMonthsBetween(birthDate, now);
    if (months < 2) return BabyAge(unit: BabyAgeUnit.weeks, count: days ~/ 7);
    return BabyAge(unit: BabyAgeUnit.months, count: months);
  }
}
