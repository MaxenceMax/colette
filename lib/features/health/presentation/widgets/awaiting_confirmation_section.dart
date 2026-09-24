import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/widgets/timeline_item_ui.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';

/// Section « RDV passé, à confirmer » : visites dont le RDV est passé sans
/// être marquées faites, dans une carte à bordure `warning`. Rien si vide.
class AwaitingConfirmationSection extends StatelessWidget {
  const AwaitingConfirmationSection({super.key, required this.items});

  final List<MedicalTimelineItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionHeader(title: S.of(context).healthSectionAwaiting),
        ColetteCardSurface(
          padding: AppSpacing.xs.all,
          borderColor: AppColors.warning,
          child: Column(
            children: [for (final item in items) TimelineItemTile(item: item)],
          ),
        ),
      ],
    );
  }
}
