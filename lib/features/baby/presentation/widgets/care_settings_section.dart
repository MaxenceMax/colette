import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/features/baby/presentation/widgets/care_frequency_row.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/int_stepper_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fréquence et suivi de chaque soin, et nombre de biberons par jour.
/// Tient une copie locale optimiste : des taps rapides s'enchaînent sans attendre Firestore.
class CareSettingsSection extends ConsumerStatefulWidget {
  const CareSettingsSection({super.key, required this.profile});

  final BabyProfile profile;

  @override
  ConsumerState<CareSettingsSection> createState() =>
      _CareSettingsSectionState();
}

class _CareSettingsSectionState extends ConsumerState<CareSettingsSection> {
  late CareSettings _settings = widget.profile.careSettings;

  @override
  void didUpdateWidget(covariant CareSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.profile.careSettings;
    final writing = ref.read(babySettingsControllerProvider).isLoading;
    if (incoming != oldWidget.profile.careSettings && !writing) {
      _settings = incoming;
    }
  }

  /// Fusionne le champ modifié dans le profil frais, pour ne jamais écraser
  /// un champ écrit entre-temps par `SleepSettingsSection`.
  void _update(CareSettings Function(CareSettings settings) apply) {
    setState(() => _settings = apply(_settings));
    ref
        .read(babySettingsControllerProvider.notifier)
        .updateCareSettings(widget.profile, apply(widget.profile.careSettings));
  }

  /// Borne haute « fois par jour » de chaque soin.
  static const _maxTimesPerDay = {
    CareType.adrigyl: 3,
    CareType.eyeCare: 4,
    CareType.noseCare: 4,
    CareType.umbilicalCare: 4,
    CareType.bath: 2,
  };

  @override
  Widget build(BuildContext context) {
    // Garde le contrôleur autoDispose vivant pendant l'await de updateCareSettings.
    ref.watch(babySettingsControllerProvider);
    final s = S.of(context);
    return ColetteCardSurface(
      padding: AppSpacing.sm.all,
      child: Column(
        spacing: AppSpacing.xs.value,
        children: [
          for (final type in CareType.scheduled)
            CareFrequencyRow(
              type: type,
              frequency: _settings.frequencyOf(type),
              maxTimesPerDay: _maxTimesPerDay[type]!,
              onChanged: (frequency) => _update(
                (settings) => settings.withFrequency(type, frequency),
              ),
            ),
          IntStepperRow(
            label: s.settingsFeedsPerDay,
            value: _settings.feedsPerDay,
            min: 4,
            max: 12,
            onChanged: (v) =>
                _update((settings) => settings.copyWith(feedsPerDay: v)),
          ),
        ],
      ),
    );
  }
}
