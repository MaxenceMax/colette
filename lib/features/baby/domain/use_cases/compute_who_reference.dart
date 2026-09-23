import 'dart:math' as math;

import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/baby/domain/entities/baby_sex.dart';
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:colette/features/baby/domain/entities/who_percentiles.dart';
import 'package:colette/features/baby/domain/reference/who_head_circumference_for_age.dart';
import 'package:colette/features/baby/domain/reference/who_length_for_age.dart';
import 'package:colette/features/baby/domain/reference/who_lms.dart';
import 'package:colette/features/baby/domain/reference/who_weight_for_age.dart';

/// Percentiles OMS d'une grandeur pour l'âge, jour par jour sur une période.
class ComputeWhoReference {
  const ComputeWhoReference();

  /// Dernier jour de vie couvert par les tables embarquées.
  static const maxAgeDays = 730;

  /// Score z du 97e percentile (et, au signe près, du 3e).
  static const _z97 = 1.880794;

  /// Un point par jour civil de [from] à [to] inclus, bornés à `[0, maxAgeDays]`.
  List<WhoPercentiles> call({
    required GrowthMetric metric,
    required BabySex sex,
    required DateTime birthDate,
    required DateTime from,
    required DateTime to,
  }) {
    final table = _table(metric, sex);
    // Tables en kg (poids) ou en cm (taille, périmètre) ; résultats en g ou mm.
    final unit = switch (metric) {
      GrowthMetric.weight => 1000,
      GrowthMetric.length || GrowthMetric.headCircumference => 10,
    };
    final first = math.max(0, calendarDaysBetween(birthDate, from));
    final last = math.min(maxAgeDays, calendarDaysBetween(birthDate, to));
    return [
      for (var day = first; day <= last; day++)
        WhoPercentiles(
          ageDays: day,
          date: DateTime(birthDate.year, birthDate.month, birthDate.day + day),
          p3: _value(table[day], -_z97, unit),
          p50: _value(table[day], 0, unit),
          p97: _value(table[day], _z97, unit),
        ),
    ];
  }

  static List<WhoLms> _table(GrowthMetric metric, BabySex sex) =>
      switch ((metric, sex)) {
        (GrowthMetric.weight, BabySex.female) => whoWeightForAgeGirls,
        (GrowthMetric.weight, BabySex.male) => whoWeightForAgeBoys,
        (GrowthMetric.length, BabySex.female) => whoLengthForAgeGirls,
        (GrowthMetric.length, BabySex.male) => whoLengthForAgeBoys,
        (GrowthMetric.headCircumference, BabySex.female) =>
          whoHeadCircumferenceForAgeGirls,
        (GrowthMetric.headCircumference, BabySex.male) =>
          whoHeadCircumferenceForAgeBoys,
      };

  /// Méthode LMS : `M × (1 + L·S·z)^(1/L)`, ou `M × e^(S·z)` si `L = 0`,
  /// convertie dans l'unité entière de la grandeur.
  static int _value(WhoLms lms, double z, int unit) {
    final (l, m, s) = lms;
    final value = l == 0
        ? m * math.exp(s * z)
        : m * math.pow(1 + l * s * z, 1 / l);
    return (value * unit).round();
  }
}
