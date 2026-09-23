import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/baby_sex.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('whoReference(length) couvre seulement les dates des mesures de taille, à un jour près', () async {
    final profile = BabyProfile(
      name: 'Colette',
      birthDate: DateTime(2026, 9, 1),
      sex: BabySex.male,
    );
    final measurements = [
      GrowthMeasurement(
        id: 'l1',
        measuredAt: DateTime(2026, 9, 2),
        lengthMm: 500,
      ),
      GrowthMeasurement(
        id: 'w',
        measuredAt: DateTime(2026, 9, 20),
        grams: 4200,
      ),
      GrowthMeasurement(
        id: 'l2',
        measuredAt: DateTime(2026, 9, 10),
        lengthMm: 520,
      ),
    ];
    final container = ProviderContainer(
      overrides: [
        babyProfileProvider.overrideWith((ref) => Stream.value(profile)),
        measurementsProvider.overrideWith((ref) => Stream.value(measurements)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(babyProfileProvider, (_, _) {});
    container.listen(measurementsProvider, (_, _) {});
    await container.read(babyProfileProvider.future);
    await container.read(measurementsProvider.future);

    final reference = container.read(whoReferenceProvider(GrowthMetric.length));

    expect(reference.first.ageDays, 0);
    expect(reference.first.date, DateTime(2026, 9, 1));
    expect(reference.last.date, DateTime(2026, 9, 11));
  });

  test('whoReference sans sexe renseigné : liste vide', () async {
    final profile = BabyProfile(
      name: 'Colette',
      birthDate: DateTime(2026, 9, 1),
    );
    final measurements = [
      GrowthMeasurement(
        id: 'l1',
        measuredAt: DateTime(2026, 9, 2),
        lengthMm: 500,
      ),
    ];
    final container = ProviderContainer(
      overrides: [
        babyProfileProvider.overrideWith((ref) => Stream.value(profile)),
        measurementsProvider.overrideWith((ref) => Stream.value(measurements)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(babyProfileProvider, (_, _) {});
    container.listen(measurementsProvider, (_, _) {});
    await container.read(babyProfileProvider.future);
    await container.read(measurementsProvider.future);

    expect(container.read(whoReferenceProvider(GrowthMetric.length)), isEmpty);
  });
}
