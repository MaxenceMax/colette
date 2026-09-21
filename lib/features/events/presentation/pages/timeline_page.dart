import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/features/events/presentation/day_label.dart';
import 'package:colette/features/events/presentation/providers/event_form_controller.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/events/presentation/timeline_grouping.dart';
import 'package:colette/features/events/presentation/widgets/day_header_delegate.dart';
import 'package:colette/features/events/presentation/widgets/event_form_sheet.dart';
import 'package:colette/features/events/presentation/widgets/event_tile.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onglet Journal : événements groupés par jour, pagination par défilement.
class TimelinePage extends ConsumerWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final events = ref.watch(timelineEventsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.journalTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showEventFormSheet(context),
        child: const Icon(Icons.add),
      ),
      body: switch (events) {
        AsyncData(:final value) when value.isEmpty => EmptyState(
          icon: Icons.view_timeline_outlined,
          message: s.journalEmpty,
        ),
        AsyncData(:final value) => _TimelineList(events: value),
        AsyncError() => EmptyState(
          icon: Icons.error_outline,
          message: s.errorUnknown,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _TimelineList extends ConsumerWidget {
  const _TimelineList({required this.events});

  static const _loadMoreThreshold = 300.0;

  final List<CareEvent> events;

  bool _onScroll(WidgetRef ref, ScrollNotification notification) {
    final lastPageFull = events.length >= ref.read(timelineLimitProvider);
    if (lastPageFull && notification.metrics.extentAfter < _loadMoreThreshold) {
      ref.read(timelineLimitProvider.notifier).loadMore();
    }
    return false;
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CareEvent event,
  ) async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.deleteEventTitle),
        content: Text(s.deleteEventBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    return ref.read(eventFormControllerProvider.notifier).delete(event.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final now = ref.watch(clockProvider).now();
    final groups = groupEventsByDay(events);
    final lastPageFull = events.length >= ref.watch(timelineLimitProvider);
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) => _onScroll(ref, notification),
      child: CustomScrollView(
        slivers: [
          for (final group in groups)
            SliverMainAxisGroup(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: DayHeaderDelegate(
                    dayLabel(group.day, now: now, s: s),
                  ),
                ),
                SliverList.builder(
                  itemCount: group.events.length,
                  itemBuilder: (context, index) {
                    final event = group.events[index];
                    return EventTile(
                      event: event,
                      onTap: () => showEventFormSheet(context, initial: event),
                      onConfirmDelete: () =>
                          _confirmDelete(context, ref, event),
                    );
                  },
                ),
              ],
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.lg.all,
              child: lastPageFull
                  ? const Center(child: CircularProgressIndicator())
                  : AppSpacing.xxl.verticalSpace,
            ),
          ),
        ],
      ),
    );
  }
}
