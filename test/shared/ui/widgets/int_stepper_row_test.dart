import 'package:colette/shared/ui/widgets/int_stepper_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('IntStepperRow respecte min et max', (tester) async {
    var value = 1;
    await pumpApp(
      tester,
      StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: IntStepperRow(
            label: 'Adrigyl par jour',
            value: value,
            min: 0,
            max: 2,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(value, 2);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(value, 2);
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(value, 1);
  });
}
