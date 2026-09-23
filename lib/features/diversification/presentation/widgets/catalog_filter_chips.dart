import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/diversification/domain/entities/food_filter.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/features/diversification/presentation/providers/catalog_filter.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tous / Pas goûtés / À éviter, et filtre allergène actif.
class CatalogFilterChips extends ConsumerWidget {
  const CatalogFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final filter = ref.watch(catalogFilterProvider);
    return Wrap(
      spacing: AppSpacing.sm.value,
      runSpacing: AppSpacing.xs.value,
      children: [
        for (final mode in CatalogMode.values)
          ChoiceChip(
            label: Text(switch (mode) {
              CatalogMode.all => s.catalogFilterAll,
              CatalogMode.notTasted => s.catalogFilterNotTasted,
              CatalogMode.avoid => s.catalogFilterAvoid,
            }),
            selected: filter.mode == mode,
            onSelected: (_) =>
                ref.read(catalogFilterProvider.notifier).setMode(mode),
          ),
        if (filter.allergen case final allergen?)
          InputChip(
            label: Text(s.catalogAllergenFilter(allergen.label(s))),
            onDeleted: () =>
                ref.read(catalogFilterProvider.notifier).setAllergen(null),
          ),
      ],
    );
  }
}
