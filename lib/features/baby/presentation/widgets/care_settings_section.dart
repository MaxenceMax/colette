import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/int_stepper_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fréquences des soins attendus et nombre de biberons par jour.
class CareSettingsSection extends ConsumerWidget {
  const CareSettingsSection({super.key, required this.settings});

  final CareSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    void update(CareSettings next) => ref
        .read(babySettingsControllerProvider.notifier)
        .updateCareSettings(next);
    return ColetteCardSurface(
      padding: AppSpacing.sm.all,
      child: Column(
        children: [
          IntStepperRow(
            label: s.settingsAdrigylPerDay,
            value: settings.adrigylPerDay,
            min: 0,
            max: 3,
            onChanged: (v) => update(settings.copyWith(adrigylPerDay: v)),
          ),
          IntStepperRow(
            label: s.settingsEyeCarePerDay,
            value: settings.eyeCarePerDay,
            min: 0,
            max: 4,
            onChanged: (v) => update(settings.copyWith(eyeCarePerDay: v)),
          ),
          IntStepperRow(
            label: s.settingsNoseCarePerDay,
            value: settings.noseCarePerDay,
            min: 0,
            max: 4,
            onChanged: (v) => update(settings.copyWith(noseCarePerDay: v)),
          ),
          IntStepperRow(
            label: s.settingsBathEveryDays,
            value: settings.bathEveryDays,
            min: 1,
            max: 7,
            onChanged: (v) => update(settings.copyWith(bathEveryDays: v)),
          ),
          IntStepperRow(
            label: s.settingsFeedsPerDay,
            value: settings.feedsPerDay,
            min: 4,
            max: 12,
            onChanged: (v) => update(settings.copyWith(feedsPerDay: v)),
          ),
          SwitchListTile(
            contentPadding: AppSpacing.sm.horizontal,
            title: Text(
              s.settingsUmbilicalEnabled,
              style: Theme.of(context).coletteTextStyles.body,
            ),
            value: settings.umbilicalCareEnabled,
            onChanged: (v) =>
                update(settings.copyWith(umbilicalCareEnabled: v)),
          ),
        ],
      ),
    );
  }
}
