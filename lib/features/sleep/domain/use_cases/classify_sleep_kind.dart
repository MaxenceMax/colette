import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';

/// Nuit si l'heure de [startAt] tombe dans `[nightStartHour, nightEndHour[`
/// (fenêtre qui peut passer minuit), sinon sieste. Bornes égales : sieste.
SleepKind classifySleepKind(
  DateTime startAt, {
  required int nightStartHour,
  required int nightEndHour,
}) {
  if (nightStartHour == nightEndHour) return SleepKind.nap;
  final hour = startAt.hour;
  final isNight = nightStartHour < nightEndHour
      ? hour >= nightStartHour && hour < nightEndHour
      : hour >= nightStartHour || hour < nightEndHour;
  return isNight ? SleepKind.night : SleepKind.nap;
}
