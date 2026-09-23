import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/duration_format.dart';

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

/// Alias de [formatDuration] pour les écrans du sommeil.
String formatSleepDuration(Duration duration, S s) =>
    formatDuration(duration, s);
