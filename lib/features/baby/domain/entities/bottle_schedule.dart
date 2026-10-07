import 'package:freezed_annotation/freezed_annotation.dart';

part 'bottle_schedule.freezed.dart';

/// Grille des biberons : horaires fixes de la journée, triés.
@freezed
abstract class BottleSchedule with _$BottleSchedule {
  const BottleSchedule._();

  const factory BottleSchedule({
    /// Horaires depuis minuit, triés, espacés d'au moins 30 min (y compris du
    /// dernier au premier du lendemain). Jamais vide (non vérifiable en `const`).
    @Default(defaultBottleTimes) List<Duration> times,
  }) = _BottleSchedule;

  /// Grille tirée des anciens réglages (premier, soir, intervalle) : chaîne
  /// `first + k × interval` avant le soir ; le soir s'ajoute s'il est à au moins
  /// un demi-intervalle du dernier créneau, sinon il le remplace.
  factory BottleSchedule.fromLegacy({
    required Duration first,
    required Duration last,
    required Duration interval,
  }) {
    final span = last - first;
    if (span <= Duration.zero || interval <= Duration.zero) {
      return BottleSchedule(times: [first]);
    }
    final slots = (span.inMinutes / interval.inMinutes).ceil();
    final chain = [for (var i = 0; i < slots; i++) first + interval * i];
    final gap = span - interval * (slots - 1);
    final replaces = gap < interval ~/ 2 && slots > 1;
    return BottleSchedule(
      times: [...replaces ? chain.sublist(0, slots - 1) : chain, last],
    );
  }

  /// Biberons par jour.
  int get feedsPerDay => times.length;

  /// Créneau daté le plus proche de [at] ; au milieu exact, le plus tardif.
  DateTime slotOf(DateTime at) {
    final day = DateTime(at.year, at.month, at.day);
    final slots = [
      _at(_shift(day, -1), times.last),
      for (final time in times) _at(day, time),
      _at(_shift(day, 1), times.first),
    ];
    for (var i = 0; i < slots.length - 1; i++) {
      final from = slots[i];
      final to = slots[i + 1];
      if (at.isBefore(from) || !at.isBefore(to)) continue;
      final middle = from.add(to.difference(from) ~/ 2);
      return at.isBefore(middle) ? from : to;
    }
    return slots.last;
  }

  /// Horaire prévu après un biberon donné à [last] : celui qui suit
  /// l'horaire auquel [last] est rattaché ([slotOf]).
  DateTime nextAfter(DateTime last) => _slotAfter(slotOf(last));

  /// Horaire attendu à [now] : le plus tardif de [nextAfter] et de
  /// l'horaire le plus proche de [now]. Un horaire sauté reste dû jusqu'au
  /// milieu de l'écart avec le suivant ; la nuit ne compte aucun retard.
  DateTime nextDue(DateTime last, DateTime now) {
    final next = nextAfter(last);
    final current = slotOf(now);
    return current.isAfter(next) ? current : next;
  }

  /// Premier horaire de la journée strictement après [at].
  DateTime morningAfter(DateTime at) {
    final day = DateTime(at.year, at.month, at.day);
    final morning = _at(day, times.first);
    return morning.isAfter(at) ? morning : _at(_shift(day, 1), times.first);
  }

  /// Créneau qui suit [slot] dans la grille.
  DateTime _slotAfter(DateTime slot) {
    final day = DateTime(slot.year, slot.month, slot.day);
    final minutes = slot.hour * 60 + slot.minute;
    for (final time in times) {
      if (time.inMinutes > minutes) return _at(day, time);
    }
    return _at(_shift(day, 1), times.first);
  }

  static DateTime _shift(DateTime day, int days) =>
      DateTime(day.year, day.month, day.day + days);

  /// [day] (à minuit) décalé de [time], en heure locale.
  static DateTime _at(DateTime day, Duration time) =>
      DateTime(day.year, day.month, day.day, 0, time.inMinutes);
}

/// Grille par défaut : 07h00, 10h00, 13h00, 16h00, 19h00, 22h00, 23h30.
const defaultBottleTimes = [
  Duration(hours: 7),
  Duration(hours: 10),
  Duration(hours: 13),
  Duration(hours: 16),
  Duration(hours: 19),
  Duration(hours: 22),
  Duration(hours: 23, minutes: 30),
];
