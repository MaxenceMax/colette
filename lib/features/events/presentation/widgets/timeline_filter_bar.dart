import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/events/domain/entities/timeline_filter.dart';
import 'package:colette/features/events/presentation/providers/timeline_filter_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:colette/shared/ui/care_type_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rangée de puces du Journal : un seul filtre actif à la fois.
class TimelineFilterBar extends ConsumerWidget {
  const TimelineFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(timelineFilterControllerProvider);
    return SingleChildScrollView(
      scrollDirection: .horizontal,
      padding: AppSpacing.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        spacing: AppSpacing.sm.value,
        children: [
          for (final filter in TimelineFilter.values)
            _FilterChip(
              filter: filter,
              selected: filter == selected,
              onSelected: () => ref
                  .read(timelineFilterControllerProvider.notifier)
                  .select(filter),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.filter,
    required this.selected,
    required this.onSelected,
  });

  final TimelineFilter filter;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final (label, icon, color) = switch (filter) {
      AllEntriesFilter() => (s.journalFilterAll, null, null),
      CareTypeFilter(:final type) => (type.label(s), type.icon, type.color),
      BottleFilter() => (
        s.careBottle,
        Icons.local_drink_outlined,
        CareCategory.feeding.color,
      ),
      SleepFilter() => (
        s.sleepCardTitle,
        Icons.bedtime_outlined,
        AppColors.sleepNight,
      ),
    };
    return ChoiceChip(
      avatar: icon == null
          ? null
          : Icon(
              icon,
              color: context.appColor(color ?? AppColors.textSecondary),
            ),
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onSelected(),
    );
  }
}
