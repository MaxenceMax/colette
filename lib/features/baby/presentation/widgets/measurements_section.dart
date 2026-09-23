import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/features/baby/presentation/widgets/growth_format.dart';
import 'package:colette/features/baby/presentation/widgets/growth_measurement_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Liste des mesures de croissance : ajout, modification et suppression.
class MeasurementsSection extends ConsumerWidget {
  const MeasurementsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final measurements =
        ref.watch(measurementsProvider).value ?? const <GrowthMeasurement>[];
    return ColetteCardSurface(
      padding: AppSpacing.sm.all,
      child: Column(
        children: [
          if (measurements.isEmpty)
            Padding(
              padding: AppSpacing.sm.all,
              child: Text(
                s.settingsMeasurementsEmpty,
                style: styles.body.copyWith(
                  color: context.appColor(AppColors.textSecondary),
                ),
              ),
            ),
          for (final measurement in measurements)
            ListTile(
              dense: true,
              title: Text(
                GrowthFormat.measurementLine(s, measurement),
                style: styles.bodyMedium,
              ),
              subtitle: Text(
                DateFormat.yMMMd('fr').format(measurement.measuredAt),
                style: styles.small,
              ),
              onTap: () =>
                  showGrowthMeasurementSheet(context, initial: measurement),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: s.actionDelete,
                onPressed: () => ref
                    .read(babySettingsControllerProvider.notifier)
                    .deleteMeasurement(measurement.id),
              ),
            ),
          TextButton.icon(
            onPressed: () => showGrowthMeasurementSheet(context),
            icon: const Icon(Icons.add),
            label: Text(s.actionAddMeasurement),
          ),
        ],
      ),
    );
  }
}
