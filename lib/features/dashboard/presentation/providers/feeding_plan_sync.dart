import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/baby/domain/entities/feeding_plan_snapshot.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_feeding_plan.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feeding_plan_sync.g.dart';

/// Recalcule le plan biberons et l'écrit dans le foyer pour les Cloud Functions.
abstract interface class FeedingPlanSync {
  Future<void> sync();
}

/// Ne fait rien ; pour les tests.
final class NoopFeedingPlanSync implements FeedingPlanSync {
  const NoopFeedingPlanSync();

  @override
  Future<void> sync() async {}
}

/// Relit les données depuis Firestore (et non depuis les streams, qui peuvent
/// être en retard d'une écriture), calcule, puis écrit `feedingPlan`.
final class FirestoreFeedingPlanSync implements FeedingPlanSync {
  const FirestoreFeedingPlanSync(this._ref);

  final Ref _ref;

  @override
  Future<void> sync() async {
    final code = _ref.read(currentHouseholdCodeProvider);
    if (code == null) return;
    final profile = await _ref.read(babyProfileProvider.future);
    if (profile == null) return;
    final weights = await _ref.read(weightsProvider.future);
    final now = _ref.read(clockProvider).now();
    final events = _ref.read(eventsRepositoryProvider);
    final today = (await events.getBetween(
      code,
      from: now.dateOnly,
      to: now.startOfNextDay,
    )).getOrElse((_) => const []);
    final lastBottle = (await events.getLatestBottle(code))
        .getOrElse((_) => null);
    final plan = const ComputeFeedingPlan()(
      birthDate: profile.birthDate,
      latestWeightGrams: weights.isEmpty ? null : weights.first.grams,
      feedsPerDay: profile.careSettings.feedsPerDay,
      todayBottles: today.where((e) => e.hasBottle).toList(),
      lastBottle: lastBottle,
      now: now,
    );
    await _ref
        .read(babyRepositoryProvider)
        .saveFeedingPlan(
          code,
          FeedingPlanSnapshot(
            nextBottleAt: plan.nextBottleAt,
            suggestedMl: plan.suggestedMl,
            computedAt: now,
          ),
        );
  }
}

@Riverpod(keepAlive: true)
FeedingPlanSync feedingPlanSync(Ref ref) => FirestoreFeedingPlanSync(ref);
