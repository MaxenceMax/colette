import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/result/no_retry.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/health/data/native_calendar_repository.dart';
import 'package:colette/features/health/data/repositories/firestore_medical_repository.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/repositories/calendar_repository.dart';
import 'package:colette/features/health/domain/repositories/medical_repository.dart';
import 'package:colette/features/health/domain/use_cases/compute_medical_timeline.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'health_providers.g.dart';

/// Sans état : `keepAlive` car lu par `healthSyncProvider` (keepAlive).
@Riverpod(keepAlive: true)
MedicalRepository medicalRepository(Ref ref) =>
    FirestoreMedicalRepository(ref.watch(firestoreProvider));

/// Pont Swift du Calendrier iOS.
@Riverpod(keepAlive: true)
CalendarRepository calendarRepository(Ref ref) =>
    const NativeCalendarRepository(
      MethodChannel(NativeCalendarRepository.channelName),
    );

/// Visites médicales du foyer courant.
@Riverpod(retry: noRetry)
Stream<List<MedicalVisit>> medicalVisits(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(const []);
  return ref.watch(medicalRepositoryProvider).watchVisits(code);
}

/// Frise du suivi médical ; `null` sans profil ou tant que les visites ne
/// sont pas lues (sinon « En retard » s'afficherait un instant au démarrage).
@riverpod
MedicalTimeline? medicalTimeline(Ref ref) {
  final profile = ref.watch(babyProfileProvider).value;
  if (profile == null) return null;
  final visits = switch (ref.watch(medicalVisitsProvider)) {
    AsyncData(:final value) => value,
    _ => null,
  };
  if (visits == null) return null;
  return const ComputeMedicalTimeline()(
    birthDate: profile.birthDate,
    visits: visits,
    now: ref.watch(currentMinuteProvider),
  );
}
