import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/result/no_retry.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/sleep/data/repositories/firestore_sleep_repository.dart';
import 'package:colette/features/sleep/domain/entities/sleep_age_band.dart';
import 'package:colette/features/sleep/domain/entities/sleep_day.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:colette/features/sleep/domain/entities/sleep_status.dart';
import 'package:colette/features/sleep/domain/repositories/sleep_repository.dart';
import 'package:colette/features/sleep/domain/use_cases/compute_sleep_days.dart';
import 'package:colette/features/sleep/domain/use_cases/compute_sleep_summary.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sleep_providers.g.dart';

/// Dépôt des sommeils du foyer.
@riverpod
SleepRepository sleepRepository(Ref ref) =>
    FirestoreSleepRepository(ref.watch(firestoreProvider));

/// Sommeils commencés depuis minuit il y a deux jours (couvre les 24 h
/// glissantes, un sommeil durant au plus 24 h). Borne stable sur la journée.
@Riverpod(retry: noRetry)
Stream<List<SleepSession>> recentSleeps(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(const []);
  final today = ref.watch(todayProvider);
  return ref
      .watch(sleepRepositoryProvider)
      .watchStartedSince(
        code,
        DateTime(today.year, today.month, today.day - 2),
      );
}

/// Dernier sommeil, toutes dates confondues.
@Riverpod(retry: noRetry)
Stream<SleepSession?> latestSleep(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(null);
  return ref.watch(sleepRepositoryProvider).watchLatest(code);
}

/// État actuel et total sur 24 h ; `null` tant que les flux chargent.
@riverpod
SleepSummary? sleepSummary(Ref ref) {
  final recent = ref.watch(recentSleepsProvider);
  final latest = ref.watch(latestSleepProvider);
  if (!recent.hasValue || !latest.hasValue) return null;
  return computeSleepSummary(
    recent: recent.requireValue,
    latest: latest.requireValue,
    now: ref.watch(currentMinuteProvider),
  );
}

/// Repère OMS selon l'âge ; `null` sans profil ou à partir de 2 ans.
@riverpod
SleepAgeBand? sleepAgeBand(Ref ref) {
  final profile = ref.watch(babyProfileProvider).value;
  if (profile == null) return null;
  return SleepAgeBand.forAge(
    birthDate: profile.birthDate,
    now: ref.watch(todayProvider),
  );
}

/// Sommeils commencés depuis J−7 (la veille du premier jour affiché couvre les
/// nuits qui débordent sur J−6).
@Riverpod(retry: noRetry)
Stream<List<SleepSession>> weekSleeps(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(const []);
  final today = ref.watch(todayProvider);
  return ref
      .watch(sleepRepositoryProvider)
      .watchStartedSince(
        code,
        DateTime(today.year, today.month, today.day - sleepWeekDayCount),
      );
}

/// Les 7 jours de la page Sommeil ; `null` tant que le flux charge.
@riverpod
List<SleepDay>? sleepWeek(Ref ref) {
  final sleeps = ref.watch(weekSleepsProvider).value;
  if (sleeps == null) return null;
  return computeSleepDays(
    sleeps,
    today: ref.watch(todayProvider),
    now: ref.watch(currentMinuteProvider),
  );
}
