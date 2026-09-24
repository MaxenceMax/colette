import 'dart:async';

import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/domain/use_cases/validate_growth_measurement.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'baby_settings_controller.g.dart';

/// Actions de l'onglet Réglages sur le profil, les mesures de croissance et les soins attendus.
@riverpod
class BabySettingsController extends _$BabySettingsController {
  @override
  FutureOr<void> build() {}

  Future<bool> saveProfile(BabyProfile profile) => _run(
    (code) => ref.read(babyRepositoryProvider).saveProfile(code, profile),
  );

  Future<bool> updateCareSettings(BabyProfile profile, CareSettings settings) =>
      saveProfile(profile.copyWith(careSettings: settings));

  /// Renseigner la date coupe le suivi du nombril ; l'effacer le rallume. La fréquence est conservée.
  Future<bool> setCordFallenAt(BabyProfile profile, DateTime? date) {
    final umbilicalCare = profile.careSettings.umbilicalCare;
    return saveProfile(
      profile.copyWith(
        cordFallenAt: date,
        careSettings: profile.careSettings.copyWith(
          umbilicalCare: umbilicalCare.copyWith(enabled: date == null),
        ),
      ),
    );
  }

  /// Crée ([id] nul) ou remplace une mesure après validation, puis resynchronise le plan.
  Future<bool> saveMeasurement({
    String? id,
    required DateTime measuredAt,
    int? grams,
    int? lengthMm,
    int? headCircumferenceMm,
  }) => _run((code) {
    final measurement = GrowthMeasurement(
      id: id ?? ref.read(idGeneratorProvider).newId(),
      measuredAt: measuredAt,
      grams: grams,
      lengthMm: lengthMm,
      headCircumferenceMm: headCircumferenceMm,
    );
    return const ValidateGrowthMeasurement()(measurement)
        .fold<Future<Either<Failure, void>>>(
          (failure) async => left(failure),
          (valid) =>
              ref.read(babyRepositoryProvider).saveMeasurement(code, valid),
        );
  });

  /// Supprime une mesure puis resynchronise le plan.
  Future<bool> deleteMeasurement(String measurementId) => _run(
    (code) =>
        ref.read(babyRepositoryProvider).deleteMeasurement(code, measurementId),
  );

  Future<bool> _run(
    Future<Either<Failure, void>> Function(String code) action,
  ) async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return false;
    // Lu avant l'await : le contrôleur autoDispose peut être détruit pendant l'écriture
    // (feuille refermée), la sync du plan doit quand même partir.
    final sync = ref.read(feedingPlanSyncProvider);
    state = const AsyncLoading();
    final result = await action(code);
    if (ref.mounted) {
      state = result.fold(
        (failure) => AsyncError(failure, StackTrace.current),
        (_) => const AsyncData(null),
      );
    }
    if (result.isRight()) await sync.sync();
    return result.isRight();
  }
}
