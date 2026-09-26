import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/widgets/dated_appointment_tile.dart';
import 'package:colette/features/health/presentation/widgets/timeline_item_ui.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';

/// Section « Rendez-vous programmés » : tous les RDV programmés, du plus
/// proche au plus lointain. Rien s'il y en a moins de deux (la carte
/// « Prochain rendez-vous » suffit).
class ScheduledSection extends StatelessWidget {
  const ScheduledSection({super.key, required this.items});

  /// RDV programmés, du plus proche au plus lointain.
  final List<MedicalTimelineItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.length < 2) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionHeader(title: S.of(context).healthSectionScheduled),
        ColetteCardSurface(
          padding: AppSpacing.xs.all,
          child: Column(
            children: [
              for (final item in items)
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
