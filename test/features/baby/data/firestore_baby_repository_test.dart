import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/baby/data/repositories/firestore_baby_repository.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/domain/entities/feeding_plan_snapshot.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const code = 'ABCDEFGH';
  final profile = BabyProfile(
    name: 'Colette',
    birthDate: DateTime(2026, 9, 1),
    careSettings: const CareSettings(bathEveryDays: 3),
  );

  test('watchProfile émet null tant que rien n\'est écrit', () async {
    final repo = FirestoreBabyRepository(FakeFirebaseFirestore());
    expect(await repo.watchProfile(code).first, isNull);
  });

  test('saveProfile puis watchProfile renvoie le profil', () async {
    final repo = FirestoreBabyRepository(FakeFirebaseFirestore());
    await repo.saveProfile(code, profile);
    expect(await repo.watchProfile(code).first, profile);
  });

  test('saveProfile conserve le cordon tombé', () async {
    final repo = FirestoreBabyRepository(FakeFirebaseFirestore());
    final withCord = profile.copyWith(cordFallenAt: DateTime(2026, 9, 12));
    await repo.saveProfile(code, withCord);
    expect(await repo.watchProfile(code).first, withCord);
  });

  test(
    'les pesées sont triées de la plus récente à la plus ancienne',
    () async {
      final repo = FirestoreBabyRepository(FakeFirebaseFirestore());
      await repo.addWeight(
        code,
        WeightEntry(id: 'w1', measuredAt: DateTime(2026, 9, 2), grams: 3200),
      );
      await repo.addWeight(
        code,
        WeightEntry(id: 'w2', measuredAt: DateTime(2026, 9, 10), grams: 3600),
      );
      final weights = await repo.watchWeights(code).first;
      expect(weights.map((w) => w.id), ['w2', 'w1']);
    },
  );

  test('deleteWeight retire la pesée', () async {
    final repo = FirestoreBabyRepository(FakeFirebaseFirestore());
    await repo.addWeight(
      code,
      WeightEntry(id: 'w1', measuredAt: DateTime(2026, 9, 2), grams: 3200),
    );
    await repo.deleteWeight(code, 'w1');
    expect(await repo.watchWeights(code).first, isEmpty);
  });

  test('saveFeedingPlan écrit feedingPlan sans effacer baby', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreBabyRepository(db);
    await repo.saveProfile(code, profile);
    await repo.saveFeedingPlan(
      code,
      FeedingPlanSnapshot(
        nextBottleAt: DateTime(2026, 9, 21, 14),
        suggestedMl: 120,
        computedAt: DateTime(2026, 9, 21, 11),
      ),
    );
    final data = (await db.collection('households').doc(code).get()).data()!;
    expect((data['feedingPlan'] as Map)['suggestedMl'], 120);
    expect(data['baby'], isNotNull);
  });

  test('saveProfile efface une cible ajustée retirée', () async {
    final repo = FirestoreBabyRepository(FakeFirebaseFirestore());
    final withTarget = profile.copyWith(
      careSettings: const CareSettings(dailyTargetMl: 600),
    );
    await repo.saveProfile(code, withTarget);
    await repo.saveProfile(
      code,
      withTarget.copyWith(careSettings: const CareSettings()),
    );
    final stored = await repo.watchProfile(code).first;
    expect(stored?.careSettings.dailyTargetMl, isNull);
  });

  group('mesures de croissance', () {
    CollectionReference<Map<String, dynamic>> weights(
      FakeFirebaseFirestore db,
    ) => db.collection('households').doc(code).collection('weights');

    test('relit une ancienne pesée sans taille ni périmètre', () async {
      final db = FakeFirebaseFirestore();
      await weights(db).doc('old').set({
        'measuredAt': Timestamp.fromDate(DateTime(2026, 9, 2)),
        'grams': 3200,
      });
      final repo = FirestoreBabyRepository(db);
      expect(await repo.watchMeasurements(code).first, [
        GrowthMeasurement(
          id: 'old',
          measuredAt: DateTime(2026, 9, 2),
          grams: 3200,
        ),
      ]);
    });

    test(
      'aller-retour d\'une mesure complète et d\'une mesure sans poids',
      () async {
        final repo = FirestoreBabyRepository(FakeFirebaseFirestore());
        final full = GrowthMeasurement(
          id: 'm1',
          measuredAt: DateTime(2026, 9, 2),
          grams: 3200,
          lengthMm: 520,
          headCircumferenceMm: 350,
        );
        final lengthOnly = GrowthMeasurement(
          id: 'm2',
          measuredAt: DateTime(2026, 9, 10),
          lengthMm: 530,
        );
        await repo.saveMeasurement(code, full);
        await repo.saveMeasurement(code, lengthOnly);
        expect(await repo.watchMeasurements(code).first, [lengthOnly, full]);
      },
    );

    test('n\'écrit pas de clé nulle', () async {
      final db = FakeFirebaseFirestore();
      await FirestoreBabyRepository(db).saveMeasurement(
        code,
        GrowthMeasurement(
          id: 'm',
          measuredAt: DateTime(2026, 9, 2),
          lengthMm: 520,
        ),
      );
      final data = (await weights(db).doc('m').get()).data()!;
      expect(data.keys, unorderedEquals(['measuredAt', 'lengthMm']));
    });

    test(
      'une modification qui retire le périmètre le retire du document',
      () async {
        final db = FakeFirebaseFirestore();
        final repo = FirestoreBabyRepository(db);
        final measurement = GrowthMeasurement(
          id: 'm',
          measuredAt: DateTime(2026, 9, 2),
          grams: 3200,
          headCircumferenceMm: 350,
        );
        await repo.saveMeasurement(code, measurement);
        await repo.saveMeasurement(
          code,
          measurement.copyWith(headCircumferenceMm: null),
        );
        final data = (await weights(db).doc('m').get()).data()!;
        expect(data.containsKey('headCircumferenceMm'), isFalse);
        expect(data['grams'], 3200);
      },
    );

    test('deleteMeasurement retire la mesure', () async {
      final repo = FirestoreBabyRepository(FakeFirebaseFirestore());
      await repo.saveMeasurement(
        code,
        GrowthMeasurement(
          id: 'm',
          measuredAt: DateTime(2026, 9, 2),
          grams: 3200,
        ),
      );
      await repo.deleteMeasurement(code, 'm');
      expect(await repo.watchMeasurements(code).first, isEmpty);
    });
  });
}
