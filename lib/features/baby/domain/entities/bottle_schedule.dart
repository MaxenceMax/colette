import 'package:freezed_annotation/freezed_annotation.dart';

part 'bottle_schedule.freezed.dart';

/// Rythme des biberons : premier du matin, biberon du soir et intervalle.
@freezed
abstract class BottleSchedule with _$BottleSchedule {
  const BottleSchedule._();

  const factory BottleSchedule({
    /// Heure du premier biberon, depuis minuit.
    @Default(Duration(hours: 7)) Duration firstBottle,

    /// Heure du biberon du soir, depuis minuit ; rien n'est prévu après.
    @Default(Duration(hours: 23, minutes: 30)) Duration lastBottle,

    /// Temps entre deux biberons de journée.
    @Default(Duration(hours: 3)) Duration interval,
  }) = _BottleSchedule;

  /// Demi-largeur de la fourchette autour de l'heure prévue.
  static const halfWindow = Duration(minutes: 30);

  /// Heure prévue du biberon qui suit celui donné à [last].
  ///
  /// Biberon de journée (dès 30 min avant le premier, jusqu'à 30 min avant
  /// celui du soir) : `last + interval`, rabattu sur le biberon du soir s'il en
  /// est à au moins un demi-intervalle ; plus près, il tient lieu de biberon du
  /// soir. Biberon du soir ou de nuit : premier biberon du matin suivant, ou
  /// `last + interval` s'il tombe plus tard.
  DateTime nextAfter(DateTime last) {
    assert(interval > Duration.zero, 'interval must be positive');
    final planned = last.add(interval);
    final day = DateTime(last.year, last.month, last.day);
    final morning = _at(day, firstBottle);
    final evening = _at(day, lastBottle);
    final isDaytime =
        !last.isBefore(morning.subtract(halfWindow)) &&
        last.isBefore(evening.subtract(halfWindow));
    if (isDaytime && !planned.isAfter(evening)) return planned;
    // Assez loin du biberon du soir : rabattu dessus ; sinon il en tient lieu.
    if (isDaytime && evening.difference(last) >= interval ~/ 2) return evening;
    final nextMorning = morningAfter(last);
    return planned.isAfter(nextMorning) ? planned : nextMorning;
  }

  /// Premier biberon du matin strictement après [at].
  DateTime morningAfter(DateTime at) {
    final day = DateTime(at.year, at.month, at.day);
    final morning = _at(day, firstBottle);
    return morning.isAfter(at)
        ? morning
        : _at(DateTime(day.year, day.month, day.day + 1), firstBottle);
  }

  /// Premier biberon de la journée en cours à [now] : celui du jour, puis
  /// celui du lendemain dès l'ouverture de la fourchette du soir.
  DateTime upcomingMorning(DateTime now) {
    final day = DateTime(now.year, now.month, now.day);
    final eveningStart = _at(day, lastBottle).subtract(halfWindow);
    return now.isBefore(eveningStart)
        ? _at(day, firstBottle)
        : _at(DateTime(day.year, day.month, day.day + 1), firstBottle);
  }

  /// Biberon attendu à [now] après un biberon donné à [last] : [nextAfter],
  /// ou, une fois sa fourchette finie et la soirée entamée ou passée, le premier biberon
  /// du matin, pour ne pas compter de retard la nuit.
  DateTime nextDue(DateTime last, DateTime now) {
    final next = nextAfter(last);
    if (!now.isAfter(next.add(halfWindow))) return next;
    final morning = upcomingMorning(now);
    return morning.isAfter(next) ? morning : next;
  }

  /// Fourchette de 30 min avant à 30 min après [at].
  (DateTime, DateTime) windowAround(DateTime at) =>
      (at.subtract(halfWindow), at.add(halfWindow));

  /// Biberons de journée du premier au soir ; au moins 1. Le dernier créneau
  /// tient lieu de biberon du soir s'il en est à moins d'un demi-intervalle.
  int get feedsPerDay {
    final span = lastBottle - firstBottle;
    if (span <= Duration.zero || interval <= Duration.zero) return 1;
    final slots = (span.inMinutes / interval.inMinutes).ceil();
    final gap = span - interval * (slots - 1);
    return gap < interval ~/ 2 ? slots : slots + 1;
  }

  /// [day] (à minuit) décalé de [time], en heure locale.
  static DateTime _at(DateTime day, Duration time) =>
      DateTime(day.year, day.month, day.day, 0, time.inMinutes);
}
