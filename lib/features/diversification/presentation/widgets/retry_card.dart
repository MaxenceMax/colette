import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_overview_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Aliments refusés ou jugés « bof » à reproposer ; rien si la liste est vide.
class RetryCard extends ConsumerWidget {
  const RetryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(foodsToRetryProvider);
    if (items.isEmpty) return const SizedBox.shrink();
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    return Padding(
      padding: AppSpacing.md.top,
      child: ColetteCardSurface(
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Text(s.retryTitle, style: styles.heading3),
            Text(s.retryHint, style: styles.small.copyWith(color: secondary)),
            AppSpacing.xs.verticalSpace,
            for (final item in items)
              InkWell(
                onTap: () => context.push(AppRoutes.plateFood(item.food.id)),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: AppSize.xl.value),
                  child: Center(
                    child: Padding(
                      padding: AppSpacing.xs.vertical,
                      child: Row(
                        spacing: AppSpacing.sm.value,
                        children: [
                          Expanded(
                            child: Text(item.food.name, style: styles.body),
                          ),
                          Text(
                            s.retryItem(
                              item.lastLiking.label(s),
                              item.tastingCount,
                            ),
                            style: styles.small.copyWith(color: secondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
