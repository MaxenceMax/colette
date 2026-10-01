import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:colette/shared/ui/widgets/care_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Puces des soins du brouillon ; nombril masqué s'il n'est plus suivi.
class EventCareChips extends ConsumerWidget {
  const EventCareChips({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final CareEvent draft;
  final ValueChanged<CareEvent> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final umbilicalEnabled =
        ref
            .watch(babyProfileProvider)
            .value
            ?.careSettings
            .umbilicalCare
            .enabled ??
        true;
    final visibleCares = CareType.values.where(
      (type) =>
          type != CareType.umbilicalCare ||
          umbilicalEnabled ||
          draft.umbilicalCare,
    );
    return Wrap(
      spacing: AppSpacing.sm.value,
      runSpacing: AppSpacing.sm.value,
      children: [
        for (final type in visibleCares)
          CareChip(
            type: type,
            selected: draft.has(type),
            onChanged: (value) => onChanged(draft.toggle(type, value)),
          ),
      ],
    );
  }
}
