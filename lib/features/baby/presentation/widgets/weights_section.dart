import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/features/baby/presentation/widgets/add_weight_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Liste des pesées, ajout et suppression.
class WeightsSection extends ConsumerWidget {
  const WeightsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final weights = ref.watch(weightsProvider).value ?? const <WeightEntry>[];
    return ColetteCardSurface(
      padding: AppSpacing.sm.all,
      child: Column(
        children: [
          if (weights.isEmpty)
            Padding(
              padding: AppSpacing.sm.all,
              child: Text(
                s.settingsWeightsEmpty,
                style: styles.body.copyWith(
                  color: context.appColor(AppColors.textSecondary),
                ),
              ),
            ),
          for (final weight in weights)
            ListTile(
              dense: true,
              title: Text(
                s.weightGrams(weight.grams),
                style: styles.bodyMedium,
              ),
              subtitle: Text(
                DateFormat.yMMMd('fr').format(weight.measuredAt),
                style: styles.small,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => ref
                    .read(babySettingsControllerProvider.notifier)
                    .deleteWeight(weight.id),
              ),
            ),
          TextButton.icon(
            onPressed: () => showAddWeightSheet(context),
            icon: const Icon(Icons.add),
            label: Text(s.settingsAddWeight),
          ),
        ],
      ),
    );
  }
}
