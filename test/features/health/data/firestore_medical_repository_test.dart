import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/health/data/repositories/firestore_medical_repository.dart';
import 'package:colette/features/health/domain/entities/given_vaccine.dart';
import 'package:colette/features/health/domain/entities/medical_reminder_snapshot.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../health_factories.dart';

void main() {
  const code = 'ABCDEFGH';
  late FakeFirebaseFirestore db;
  late FirestoreMedicalRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreMedicalRepository(db);
  });

  CollectionReference<Map<String, dynamic>> visits() =>
      db.collection('households').doc(code).collection('medicalVisits');

  test('aller-retour d\'une visite complète, triée par étape', () async {
    final m2 = makeVisit(
      MedicalStageId.m2,
      appointmentAt: DateTime(2026, 11, 3, 10),
      practitioner: 'Dr Martin',
      doneAt: DateTime(2026, 11, 3, 10, 30),
      note: 'RAS',
      vaccines: {
        VaccineCode.hexavalent: GivenVaccine(
          givenAt: DateTime(2026, 11, 3, 10, 30),
          brand: 'Hexyon',
          lot: 'A123',
        ),
        VaccineCode.pneumococcal: GivenVaccine(
          givenAt: DateTime(2026, 11, 3, 10, 30),
        ),
      },
    );
    final day8 = makeVisit(MedicalStageId.day8, doneAt: DateTime(2026, 9, 4));
    await repo.saveVisit(code, m2);
    await repo.saveVisit(code, day8);
    expect(await repo.watchVisits(code).first, [day8, m2]);
  });

  test('n\'écrit pas les clés absentes', () async {
    await repo.saveVisit(
      code,
      makeVisit(MedicalStageId.m2, appointmentAt: DateTime(2026, 11, 3, 10)),
    );
    final data = (await visits().doc('m2').get()).data()!;
    expect(
      data.keys,
      unorderedEquals(['appointmentAt', 'updatedAt', 'updatedByDeviceId']),
    );
  });

  test('ignore un document d\'étape inconnue et un vaccin inconnu', () async {
    await visits().doc('m99').set({
      'updatedAt': Timestamp.fromDate(DateTime(2026, 9, 1)),
      'updatedByDeviceId': 'x',
    });
    await visits().doc('m3').set({
      'vaccines': {
        'menB': {'givenAt': Timestamp.fromDate(DateTime(2026, 12, 2))},
        'bcg': {'givenAt': Timestamp.fromDate(DateTime(2026, 12, 2))},
      },
      'updatedAt': Timestamp.fromDate(DateTime(2026, 9, 1)),
      'updatedByDeviceId': 'x',
    });
    final read = await repo.watchVisits(code).first;
    expect(read.single.stageId, MedicalStageId.m3);
    expect(read.single.vaccines.keys, [VaccineCode.menB]);
  });

  test('ignore un document sans updatedAt, lit le document valide', () async {
    await visits().doc('m3').set({'practitioner': 'Dr Martin'});
    await visits().doc('m4').set({
      'updatedAt': Timestamp.fromDate(DateTime(2026, 9, 1)),
      'updatedByDeviceId': 'x',
    });
    final read = await repo.watchVisits(code).first;
    expect(read.single.stageId, MedicalStageId.m4);
  });

  test(
    'vaccines invalide ou vaccin sans givenAt : visite lue sans ces vaccins',
    () async {
      await visits().doc('m3').set({
        'vaccines': 'x',
        'updatedAt': Timestamp.fromDate(DateTime(2026, 9, 1)),
        'updatedByDeviceId': 'x',
      });
      await visits().doc('m4').set({
        'vaccines': {
          'menB': {'brand': 'Bexsero'},
        },
        'updatedAt': Timestamp.fromDate(DateTime(2026, 9, 1)),
        'updatedByDeviceId': 'x',
      });
      final read = await repo.watchVisits(code).first;
      expect(read, hasLength(2));
      expect(read.every((v) => v.vaccines.isEmpty), isTrue);
    },
  );

  test('saveReminderSnapshot écrase les étapes du précédent appel', () async {
    await repo.saveReminderSnapshot(
      code,
      MedicalReminderSnapshot(
        stages: [
          MedicalReminderStage(
            stageId: MedicalStageId.m2,
            dueFrom: DateTime(2026, 11, 1),
            dueUntil: DateTime(2026, 12, 1),
            hasAppointment: false,
          ),
          MedicalReminderStage(
            stageId: MedicalStageId.m3,
            dueFrom: DateTime(2026, 11, 1),
            dueUntil: DateTime(2026, 12, 1),
            hasAppointment: false,
          ),
          MedicalReminderStage(
            stageId: MedicalStageId.m4,
            dueFrom: DateTime(2026, 11, 1),
            dueUntil: DateTime(2026, 12, 1),
            hasAppointment: false,
          ),
        ],
        computedAt: DateTime(2026, 10, 20),
      ),
    );
    await repo.saveReminderSnapshot(
      code,
      MedicalReminderSnapshot(
        stages: [
          MedicalReminderStage(
            stageId: MedicalStageId.m2,
            dueFrom: DateTime(2026, 11, 1),
            dueUntil: DateTime(2026, 12, 1),
            hasAppointment: true,
          ),
        ],
        computedAt: DateTime(2026, 10, 21),
      ),
    );
    final data = (await db.collection('households').doc(code).get()).data()!;
    final reminder = data['medicalReminder'] as Map<String, dynamic>;
    expect(reminder['stages'], hasLength(1));
  });

  test('deleteVisit retire la visite', () async {
    await repo.saveVisit(code, makeVisit(MedicalStageId.m2, note: 'x'));
    await repo.deleteVisit(code, MedicalStageId.m2);
    expect(await repo.watchVisits(code).first, isEmpty);
  });

  test(
    'saveReminderSnapshot écrit medicalReminder sans effacer baby',
    () async {
      await db.collection('households').doc(code).set({
        'baby': {'name': 'Colette'},
      });
      await repo.saveReminderSnapshot(
        code,
        MedicalReminderSnapshot(
          stages: [
            MedicalReminderStage(
              stageId: MedicalStageId.m2,
              dueFrom: DateTime(2026, 11, 1),
              dueUntil: DateTime(2026, 12, 1),
              hasAppointment: false,
            ),
          ],
          computedAt: DateTime(2026, 10, 20),
        ),
      );
      final data = (await db.collection('households').doc(code).get()).data()!;
      expect(data['baby'], isNotNull);
      final reminder = data['medicalReminder'] as Map<String, dynamic>;
      final stage = (reminder['stages'] as List).single as Map<String, dynamic>;
      expect(stage['stageId'], 'm2');
      expect(stage['hasAppointment'], isFalse);
      expect((stage['dueFrom'] as Timestamp).toDate(), DateTime(2026, 11, 1));
    },
  );
}
