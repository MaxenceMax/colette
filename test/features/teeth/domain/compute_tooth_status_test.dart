import 'package:colette/features/teeth/domain/entities/tooth_status.dart';
import 'package:colette/features/teeth/domain/use_cases/compute_tooth_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../teeth_factories.dart';

void main() {
  const status = ComputeToothStatus();
  final erupted = DateTime(2027, 3, 1, 12);
  final lost = DateTime(2033, 5, 2, 12);

  test('absente sans enregistrement ou avec une note seule', () {
    expect(status(null), ToothStatus.absent);
    expect(status(makeTooth(51, note: 'gencive gonflée')), ToothStatus.absent);
  });

  test('sortie', () {
    expect(status(makeTooth(51, eruptedAt: erupted)), ToothStatus.erupted);
  });

  test('tombée, même sans date de sortie', () {
    expect(
      status(makeTooth(51, eruptedAt: erupted, lostAt: lost)),
      ToothStatus.lost,
    );
    expect(status(makeTooth(51, lostAt: lost)), ToothStatus.lost);
  });

  test('isEmpty : ni date ni note', () {
    expect(makeTooth(51).isEmpty, isTrue);
    expect(makeTooth(51, note: '   ').isEmpty, isTrue);
    expect(makeTooth(51, note: 'x').isEmpty, isFalse);
    expect(makeTooth(51, eruptedAt: erupted).isEmpty, isFalse);
    expect(makeTooth(51, lostAt: lost).isEmpty, isFalse);
  });
}
