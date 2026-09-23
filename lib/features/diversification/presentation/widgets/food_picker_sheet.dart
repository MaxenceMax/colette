import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_filter.dart';
import 'package:colette/features/diversification/domain/use_cases/filter_foods.dart';
import 'package:colette/features/diversification/domain/use_cases/food_name.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_overview_providers.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:colette/features/diversification/presentation/widgets/food_status_badge.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre la liste des aliments ; renvoie l'aliment choisi ou `null`.
Future<Food?> showFoodPickerSheet(BuildContext context) =>
    showModalBottomSheet<Food>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const FoodPickerSheet(),
    );

/// Recherche et choix d'un aliment du catalogue ou perso.
class FoodPickerSheet extends ConsumerStatefulWidget {
  const FoodPickerSheet({super.key});

  @override
  ConsumerState<FoodPickerSheet> createState() => _FoodPickerSheetState();
}

class _FoodPickerSheetState extends ConsumerState<FoodPickerSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final foods = ref.watch(foodsProvider).value ?? const <String, Food>{};
    final statuses = ref.watch(foodStatusesProvider);
    final list =
        [
          for (final section in const FilterFoods()(
            foods: foods.values,
            filter: FoodFilter(query: _query),
            statuses: statuses,
            tastingCounts: const {},
            ageMonths: ref.watch(diversificationTimelineProvider)?.ageMonths,
          ))
            ...section.foods,
        ]..sort(
          (a, b) =>
              normalizeFoodName(a.name).compareTo(normalizeFoodName(b.name)),
        );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        children: [
          Padding(
            padding: AppSpacing.md.all,
            child: TextField(
              controller: _search,
              autofocus: true,
              decoration: InputDecoration(
                hintText: s.catalogSearchHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? EmptyState(icon: Icons.search_off, message: s.catalogEmpty)
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final food = list[index];
                      final status = statuses[food.id];
                      return ListTile(
                        title: Text(food.name),
                        trailing: status == null
                            ? null
                            : FoodStatusBadge(status: status),
                        onTap: () => Navigator.of(context).pop(food),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
