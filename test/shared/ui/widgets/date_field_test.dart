import 'package:colette/shared/ui/widgets/date_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  for (final value in ['Choisir la date du RDV', 'mar. 3 nov., 10h00']) {
    testWidgets('DateField ne déborde pas à 320 pt avec « $value »', (
      tester,
    ) async {
      await pumpApp(
        tester,
        Scaffold(
          body: DateField(label: 'Rendez-vous', value: value, onTap: () {}),
        ),
        viewSize: const Size(320, 800),
      );
      expect(tester.takeException(), isNull);
      expect(find.text(value), findsOneWidget);
    });
  }
}
