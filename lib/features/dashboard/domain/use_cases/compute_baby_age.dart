import 'dart:math';

import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/dashboard/domain/entities/baby_age.dart';

/// Jours jusqu'à 2 semaines, semaines jusqu'à 2 mois, puis mois civils.
class ComputeBabyAge {
  const ComputeBabyAge();

  BabyAge call({required DateTime birthDate, required DateTime now}) {
    final days = max(0, now.dateOnly.difference(birthDate.dateOnly).inDays);
    if (days < 14) return BabyAge(unit: BabyAgeUnit.days, count: days);
    if (days < 61) return BabyAge(unit: BabyAgeUnit.weeks, count: days ~/ 7);
    return BabyAge(
      unit: BabyAgeUnit.months,
      count: _monthsBetween(birthDate, now),
    );
  }

  static int _monthsBetween(DateTime from, DateTime to) {
    final months = (to.year - from.year) * 12 + to.month - from.month;
    return to.day < from.day ? months - 1 : months;
  }
}
