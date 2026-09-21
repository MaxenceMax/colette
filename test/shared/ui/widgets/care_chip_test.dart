import 'package:colette/shared/domain/care_type.dart';
import 'package:colette/shared/ui/widgets/care_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('CareChip affiche le libellé et appelle onChanged au tap', (
    tester,
  ) async {
    bool? received;
    await pumpApp(
      tester,
      Scaffold(
        body: CareChip(
          type: CareType.adrigyl,
          selected: false,
          onChanged: (value) => received = value,
        ),
      ),
    );
    expect(find.text('Adrigyl'), findsOneWidget);
    await tester.tap(find.byType(CareChip));
    expect(received, isTrue);
  });

  testWidgets('CareChip sélectionnée appelle onChanged(false) au tap', (
    tester,
  ) async {
    bool? received;
    await pumpApp(
      tester,
      Scaffold(
        body: CareChip(
          type: CareType.adrigyl,
          selected: true,
          onChanged: (value) => received = value,
        ),
      ),
    );
    await tester.tap(find.byType(CareChip));
    expect(received, isFalse);
  });
}
