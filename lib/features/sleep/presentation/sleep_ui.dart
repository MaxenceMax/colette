import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:colette/l10n/generated/app_localizations.dart';

/// Libellé et couleur d'un [SleepKind].
extension SleepKindUi on SleepKind {
  String label(S s) => switch (this) {
    SleepKind.nap => s.sleepKindNap,
    SleepKind.night => s.sleepKindNight,
  };

  /// Couleur de remplissage sur la frise.
  AppColors get fill => switch (this) {
    SleepKind.nap => AppColors.sleepNap,
    SleepKind.night => AppColors.sleepNight,
  };
}

/// « 42 min », « 2 h », « 1 h 05 ». Une durée négative est bornée à zéro.
String formatSleepDuration(Duration duration, S s) {
  final minutes = duration.isNegative ? 0 : duration.inMinutes;
  if (minutes < Duration.minutesPerHour) return s.durationMinutes(minutes);
  final hours = minutes ~/ Duration.minutesPerHour;
  final rest = minutes % Duration.minutesPerHour;
  if (rest == 0) return s.durationHours(hours);
  return s.durationHoursMinutes(hours, rest.toString().padLeft(2, '0'));
}
