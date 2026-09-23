import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/dashboard/domain/entities/feeding_age_band.dart';
import 'package:colette/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_household_local_store.dart';

void main() {
  final now = DateTime(2026, 9, 10, 12);

  List<Override> baseOverrides({
    required BabyProfile? profile,
    List<GrowthMeasurement> measurements = const [],
  }) => [
    clockProvider.overrideWithValue(FixedClock(now)),
    minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
    householdLocalStoreProvider.overrideWithValue(
      InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
    ),
    babyProfileProvider.overrideWith((ref) => Stream.value(profile)),
    measurementsProvider.overrideWith((ref) => Stream.value(measurements)),
    todayEventsProvider.overrideWith((ref) => const Stream.empty()),
    recentEventsProvider.overrideWith((ref) => const Stream.empty()),
    latestBottleProvider.overrideWith((ref) => Stream.value(null)),
    latestBathProvider.overrideWith((ref) => Stream.value(null)),
  ];

  test('feedingPlan honore la cible ajustée du profil', () async {
    final profile = BabyProfile(
      name: 'Colette',
      birthDate: DateTime(2026, 9, 1),
      careSettings: const CareSettings(dailyTargetMl: 600),
    );
    final container = ProviderContainer(
      overrides: baseOverrides(
        profile: profile,
        measurements: [
          GrowthMeasurement(
            id: 'w',
            measuredAt: DateTime(2026, 9, 9),
            grams: 3600,
          ),
        ],
      ),
    );
    addTearDown(container.dispose);
    container.listen(babyProfileProvider, (_, _) {});
    container.listen(measurementsProvider, (_, _) {});

    await container.read(babyProfileProvider.future);
    await container.read(measurementsProvider.future);

    final plan = container.read(feedingPlanProvider);

    expect(plan!.dailyTargetMl, 600);
    expect(plan.omsTargetMl, 540);
    expect(plan.isTargetOverridden, isTrue);
  });

  test('feedingReference est null sans profil', () async {
    final container = ProviderContainer(
      overrides: baseOverrides(profile: null),
    );
    addTearDown(container.dispose);
    container.listen(babyProfileProvider, (_, _) {});

    await container.read(babyProfileProvider.future);

    expect(container.read(feedingReferenceProvider), isNull);
  });

  test('feedingReference reflète le jour de vie et la pesée', () async {
    final profile = BabyProfile(
      name: 'Colette',
      birthDate: DateTime(2026, 9, 1),
    );
    final container = ProviderContainer(
      overrides: baseOverrides(
        profile: profile,
        measurements: [
          GrowthMeasurement(
            id: 'w',
            measuredAt: DateTime(2026, 9, 9),
            grams: 4200,
          ),
        ],
      ),
    );
    addTearDown(container.dispose);
    container.listen(babyProfileProvider, (_, _) {});
    container.listen(measurementsProvider, (_, _) {});

    await container.read(babyProfileProvider.future);
    await container.read(measurementsProvider.future);

    final reference = container.read(feedingReferenceProvider);

    expect(reference!.dayOfLife, 10);
    expect(reference.ageBand, FeedingAgeBand.day6ToMonth1);
    expect(reference.mlPerKg, 150);
    expect(reference.weightGrams, 4200);
    expect(reference.weightTargetMl, 630);
  });

  test('latestWeight ignore une mesure plus récente sans poids', () async {
    final container = ProviderContainer(
      overrides: baseOverrides(
        profile: BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1)),
        measurements: [
          GrowthMeasurement(
            id: 'l',
            measuredAt: DateTime(2026, 9, 10),
            lengthMm: 530,
          ),
          GrowthMeasurement(
            id: 'w',
            measuredAt: DateTime(2026, 9, 9),
            grams: 4200,
          ),
        ],
      ),
    );
    addTearDown(container.dispose);
    container.listen(babyProfileProvider, (_, _) {});
    container.listen(measurementsProvider, (_, _) {});
    await container.read(babyProfileProvider.future);
    await container.read(measurementsProvider.future);

    expect(container.read(latestWeightProvider)?.id, 'w');
    expect(container.read(feedingReferenceProvider)!.weightGrams, 4200);
  });
}
