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

  testWidgets('le bouton moins est désactivé quand value == min', (
    tester,
  ) async {
    await pumpApp(
      tester,
      Scaffold(
        body: IntStepperRow(
          label: 'Adrigyl par jour',
          value: 0,
          min: 0,
          max: 2,
          onChanged: (_) {},
        ),
      ),
    );
    final button = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.remove),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('format remplace l\'affichage de la valeur', (tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: IntStepperRow(
          label: 'Intervalle',
          value: 165,
          min: 90,
          max: 300,
          step: 15,
          format: (v) => '${v ~/ 60} h ${(v % 60).toString().padLeft(2, '0')}',
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('2 h 45'), findsOneWidget);
    expect(find.text('165'), findsNothing);
  });
}
