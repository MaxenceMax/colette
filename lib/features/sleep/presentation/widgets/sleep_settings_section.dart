import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/int_stepper_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Horaires de nuit qui classent un endormissement en sieste ou en nuit.
/// Tient une copie locale optimiste, comme `CareSettingsSection`.
class SleepSettingsSection extends ConsumerStatefulWidget {
  const SleepSettingsSection({super.key, required this.profile});

  final BabyProfile profile;

  @override
  ConsumerState<SleepSettingsSection> createState() =>
      _SleepSettingsSectionState();
}

class _SleepSettingsSectionState extends ConsumerState<SleepSettingsSection> {
  late CareSettings _settings = widget.profile.careSettings;

  @override
  void didUpdateWidget(covariant SleepSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.profile.careSettings;
    final writing = ref.read(babySettingsControllerProvider).isLoading;
    if (incoming != oldWidget.profile.careSettings && !writing) {
      _settings = incoming;
    }
  }

  void _update(CareSettings next) {
    setState(() => _settings = next);
    ref
        .read(babySettingsControllerProvider.notifier)
        .updateCareSettings(widget.profile, next);
  }

  @override
  Widget build(BuildContext context) {
    // Garde le contrôleur autoDispose vivant pendant l'await de updateCareSettings.
    ref.watch(babySettingsControllerProvider);
    final s = S.of(context);
    return ColetteCardSurface(
      padding: AppSpacing.sm.all,
      child: Column(
        children: [
          IntStepperRow(
            label: s.settingsNightStart,
            value: _settings.nightStartHour,
            min: 0,
            max: 23,
            suffix: s.hourSuffix,
            onChanged: (v) => _update(_settings.copyWith(nightStartHour: v)),
          ),
          IntStepperRow(
            label: s.settingsNightEnd,
            value: _settings.nightEndHour,
            min: 0,
            max: 23,
            suffix: s.hourSuffix,
            onChanged: (v) => _update(_settings.copyWith(nightEndHour: v)),
          ),
        ],
      ),
    );
  }
}
