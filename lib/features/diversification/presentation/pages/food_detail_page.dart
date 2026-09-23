import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_status.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/features/diversification/presentation/providers/custom_food_controller.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_overview_providers.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:colette/features/diversification/presentation/providers/tasting_form_controller.dart';
import 'package:colette/features/diversification/presentation/widgets/custom_food_sheet.dart';
import 'package:colette/features/diversification/presentation/widgets/food_status_badge.dart';
import 'package:colette/features/diversification/presentation/widgets/rule_tile.dart';
import 'package:colette/features/diversification/presentation/widgets/tasting_form_sheet.dart';
import 'package:colette/features/diversification/presentation/widgets/tasting_history_sliver.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fiche d'un aliment : statut, repères sourcés, allergènes, dégustations.
class FoodDetailPage extends ConsumerWidget {
  const FoodDetailPage({super.key, required this.foodId});

  final String foodId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Garde les contrôleurs autoDispose vivants pendant les suppressions
    // lancées depuis l'historique ou le bouton de suppression.
    ref
      ..listen(tastingFormControllerProvider, (_, _) {})
      ..listen(customFoodControllerProvider, (_, _) {});
    return switch (ref.watch(foodsProvider)) {
      AsyncData(:final value) => _FoodDetailView(
        food: value[foodId] ?? Food.unknown(foodId),
      ),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.error_outline,
          message: failureMessage(error, S.of(context)),
        ),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class _FoodDetailView extends ConsumerWidget {
  const _FoodDetailView({required this.food});

  final Food food;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    final status = ref.watch(foodStatusesProvider)[food.id];
    final hasTastings = ref.watch(tastingsForFoodProvider(food.id)).isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(foodDisplayName(food, s)),
        actions: [
          if (food.isCustom)
            IconButton(
              tooltip: s.actionEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => showCustomFoodSheet(context, food: food),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: AppSpacing.md.all,
            sliver: SliverList.list(
              children: [
                Row(
                  spacing: AppSpacing.sm.value,
                  children: [
                    Expanded(
                      child: Text(
                        food.group.label(s),
                        style: styles.body.copyWith(color: secondary),
                      ),
                    ),
                    if (status != null)
                      Flexible(child: FoodStatusBadge(status: status)),
                  ],
                ),
                if (status is FoodStatusNotYetRecommended)
                  Text(
                    s.statusNotYetFrance,
                    style: styles.small.copyWith(color: secondary),
                  ),
                if (food.isCustom)
                  Text(
                    s.foodDetailCustom,
                    style: styles.small.copyWith(color: secondary),
                  ),
                if (!food.isUnknown) ...[
                  AppSpacing.md.verticalSpace,
                  FilledButton.icon(
                    onPressed: () => showTastingFormSheet(context, food: food),
                    icon: const Icon(Icons.add),
                    label: Text(s.actionAddTasting),
                  ),
                ],
                SectionHeader(title: s.foodDetailRules),
                if (food.rules.isEmpty)
                  Text(s.foodDetailNoRules, style: styles.body)
                else
                  for (final rule in food.rules) RuleTile(rule: rule),
                SectionHeader(title: s.foodDetailAllergens),
                Text(
                  food.allergens.isEmpty
                      ? s.foodDetailNoAllergen
                      : food.allergens.map((a) => a.label(s)).join(', '),
                  style: styles.body,
                ),
                SectionHeader(title: s.foodDetailHistory),
              ],
            ),
          ),
          SliverPadding(
            padding: AppSpacing.md.horizontal,
            sliver: TastingHistorySliver(food: food),
          ),
          if (food.isCustom && !hasTastings)
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.md.all,
                child: _DeleteFoodButton(food: food),
              ),
            ),
          SliverToBoxAdapter(child: AppSpacing.xl.verticalSpace),
        ],
      ),
    );
  }
}

class _DeleteFoodButton extends ConsumerWidget {
  const _DeleteFoodButton({required this.food});

  final Food food;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(s.foodDetailDeleteFoodConfirm(food.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await ref
        .read(customFoodControllerProvider.notifier)
        .delete(food.id);
    if (!context.mounted) return;
    if (ok) {
      await Navigator.of(context).maybePop();
      return;
    }
    final error = ref.read(customFoodControllerProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failureMessage(error ?? s.errorUnknown, s))),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextButton.icon(
    onPressed: () => _delete(context, ref),
    icon: Icon(Icons.delete_outline, color: context.appColor(AppColors.error)),
    label: Text(
      S.of(context).foodDetailDeleteFood,
      style: Theme.of(context).coletteTextStyles.label
          .copyWith(color: context.appColor(AppColors.error)),
    ),
  );
}
