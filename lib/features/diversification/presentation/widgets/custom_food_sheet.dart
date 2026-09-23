import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/use_cases/validate_custom_food.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/features/diversification/presentation/providers/custom_food_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre la création (ou la modification si [food]) d'un aliment perso.
Future<void> showCustomFoodSheet(BuildContext context, {Food? food}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CustomFoodSheet(food: food),
    );

/// Nom, groupe OMS et allergènes d'un aliment perso.
class CustomFoodSheet extends ConsumerStatefulWidget {
  const CustomFoodSheet({super.key, this.food});

  final Food? food;

  @override
  ConsumerState<CustomFoodSheet> createState() => _CustomFoodSheetState();
}

class _CustomFoodSheetState extends ConsumerState<CustomFoodSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.food?.name ?? '',
  );
  late FoodGroup _group = widget.food?.group ?? FoodGroup.otherFruitsVeg;
  late final Set<Allergen> _allergens = {...?widget.food?.allergens};

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _toggle(Allergen allergen, bool selected) => setState(() {
    if (selected) {
      _allergens.add(allergen);
    } else {
      _allergens.remove(allergen);
    }
  });

  Future<void> _save() async {
    final ok = await ref
        .read(customFoodControllerProvider.notifier)
        .save(
          id: widget.food?.id,
          name: _name.text,
          group: _group,
          allergens: {..._allergens},
        );
    if (ok && mounted) await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    // Garde le contrôleur autoDispose vivant pendant l'await de _save.
    final saveState = ref.watch(customFoodControllerProvider);
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        shrinkWrap: true,
        padding: AppSpacing.lg.all,
        children: [
          Text(
            widget.food == null ? s.customFoodNewTitle : s.customFoodEditTitle,
            style: styles.heading2,
          ),
          AppSpacing.md.verticalSpace,
          TextField(
            controller: _name,
            autofocus: widget.food == null,
            maxLength: ValidateCustomFood.maxNameLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: s.customFoodFieldName),
          ),
          AppSpacing.sm.verticalSpace,
          Text(s.customFoodFieldGroup, style: styles.label),
          AppSpacing.xs.verticalSpace,
          Wrap(
            spacing: AppSpacing.sm.value,
            runSpacing: AppSpacing.xs.value,
            children: [
              for (final group in FoodGroup.values)
                ChoiceChip(
                  label: Text(group.shortLabel(s)),
                  selected: _group == group,
                  onSelected: (_) => setState(() => _group = group),
                ),
            ],
          ),
          AppSpacing.md.verticalSpace,
          Text(s.customFoodFieldAllergens, style: styles.label),
          AppSpacing.xs.verticalSpace,
          Wrap(
            spacing: AppSpacing.sm.value,
            runSpacing: AppSpacing.xs.value,
            children: [
              for (final allergen in Allergen.values)
                FilterChip(
                  label: Text(allergen.label(s)),
                  selected: _allergens.contains(allergen),
                  onSelected: (selected) => _toggle(allergen, selected),
                ),
            ],
          ),
          if (saveState case AsyncError(:final error)) ...[
            AppSpacing.md.verticalSpace,
            Text(
              failureMessage(error, s),
              style: styles.body.copyWith(
                color: context.appColor(AppColors.error),
              ),
            ),
          ],
          AppSpacing.lg.verticalSpace,
          FilledButton(
            onPressed: saveState is AsyncLoading ? null : _save,
            child: Text(s.actionSave),
          ),
        ],
      ),
    );
  }
}
