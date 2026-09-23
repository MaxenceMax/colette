import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_overview_providers.dart';
import 'package:colette/features/diversification/presentation/widgets/food_row.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Catalogue filtré, en-tête par groupe OMS puis aliments.
class FoodCatalogSliver extends ConsumerWidget {
  const FoodCatalogSliver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(filteredCatalogProvider);
    final statuses = ref.watch(foodStatusesProvider);
    if (sections.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyState(
          icon: Icons.search_off,
          message: S.of(context).catalogEmpty,
        ),
      );
    }
    final entries = <Object>[
      for (final section in sections) ...[section.group, ...section.foods],
    ];
    return SliverList.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) => switch (entries[index]) {
        final FoodGroup group => _GroupHeader(group: group),
        final Food food => FoodRow(food: food, status: statuses[food.id]),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final FoodGroup group;

  @override
  Widget build(BuildContext context) => Padding(
    padding: AppSpacing.only(top: AppSpacing.md, bottom: AppSpacing.xs),
    child: Text(
      group.label(S.of(context)),
      style: Theme.of(context).coletteTextStyles.label
          .copyWith(color: context.appColor(AppColors.textSecondary)),
    ),
  );
}
