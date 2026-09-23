import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/care_event_factory.dart';
import '../../../helpers/in_memory_household_local_store.dart';

void main() {
  test(
    'sync écrit nextBottleAt = dernier biberon + 3 h et la suggestion',
    () async {
      final db = FakeFirebaseFirestore();
      final now = DateTime(2026, 9, 10, 12);
      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(FixedClock(now)),
          householdLocalStoreProvider.overrideWithValue(
            InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(babyRepositoryProvider)
          .saveProfile(
            'ABCDEFGH',
            BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1)),
          );
      final bottle = makeEvent(
        id: 'b',
        startAt: DateTime(2026, 9, 10, 9),
        bottleMl: 60,
      );
      await container.read(eventsRepositoryProvider).save('ABCDEFGH', bottle);

      await container.read(feedingPlanSyncProvider).sync();

      final data = (await db.collection('households').doc('ABCDEFGH').get())
          .data()!;
      final plan = data['feedingPlan'] as Map<String, dynamic>;
      expect(
        (plan['nextBottleAt'] as Timestamp).toDate(),
        DateTime(2026, 9, 10, 12),
      );
      expect(
        (plan['windowStartAt'] as Timestamp).toDate(),
        DateTime(2026, 9, 10, 11, 30),
      );
      expect(
        (plan['windowEndAt'] as Timestamp).toDate(),
        DateTime(2026, 9, 10, 14),
      );
      expect(plan['suggestedMl'], 60);
    },
  );

  test('sync utilise la cible ajustée du profil pour la suggestion', () async {
    final db = FakeFirebaseFirestore();
    final now = DateTime(2026, 9, 10, 12);
    final container = ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(FixedClock(now)),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(babyRepositoryProvider)
        .saveProfile(
          'ABCDEFGH',
          BabyProfile(
            name: 'Colette',
            birthDate: DateTime(2026, 9, 1),
            careSettings: const CareSettings(dailyTargetMl: 600),
          ),
        );
    final bottle = makeEvent(
      id: 'b',
      startAt: DateTime(2026, 9, 10, 9),
      bottleMl: 60,
    );
    await container.read(eventsRepositoryProvider).save('ABCDEFGH', bottle);

    await container.read(feedingPlanSyncProvider).sync();

    final data = (await db.collection('households').doc('ABCDEFGH').get())
        .data()!;
    final plan = data['feedingPlan'] as Map<String, dynamic>;
    // Sans pesée la cible OMS serait 480 (suggestion 60) ; avec 600 : (600 − 60) / 7 → 80.
    expect(plan['suggestedMl'], 80);
  });

  test(
    'sync utilise la dernière pesée, pas une mesure de taille plus récente',
    () async {
      final db = FakeFirebaseFirestore();
      final now = DateTime(2026, 9, 10, 12);
      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(FixedClock(now)),
          householdLocalStoreProvider.overrideWithValue(
            InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
          ),
        ],
      );
      addTearDown(container.dispose);
      final repo = container.read(babyRepositoryProvider);
      await repo.saveProfile(
        'ABCDEFGH',
        BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1)),
      );
      await repo.saveMeasurement(
        'ABCDEFGH',
        GrowthMeasurement(
          id: 'w',
          measuredAt: DateTime(2026, 9, 9),
          grams: 4200,
        ),
      );
      await repo.saveMeasurement(
        'ABCDEFGH',
        GrowthMeasurement(
          id: 'l',
          measuredAt: DateTime(2026, 9, 10),
          lengthMm: 530,
        ),
      );

      await container.read(feedingPlanSyncProvider).sync();

      final data = (await db.collection('households').doc('ABCDEFGH').get())
          .data()!;
      final plan = data['feedingPlan'] as Map<String, dynamic>;
      // Jour de vie 10 : 150 ml/kg × 4,2 kg = 630 ml, 8 biberons → 80 ml.
      // Sans pesée, la table par âge donnerait 480 / 8 = 60 ml.
      expect(plan['suggestedMl'], 80);
    },
  );

  test('sync n\'échoue pas sans profil', () async {
    final container = ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
        clockProvider.overrideWithValue(FixedClock(DateTime(2026, 9, 10, 12))),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    addTearDown(container.dispose);
    await expectLater(
      container.read(feedingPlanSyncProvider).sync(),
      completes,
    );
  });
}
