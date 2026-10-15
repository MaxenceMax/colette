import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diversification/domain/entities/diversification_timeline.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:colette/features/diversification/presentation/widgets/add_tasting_button.dart';
import 'package:colette/features/diversification/presentation/widgets/guide_item_tile.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Avant 6 mois : compte à rebours, repères OMS / France / pédiatre, étapes
/// datées atteintes à son âge, signes que bébé est prêt.
class PreparationCard extends ConsumerWidget {
  const PreparationCard({super.key, required this.timeline});

  final DiversificationTimeline timeline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final guide = ref.watch(foodCatalogProvider).value?.guide;
    final signs = guide?.readinessSigns ?? const [];
    final steps = [
      for (final item in guide?.phases[timeline.phase]?.items ?? const [])
        if (item.fromMonths case final from? when from <= timeline.ageMonths)
          item,
    ];
    return ColetteCardSurface(
      backgroundColor: AppColors.primaryContainer,
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.sm.value,
        children: [
          Text(s.preparationTitle, style: styles.heading3),
          Text(
            s.preparationCountdown(timeline.daysUntilSixMonths),
            style: styles.heading2,
          ),
          Text(
            s.preparationReferences,
            style: styles.small.copyWith(
              color: context.appColor(AppColors.textSecondary),
            ),
          ),
          if (steps.isNotEmpty) ...[
            Text(s.preparationAtAge, style: styles.label),
            for (final step in steps) GuideItemTile(item: step),
          ],
          if (signs.isNotEmpty) ...[
            Text(s.guideReadiness, style: styles.label),
            for (final sign in signs) GuideItemTile(item: sign),
          ],
          const AddTastingButton(),
        ],
      ),
    );
  }
}
