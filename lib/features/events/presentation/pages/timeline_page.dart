import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/features/events/presentation/day_label.dart';
import 'package:colette/features/events/presentation/providers/event_form_controller.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/events/presentation/providers/timeline_sleeps_provider.dart';
import 'package:colette/features/events/presentation/timeline_entry.dart';
import 'package:colette/features/events/presentation/timeline_grouping.dart';
import 'package:colette/features/events/presentation/widgets/day_header_delegate.dart';
import 'package:colette/features/events/presentation/widgets/event_form_sheet.dart';
import 'package:colette/features/events/presentation/widgets/event_tile.dart';
import 'package:colette/features/events/presentation/widgets/timeline_delete_dialog.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_form_controller.dart';
import 'package:colette/features/sleep/presentation/widgets/sleep_form_sheet.dart';
import 'package:colette/features/sleep/presentation/widgets/sleep_tile.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onglet Journal : soins et sommeils groupés par jour, pagination par défilement.
class TimelinePage extends ConsumerWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final events = ref.watch(timelineEventsProvider);
    final sleeps =
        ref.watch(timelineSleepsProvider).value ?? const <SleepSession>[];
    return Scaffold(
      appBar: AppBar(title: Text(s.journalTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showEventFormSheet(context),
        child: const Icon(Icons.add),
      ),
      body: switch (events) {
        AsyncValue(hasValue: true, value: final List<CareEvent> value)
            when value.isEmpty && sleeps.isEmpty =>
          EmptyState(
            icon: Icons.view_timeline_outlined,
            message: s.journalEmpty,
          ),
        AsyncValue(hasValue: true, value: final List<CareEvent> value) =>
          _TimelineList(events: value, sleeps: sleeps),
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
  const _TimelineList({required this.events, required this.sleeps});

  static const _loadMoreThreshold = 300.0;

  final List<CareEvent> events;
  final List<SleepSession> sleeps;

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
    final confirmed = await confirmTimelineDelete(
      context,
      title: s.deleteEventTitle,
    );
    if (confirmed != true) return false;
    final deleted = await ref
        .read(eventFormControllerProvider.notifier)
        .delete(event.id);
    if (!deleted && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.errorUnknown)));
    }
    return deleted;
  }

  Future<bool> _confirmDeleteSleep(
    BuildContext context,
    WidgetRef ref,
    SleepSession session,
  ) async {
    final s = S.of(context);
    final confirmed = await confirmTimelineDelete(
      context,
      title: s.deleteSleepTitle,
    );
    if (confirmed != true) return false;
    final deleted = await ref
        .read(sleepFormControllerProvider.notifier)
        .delete(session.id);
    if (!deleted && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.errorUnknown)));
    }
    return deleted;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final now = ref.watch(clockProvider).now();
    // Garde `eventFormControllerProvider` et `sleepFormControllerProvider`
    // (autoDispose) en vie pendant la suppression déclenchée par un
    // glissement, le temps de l'appel réseau.
    ref.watch(eventFormControllerProvider);
    ref.watch(sleepFormControllerProvider);
    final groups = groupEntriesByDay(mergeTimelineEntries(events, sleeps));
    final lastPageFull = events.length >= ref.watch(timelineLimitProvider);
    final headerBackground = context.appColor(AppColors.pageBackground);
    final headerStyle = Theme.of(context).coletteTextStyles.label
        .copyWith(color: context.appColor(AppColors.textSecondary));
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
                    background: headerBackground,
                    textStyle: headerStyle,
                  ),
                ),
                SliverList.builder(
                  itemCount: group.entries.length,
                  itemBuilder: (context, index) =>
                      switch (group.entries[index]) {
                        CareEntry(:final event) => EventTile(
                          key: ValueKey(event.id),
                          event: event,
                          onTap: () =>
                              showEventFormSheet(context, initial: event),
                          onConfirmDelete: () =>
                              _confirmDelete(context, ref, event),
                        ),
                        SleepEntry(:final session) => SleepTile(
                          key: ValueKey(session.id),
                          session: session,
                          now: now,
                          onTap: () =>
                              showSleepFormSheet(context, initial: session),
                          onConfirmDelete: () =>
                              _confirmDeleteSleep(context, ref, session),
                        ),
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
