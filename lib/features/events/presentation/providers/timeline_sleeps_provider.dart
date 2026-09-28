import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/result/no_retry.dart';
import 'package:colette/features/events/domain/entities/timeline_filter.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/events/presentation/providers/timeline_filter_controller.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'timeline_sleeps_provider.g.dart';

/// Sommeils du Journal : un seul provider (pas de famille par `from`) pour
/// que Riverpod garde la liste précédente pendant le rechargement au lieu de
/// démarrer un nouveau flux vide à chaque élargissement de la fenêtre.
/// `from` suit le plus ancien soin déjà chargé par [timelineEventsProvider],
/// sinon J−7 à minuit. Avec [SleepFilter], les sommeils sont paginés seuls
/// par [TimelineLimit] ; avec un filtre de soin, la liste est vide.
@Riverpod(retry: noRetry)
Stream<List<SleepSession>> timelineSleeps(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(const []);
  final filter = ref.watch(timelineFilterControllerProvider);
  if (!filter.showsSleeps) return Stream.value(const []);
  if (filter is SleepFilter) {
    final limit = ref.watch(timelineLimitProvider);
    return ref
        .watch(sleepRepositoryProvider)
        .watchLatestSessions(code, limit: limit);
  }
  final oldestLoadedDay = ref.watch(
    timelineEventsProvider.select((events) {
      final loaded = events.value;
      return switch (loaded) {
        final list? when list.isNotEmpty => list.last.startAt.dateOnly,
        _ => null,
      };
    }),
  );
  final today = ref.watch(todayProvider);
  final from =
      oldestLoadedDay ?? DateTime(today.year, today.month, today.day - 7);
  return ref.watch(sleepRepositoryProvider).watchStartedSince(code, from);
}
