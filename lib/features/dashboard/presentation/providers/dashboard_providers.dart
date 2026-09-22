import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/dashboard/domain/entities/baby_age.dart';
import 'package:colette/features/dashboard/domain/entities/care_task.dart';
import 'package:colette/features/dashboard/domain/entities/feeding_plan.dart';
import 'package:colette/features/dashboard/domain/entities/feeding_reference.dart';
import 'package:colette/features/dashboard/domain/entities/rolling_intake.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_baby_age.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_daily_care_status.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_feeding_plan.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_feeding_reference.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_rolling_intake.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_providers.g.dart';

/// Compteurs du jour.
typedef DayCounters = ({int diapers, int pee, int poop});

/// Plan biberons du jour ; `null` sans profil.
@riverpod
FeedingPlan? feedingPlan(Ref ref) {
  final profile = ref.watch(babyProfileProvider).value;
  if (profile == null) return null;
  final today = ref.watch(todayEventsProvider).value ?? const [];
  return const ComputeFeedingPlan()(
    birthDate: profile.birthDate,
    latestWeightGrams: ref.watch(latestWeightProvider)?.grams,
    feedsPerDay: profile.careSettings.feedsPerDay,
    todayBottles: today.where((e) => e.hasBottle).toList(),
    lastBottle: ref.watch(latestBottleProvider).value,
    now: ref.watch(currentMinuteProvider),
    dailyTargetMlOverride: profile.careSettings.dailyTargetMl,
  );
}

/// Repères OMS du jour ; `null` sans profil.
@riverpod
FeedingReference? feedingReference(Ref ref) {
  final profile = ref.watch(babyProfileProvider).value;
  if (profile == null) return null;
  return const ComputeFeedingReference()(
    birthDate: profile.birthDate,
    latestWeightGrams: ref.watch(latestWeightProvider)?.grams,
    now: ref.watch(currentMinuteProvider),
  );
}

/// Biberons des dernières 24 h glissantes.
@riverpod
RollingIntake rollingIntake(Ref ref) => const ComputeRollingIntake()(
  events: ref.watch(recentEventsProvider).value ?? const [],
  now: ref.watch(currentMinuteProvider),
);

/// Soins attendus aujourd'hui.
@riverpod
List<CareTask> dailyCareTasks(Ref ref) {
  final profile = ref.watch(babyProfileProvider).value;
  if (profile == null) return const [];
  return const ComputeDailyCareStatus()(
    settings: profile.careSettings,
    todayEvents: ref.watch(todayEventsProvider).value ?? const [],
    lastBath: ref.watch(latestBathProvider).value,
    now: ref.watch(currentMinuteProvider),
  );
}

@riverpod
DayCounters dayCounters(Ref ref) {
  final events = ref.watch(todayEventsProvider).value ?? const [];
  return (
    diapers: events.where((e) => e.diaperChange).length,
    pee: events.where((e) => e.pee).length,
    poop: events.where((e) => e.poop).length,
  );
}

/// Âge du bébé ; `null` sans profil.
@riverpod
BabyAge? babyAge(Ref ref) {
  final profile = ref.watch(babyProfileProvider).value;
  if (profile == null) return null;
  return const ComputeBabyAge()(
    birthDate: profile.birthDate,
    now: ref.watch(currentMinuteProvider),
  );
}
