import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/domain/entities/food_catalog.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:colette/features/diversification/presentation/widgets/guide_item_tile.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre les repères de [phase].
Future<void> showAgeGuideSheet(
  BuildContext context, {
  required DiversificationPhase phase,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => AgeGuideSheet(phase: phase),
);

/// Repas et textures de la phase, signes, sécurité, sources et avertissement.
class AgeGuideSheet extends ConsumerWidget {
  const AgeGuideSheet({super.key, required this.phase});

  final DiversificationPhase phase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(foodCatalogProvider).value;
    if (catalog == null) return const SizedBox.shrink();
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    final guide = catalog.guide;
    return ListView(
      padding: AppSpacing.lg.all,
      children: [
        Text(s.guideTitle, style: styles.heading2),
        _GuideSection(
          title: s.guideMealsFor(phase.label(s)),
          items: guide.phases[phase]?.items ?? const [],
        ),
        _GuideSection(title: s.guideReadiness, items: guide.readinessSigns),
        _GuideSection(title: s.guideHunger, items: guide.hungerSigns),
        _GuideSection(title: s.guideSatiety, items: guide.satietySigns),
        _GuideSection(title: s.guideSafety, items: guide.safety),
        SectionHeader(title: s.guideSources),
        for (final source in catalog.sources.values)
          Padding(
            padding: AppSpacing.xs.vertical,
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(source.label, style: styles.body),
                SelectableText(
                  source.url,
                  style: styles.small.copyWith(color: secondary),
                ),
              ],
            ),
          ),
        AppSpacing.sm.verticalSpace,
        Text(
          s.guideReviewedAt(formatShortDate(catalog.reviewedAt)),
          style: styles.small.copyWith(color: secondary),
        ),
        AppSpacing.md.verticalSpace,
        Text(s.guideDisclaimer, style: styles.label),
      ],
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({required this.title, required this.items});

  final String title;
  final List<GuideItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: .start,
      children: [
        SectionHeader(title: title),
        for (final item in items) GuideItemTile(item: item),
      ],
    );
  }
}
