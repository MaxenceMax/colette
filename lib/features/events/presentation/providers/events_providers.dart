import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/events/data/repositories/firestore_events_repository.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/features/events/domain/repositories/events_repository.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'events_providers.g.dart';

/// Taille d'une page du journal.
const timelinePageSize = 30;

/// Sans état : `keepAlive` car consommé par `feedingPlanSyncProvider` (keepAlive).
@Riverpod(keepAlive: true)
EventsRepository eventsRepository(Ref ref) =>
    FirestoreEventsRepository(ref.watch(firestoreProvider));

/// Événements du jour civil courant, du plus récent au plus ancien.
@riverpod
Stream<List<CareEvent>> todayEvents(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(const []);
  final today = ref.watch(todayProvider);
  return ref
      .watch(eventsRepositoryProvider)
      .watchBetween(code, from: today, to: today.startOfNextDay);
}

/// Événements d'hier et d'aujourd'hui (couvre toujours les 24 h glissantes).
@riverpod
Stream<List<CareEvent>> recentEvents(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(const []);
  final today = ref.watch(todayProvider);
  return ref
      .watch(eventsRepositoryProvider)
      .watchBetween(
        code,
        from: today.startOfPreviousDay,
        to: today.startOfNextDay,
      );
}

/// Dernier bain enregistré, toutes dates confondues.
@riverpod
Stream<CareEvent?> latestBath(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(null);
  return ref.watch(eventsRepositoryProvider).watchLatestBath(code);
}

/// Dernier biberon enregistré, toutes dates confondues.
@riverpod
Stream<CareEvent?> latestBottle(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(null);
  return ref.watch(eventsRepositoryProvider).watchLatestBottle(code);
}

/// Nombre d'événements demandés au journal ; grandit par pages.
@riverpod
class TimelineLimit extends _$TimelineLimit {
  @override
  int build() => timelinePageSize;

  void loadMore() => state += timelinePageSize;
}

/// Événements du journal, limités par [TimelineLimit].
@riverpod
Stream<List<CareEvent>> timelineEvents(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(const []);
  final limit = ref.watch(timelineLimitProvider);
  return ref.watch(eventsRepositoryProvider).watchLatest(code, limit: limit);
}
