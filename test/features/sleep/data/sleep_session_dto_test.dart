import 'package:colette/features/sleep/data/dtos/sleep_session_dto.dart';
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/sleep_session_factory.dart';

void main() {
  Future<dynamic> roundTrip(Map<String, dynamic> map) async {
    final db = FakeFirebaseFirestore();
    final ref = db.collection('sleeps').doc('s1');
    await ref.set(map);
    return SleepSessionDto.fromDoc(await ref.get());
  }

  test('aller-retour d\'un sommeil terminé', () async {
    final sleep = makeSleep(
      startAt: DateTime(2026, 9, 23, 13),
      endAt: DateTime(2026, 9, 23, 14),
      kind: SleepKind.night,
    );
    expect(await roundTrip(SleepSessionDto.toMap(sleep)), sleep);
  });

  test('aller-retour d\'un sommeil en cours : endAt écrit à null', () async {
    final sleep = makeSleep(startAt: DateTime(2026, 9, 23, 13));
    final map = SleepSessionDto.toMap(sleep);
    expect(map.containsKey('endAt'), isTrue);
    expect(map['endAt'], isNull);
    expect(await roundTrip(map), sleep);
  });

  test('kind inconnu lu comme sieste', () async {
    final map = SleepSessionDto.toMap(
      makeSleep(startAt: DateTime(2026, 9, 23, 13)),
    )..['kind'] = 'autre';
    expect((await roundTrip(map)).kind, SleepKind.nap);
  });
}
