import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/widgets/dated_appointment_tile.dart';
import 'package:colette/features/health/presentation/widgets/timeline_item_ui.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';

/// Section « Aussi programmés » : les RDV programmés après le premier
/// (déjà en carte « Prochain rendez-vous »). Rien s'il y en a moins de deux.
class ScheduledSection extends StatelessWidget {
  const ScheduledSection({super.key, required this.items});

  /// RDV programmés, du plus proche au plus lointain.
  final List<MedicalTimelineItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.length < 2) return const SizedBox.shrink();
    final rest = items.skip(1);
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionHeader(title: S.of(context).healthSectionScheduled),
        ColetteCardSurface(
          padding: AppSpacing.xs.all,
          child: Column(
            children: [
              for (final item in rest)
                if (item.appointmentAt case final at?)
                  DatedAppointmentTile(
                    item: item,
                    appointmentAt: at,
                    onTap: () => showTimelineItemSheet(context, item),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
