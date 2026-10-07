import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/features/baby/presentation/widgets/bottle_time_row.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/int_stepper_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Horaires des biberons : nombre par jour et heure de chacun.
/// Tient une copie locale optimiste, comme `CareSettingsSection`.
class BottleScheduleSettingsSection extends ConsumerStatefulWidget {
  const BottleScheduleSettingsSection({super.key, required this.profile});

  final BabyProfile profile;

  @override
  ConsumerState<BottleScheduleSettingsSection> createState() =>
      _BottleScheduleSettingsSectionState();
}

class _BottleScheduleSettingsSectionState
    extends ConsumerState<BottleScheduleSettingsSection> {
  late CareSettings _settings = widget.profile.careSettings;

  @override
  void didUpdateWidget(covariant BottleScheduleSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.profile.careSettings;
    final writing = ref.read(babySettingsControllerProvider).isLoading;
    if (incoming != oldWidget.profile.careSettings && !writing) {
      _settings = incoming;
    }
  }

  /// Fusionne le champ modifié dans le profil frais, pour ne jamais écraser
  /// un champ écrit entre-temps par une autre section des réglages.
  void _update(CareSettings Function(CareSettings settings) apply) {
    setState(() => _settings = apply(_settings));
    ref
        .read(babySettingsControllerProvider.notifier)
        .updateCareSettings(widget.profile, apply(widget.profile.careSettings));
  }

  /// Grille calculée une seule fois depuis la copie locale, puis fusionnée
  /// seule (`bottleTimesMinutes`) dans le profil frais.
  void _setTimes(List<int> times) =>
      _update((settings) => settings.copyWith(bottleTimesMinutes: times));

  void _setCount(int count) =>
      _setTimes(_settings.withBottleCount(count).bottleTimesMinutes);

  void _setTime(int index, int minutes) {
    final next = _settings.withBottleTime(index, minutes);
    if (next == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).settingsBottleTimeTooClose)),
      );
      return;
    }
    _setTimes(next.bottleTimesMinutes);
  }

  @override
  Widget build(BuildContext context) {
    // Garde le contrôleur autoDispose vivant pendant l'await de updateCareSettings.
    ref.watch(babySettingsControllerProvider);
    final s = S.of(context);
    final times = _settings.bottleTimesMinutes;
    final count = times.length;
    return ColetteCardSurface(
      padding: AppSpacing.sm.all,
      child: Column(
        crossAxisAlignment: .start,
        children: [
          IntStepperRow(
            label: s.settingsBottlesPerDay,
            value: count,
            min: count < CareSettings.minBottlesPerDay
                ? count
                : CareSettings.minBottlesPerDay,
            max: _settings.canAddBottle ? count + 1 : count,
            onChanged: _setCount,
          ),
          for (var i = 0; i < count; i++)
            BottleTimeRow(
              key: ValueKey(i),
              index: i,
              minutes: times[i],
              onChanged: (minutes) => _setTime(i, minutes),
            ),
        ],
      ),
    );
  }
}
