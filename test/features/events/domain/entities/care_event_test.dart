import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 21, 14, 30);
  final empty = CareEvent(
    id: 'e1',
    startAt: now,
    endAt: now,
    createdByDeviceId: 'd1',
    createdAt: now,
    updatedAt: now,
  );

  test('un événement sans soin ni biberon est vide', () {
    expect(empty.isEmpty, isTrue);
    expect(empty.checkedCares, isEmpty);
  });

  test('toggle coche un soin et checkedCares le liste', () {
    final withAdrigyl = empty.toggle(CareType.adrigyl, true);
    expect(withAdrigyl.has(CareType.adrigyl), isTrue);
    expect(withAdrigyl.checkedCares, [CareType.adrigyl]);
    expect(withAdrigyl.isEmpty, isFalse);
  });

  test('un biberon seul rend l\'événement non vide', () {
    final withBottle = empty.copyWith(bottleMl: 120);
    expect(withBottle.hasBottle, isTrue);
    expect(withBottle.isEmpty, isFalse);
  });
}
