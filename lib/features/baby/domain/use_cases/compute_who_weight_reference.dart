import 'dart:math' as math;

import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/baby/domain/entities/baby_sex.dart';
import 'package:colette/features/baby/domain/entities/who_weight_percentiles.dart';
import 'package:colette/features/baby/domain/reference/who_weight_for_age.dart';

/// Percentiles OMS du poids pour l'âge, jour par jour sur une période.
class ComputeWhoWeightReference {
  const ComputeWhoWeightReference();

  /// Dernier jour de vie couvert par la table embarquée.
  static const maxAgeDays = 730;

  /// Score z du 97e percentile (et, au signe près, du 3e).
  static const _z97 = 1.880794;

  /// Un point par jour civil de [from] à [to] inclus, bornés à `[0, maxAgeDays]`.
  List<WhoWeightPercentiles> call({
    required BabySex sex,
    required DateTime birthDate,
    required DateTime from,
    required DateTime to,
  }) {
    final table = switch (sex) {
      BabySex.female => whoWeightForAgeGirls,
      BabySex.male => whoWeightForAgeBoys,
    };
    final first = math.max(0, calendarDaysBetween(birthDate, from));
    final last = math.min(maxAgeDays, calendarDaysBetween(birthDate, to));
    return [
      for (var day = first; day <= last; day++)
        WhoWeightPercentiles(
          ageDays: day,
          date: DateTime(birthDate.year, birthDate.month, birthDate.day + day),
          p3Grams: _grams(table[day], -_z97),
          p50Grams: _grams(table[day], 0),
          p97Grams: _grams(table[day], _z97),
        ),
    ];
  }

  /// Méthode LMS : `M × (1 + L·S·z)^(1/L)`, ou `M × e^(S·z)` si `L = 0`.
  static int _grams(WhoLms lms, double z) {
    final (l, m, s) = lms;
    final kg = l == 0
        ? m * math.exp(s * z)
        : m * math.pow(1 + l * s * z, 1 / l);
    return (kg * 1000).round();
  }
}
