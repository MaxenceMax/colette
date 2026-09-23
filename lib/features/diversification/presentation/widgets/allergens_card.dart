import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/allergen_state.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_overview_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Les 9 allergènes suivis : pas encore, introduit ou réaction signalée.
class AllergensCard extends ConsumerWidget {
  const AllergensCard({super.key, required this.onAllergenTap});

  /// Filtre le catalogue sur l'allergène touché.
  final ValueChanged<Allergen> onAllergenTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final states = ref.watch(allergenProgressProvider);
    final introduced = states.values
        .where((state) => state != AllergenState.notYet)
        .length;
    return ColetteCardSurface(
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.sm.value,
        children: [
          Row(
            children: [
              Expanded(child: Text(s.allergensTitle, style: styles.heading3)),
              Text(
                s.allergensIntroduced(introduced, Allergen.tracked.length),
                style: styles.small.copyWith(
                  color: context.appColor(AppColors.textSecondary),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: AppSpacing.xs.value,
            runSpacing: AppSpacing.xs.value,
            children: [
              for (final MapEntry(key: allergen, value: state)
                  in states.entries)
                _AllergenChip(
                  allergen: allergen,
                  state: state,
                  onTap: () => onAllergenTap(allergen),
                ),
            ],
          ),
          Text(
            s.allergensHint,
            style: styles.small.copyWith(
              color: context.appColor(AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllergenChip extends StatelessWidget {
  const _AllergenChip({
    required this.allergen,
    required this.state,
    required this.onTap,
  });

  final Allergen allergen;
  final AllergenState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final (icon, color, stateLabel) = switch (state) {
      AllergenState.notYet => (
        Icons.radio_button_unchecked,
        AppColors.textSecondary,
        s.allergenStateNotYet,
      ),
      AllergenState.introduced => (
        Icons.check_circle_outline,
        AppColors.success,
        s.allergenStateIntroduced,
      ),
      AllergenState.reaction => (
        Icons.warning_amber,
        AppColors.warning,
        s.allergenStateReaction,
      ),
    };
    return Semantics(
      button: true,
      label: s.allergenSemantics(allergen.label(s), stateLabel),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.round.circular,
        child: Padding(
          padding: AppSpacing.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: .min,
            spacing: AppSpacing.xxs.value,
            children: [
              Icon(
                icon,
                size: AppSize.xs.value,
                color: context.appColor(color),
              ),
              Text(
                allergen.label(s),
                style: Theme.of(context).coletteTextStyles.small,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
