import 'package:colette/core/dates/date_extensions.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'care_frequency.freezed.dart';

/// Fréquence attendue d'un soin : `timesPerDay` fois par jour, ou une fois tous les `everyDays` jours.
/// Invariant : l'un des deux vaut 1. `enabled` faux = soin plus suivi, fréquence conservée.
@freezed
abstract class CareFrequency with _$CareFrequency {
  const CareFrequency._();

  const factory CareFrequency({
    @Default(1) int timesPerDay,
    @Default(1) int everyDays,
    @Default(true) bool enabled,
  }) = _CareFrequency;

  /// Espacement maximal réglable ; au-delà, on coupe le suivi.
  static const maxEveryDays = 7;

  /// Cran suivant vers « plus souvent » (bouton +) ; `null` en butée.
  CareFrequency? next(int maxTimesPerDay) {
    if (everyDays > 1) return copyWith(everyDays: everyDays - 1);
    if (timesPerDay < maxTimesPerDay) {
      return copyWith(timesPerDay: timesPerDay + 1);
    }
    return null;
  }

  /// Cran suivant vers « moins souvent » (bouton −) ; `null` en butée.
  CareFrequency? previous() {
    if (timesPerDay > 1) return copyWith(timesPerDay: timesPerDay - 1);
    if (everyDays < maxEveryDays) return copyWith(everyDays: everyDays + 1);
    return null;
  }

  /// Soin dû aujourd'hui : suivi actif, et quotidien, jamais fait,
  /// ou dernier fait il y a au moins [everyDays] jours civils.
  bool isExpected({required DateTime? lastDoneAt, required DateTime now}) {
    if (!enabled) return false;
    if (everyDays == 1 || lastDoneAt == null) return true;
    return calendarDaysBetween(lastDoneAt, now) >= everyDays;
  }
}
