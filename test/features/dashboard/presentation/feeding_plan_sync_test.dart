import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
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
      // Garde les providers stream vivants : `sync()` les lit via `.future`
      // sans les `watch`er, et une lecture ponctuelle laisserait le provider
      // `autoDispose` se détruire avant que le flux Firestore n'ait émis,
      // ce qui romprait le `Future` avec une erreur d'état.
      container.listen(babyProfileProvider, (_, _) {});
      container.listen(weightsProvider, (_, _) {});
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
      expect(plan['suggestedMl'], 60);
    },
  );
}
