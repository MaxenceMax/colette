import 'dart:async';

import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'baby_settings_controller.g.dart';

/// Actions de l'onglet Réglages sur le profil, les pesées et les soins attendus.
@riverpod
class BabySettingsController extends _$BabySettingsController {
  static const minWeightGrams = 1000;
  static const maxWeightGrams = 20000;

  @override
  FutureOr<void> build() {}

  Future<bool> saveProfile(BabyProfile profile) => _run(
    (code) => ref.read(babyRepositoryProvider).saveProfile(code, profile),
  );

  Future<bool> updateCareSettings(BabyProfile profile, CareSettings settings) =>
      saveProfile(profile.copyWith(careSettings: settings));

  /// Renseigner la date désactive le soin du nombril ; l'effacer le réactive.
  Future<bool> setCordFallenAt(BabyProfile profile, DateTime? date) =>
      saveProfile(
        profile.copyWith(
          cordFallenAt: date,
          careSettings: profile.careSettings.copyWith(
            umbilicalCareEnabled: date == null,
          ),
        ),
      );

  Future<bool> addWeight({required DateTime measuredAt, required int grams}) =>
      _run((code) async {
        if (grams < minWeightGrams || grams > maxWeightGrams) {
          return left(const ValidationFailure(ValidationReason.invalidWeight));
        }
        final entry = WeightEntry(
          id: ref.read(idGeneratorProvider).newId(),
          measuredAt: measuredAt,
          grams: grams,
        );
        return ref.read(babyRepositoryProvider).addWeight(code, entry);
      });

  Future<bool> deleteWeight(String weightId) => _run(
    (code) => ref.read(babyRepositoryProvider).deleteWeight(code, weightId),
  );

  Future<bool> _run(
    Future<Either<Failure, void>> Function(String code) action,
  ) async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return false;
    state = const AsyncLoading();
    final result = await action(code);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    if (result.isRight()) await ref.read(feedingPlanSyncProvider).sync();
    return result.isRight();
  }
}
