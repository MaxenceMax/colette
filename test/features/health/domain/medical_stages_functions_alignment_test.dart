import 'dart:io';

import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('les libellés des Cloud Functions couvrent tous les stageId', () {
    final source = File('functions/src/lib/medical-stages.ts')
        .readAsStringSync();
    final keys = RegExp(
      r"^\s+(\w+): '",
      multiLine: true,
    ).allMatches(source).map((m) => m.group(1)).toList();
    expect(keys, MedicalStageId.values.map((id) => id.name).toList());
  });
}
