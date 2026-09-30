import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/int_stepper_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Horaires des biberons : premier, soir, intervalle, et nombre déduit par jour.
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

  @override
  Widget build(BuildContext context) {
    // Garde le contrôleur autoDispose vivant pendant l'await de updateCareSettings.
    ref.watch(babySettingsControllerProvider);
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    String hoursMinutes(int minutes) => s.durationHoursMinutes(
      minutes ~/ 60,
      (minutes % 60).toString().padLeft(2, '0'),
    );
    return ColetteCardSurface(
      padding: AppSpacing.sm.all,
      child: Column(
        crossAxisAlignment: .start,
        children: [
          IntStepperRow(
            label: s.settingsFirstBottle,
            value: _settings.firstBottleMinutes,
            min: CareSettings.minFirstBottleMinutes,
            max: CareSettings.maxFirstBottleMinutes,
            step: CareSettings.bottleTimeStepMinutes,
            format: hoursMinutes,
            onChanged: (v) =>
                _update((settings) => settings.copyWith(firstBottleMinutes: v)),
          ),
          IntStepperRow(
            label: s.settingsLastBottle,
            value: _settings.lastBottleMinutes,
            min: CareSettings.minLastBottleMinutes,
            max: CareSettings.maxLastBottleMinutes,
            step: CareSettings.bottleTimeStepMinutes,
            format: hoursMinutes,
            onChanged: (v) =>
                _update((settings) => settings.copyWith(lastBottleMinutes: v)),
          ),
          IntStepperRow(
            label: s.settingsBottleInterval,
            value: _settings.bottleIntervalMinutes,
            min: CareSettings.minBottleIntervalMinutes,
            max: CareSettings.maxBottleIntervalMinutes,
            step: CareSettings.bottleTimeStepMinutes,
            format: hoursMinutes,
            onChanged: (v) => _update(
              (settings) => settings.copyWith(bottleIntervalMinutes: v),
            ),
          ),
          Padding(
            padding: AppSpacing.xs.vertical,
            child: Text(
              s.settingsFeedsPerDaySummary(
                _settings.bottleSchedule.feedsPerDay,
              ),
              style: styles.small.copyWith(
                color: context.appColor(AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
