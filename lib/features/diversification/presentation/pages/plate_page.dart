import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/presentation/providers/catalog_filter.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_overview_providers.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:colette/features/diversification/presentation/widgets/allergens_card.dart';
import 'package:colette/features/diversification/presentation/widgets/catalog_filter_chips.dart';
import 'package:colette/features/diversification/presentation/widgets/catalog_search_bar.dart';
import 'package:colette/features/diversification/presentation/widgets/custom_food_sheet.dart';
import 'package:colette/features/diversification/presentation/widgets/food_catalog_sliver.dart';
import 'package:colette/features/diversification/presentation/widgets/phase_header.dart';
import 'package:colette/features/diversification/presentation/widgets/preparation_card.dart';
import 'package:colette/features/diversification/presentation/widgets/retry_card.dart';
import 'package:colette/features/diversification/presentation/widgets/today_diversity_card.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onglet Assiette : phase, diversité du jour ou préparation, allergènes,
/// aliments à reproposer et catalogue.
class PlatePage extends ConsumerStatefulWidget {
  const PlatePage({super.key});

  @override
  ConsumerState<PlatePage> createState() => _PlatePageState();
}

class _PlatePageState extends ConsumerState<PlatePage> {
  final _catalogKey = GlobalKey();

  void _filterByAllergen(Allergen allergen) {
    ref.read(catalogFilterProvider.notifier).setAllergen(allergen);
    final target = _catalogKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(target, duration: AppDuration.normal.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final catalog = ref.watch(foodCatalogProvider);
    final timeline = ref.watch(diversificationTimelineProvider);
    final foods = ref.watch(foodsProvider).value ?? const {};
    final tastedCount = ref
        .watch(tastingCountsProvider)
        .keys
        .where(foods.containsKey)
        .length;
    return Scaffold(
      body: SafeArea(
        child: switch (catalog) {
          AsyncData() => CustomScrollView(
            slivers: [
              SliverPadding(
                padding: AppSpacing.md.all,
                sliver: SliverList.list(
                  children: [
                    const PhaseHeader(),
                    AppSpacing.md.verticalSpace,
                    if (timeline != null &&
                        timeline.phase == DiversificationPhase.preparation)
                      PreparationCard(timeline: timeline)
                    else
                      const TodayDiversityCard(),
                    AppSpacing.md.verticalSpace,
                    AllergensCard(onAllergenTap: _filterByAllergen),
                    const RetryCard(),
                    SectionHeader(
                      key: _catalogKey,
                      title: s.catalogTitle(tastedCount),
                      trailing: TextButton.icon(
                        onPressed: () => showCustomFoodSheet(context),
                        icon: const Icon(Icons.add),
                        label: Text(s.catalogAddFood),
                      ),
                    ),
                    const CatalogSearchBar(),
                    AppSpacing.sm.verticalSpace,
                    const CatalogFilterChips(),
                  ],
                ),
              ),
              SliverPadding(
                padding: AppSpacing.md.horizontal,
                sliver: const FoodCatalogSliver(),
              ),
              SliverToBoxAdapter(child: AppSpacing.xl.verticalSpace),
            ],
          ),
          AsyncError(:final error) => EmptyState(
            icon: Icons.error_outline,
            message: failureMessage(error, s),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}
