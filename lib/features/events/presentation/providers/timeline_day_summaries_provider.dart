import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/result/no_retry.dart';
import 'package:colette/features/events/domain/entities/care_day_summary.dart';
import 'package:colette/features/events/domain/use_cases/summarize_care_days.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/events/presentation/providers/timeline_sleeps_provider.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'timeline_day_summaries_provider.g.dart';

/// Bilan de chaque jour affiché par le Journal, sur la journée entière :
/// ignore le filtre et la coupure de pagination. `from` suit le plus ancien
/// soin ou sommeil chargé, sinon aujourd'hui à minuit. Un seul provider,
/// comme [timelineSleepsProvider], pour garder le bilan précédent pendant le
/// rechargement.
@Riverpod(retry: noRetry)
Stream<Map<DateTime, CareDaySummary>> timelineDaySummaries(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(const {});
  final oldestCareDay = ref.watch(
    timelineEventsProvider.select(
      (events) => switch (events.value) {
        final list? when list.isNotEmpty => list.last.startAt.dateOnly,
        _ => null,
      },
    ),
  );
  final oldestSleepDay = ref.watch(
    timelineSleepsProvider.select(
      (sleeps) => switch (sleeps.value) {
        final list? when list.isNotEmpty => list.last.startAt.dateOnly,
        _ => null,
      },
    ),
  );
  final today = ref.watch(todayProvider);
  final from = [
    today,
    ?oldestCareDay,
    ?oldestSleepDay,
  ].reduce((a, b) => a.isBefore(b) ? a : b);
  return ref
      .watch(eventsRepositoryProvider)
      .watchBetween(code, from: from, to: today.startOfNextDay)
      .map(summarizeCareDays);
}
