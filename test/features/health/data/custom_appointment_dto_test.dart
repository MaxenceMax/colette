import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/health/data/dtos/custom_appointment_dto.dart';
import 'package:colette/features/health/domain/entities/custom_vaccine.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../health_factories.dart';

void main() {
  late FakeFirebaseFirestore db;

  setUp(() => db = FakeFirebaseFirestore());

  CollectionReference<Map<String, dynamic>> col() => db
      .collection('households')
      .doc('ABCDEFGH')
      .collection('medicalAppointments');

  test('aller-retour complet avec vaccins connu et libre', () async {
    final rdv = makeAppointment(
      practitioner: 'Mme Dupont',
      doneAt: DateTime(2026, 11, 3, 10, 30),
      note: 'RAS',
      vaccines: [
        CustomVaccine(
          code: VaccineCode.mmr,
          givenAt: DateTime(2026, 11, 3),
          brand: 'Priorix',
          lot: 'L1',
        ),
        CustomVaccine(name: 'Grippe', givenAt: DateTime(2026, 11, 3)),
      ],
    );
    await col().doc(rdv.id).set(CustomAppointmentDto.toMap(rdv));
    final read = CustomAppointmentDto.fromDoc(await col().doc(rdv.id).get());
    expect(read, rdv);
  });

  test('n\'écrit pas les clés absentes', () {
    final map = CustomAppointmentDto.toMap(makeAppointment());
    expect(
      map.keys,
      unorderedEquals([
        'title',
        'appointmentAt',
        'updatedAt',
        'updatedByDeviceId',
      ]),
    );
  });

  test('null sans titre, sans date de RDV ou sans updatedAt', () async {
    await col().doc('a').set({
      'appointmentAt': Timestamp.fromDate(DateTime(2026, 11, 3)),
      'updatedAt': Timestamp.fromDate(DateTime(2026, 9, 1)),
    });
    await col().doc('b').set({
      'title': 'x',
      'updatedAt': Timestamp.fromDate(DateTime(2026, 9, 1)),
    });
    await col().doc('c').set({
      'title': 'x',
      'appointmentAt': Timestamp.fromDate(DateTime(2026, 11, 3)),
    });
    for (final id in ['a', 'b', 'c']) {
      expect(CustomAppointmentDto.fromDoc(await col().doc(id).get()), isNull);
    }
  });

  test('ignore un vaccin illisible, garde les autres', () async {
    await col().doc('a').set({
      'title': 'x',
      'appointmentAt': Timestamp.fromDate(DateTime(2026, 11, 3)),
      'updatedAt': Timestamp.fromDate(DateTime(2026, 9, 1)),
      'vaccines': [
        {'code': 'bcg', 'givenAt': Timestamp.fromDate(DateTime(2026, 11, 3))},
        {'name': 'Grippe'},
        {'name': 'VRS', 'givenAt': Timestamp.fromDate(DateTime(2026, 11, 3))},
        'x',
      ],
    });
    final read = CustomAppointmentDto.fromDoc(await col().doc('a').get())!;
    expect(read.vaccines.single.name, 'VRS');
  });
}
