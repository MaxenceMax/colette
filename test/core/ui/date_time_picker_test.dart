import 'package:colette/core/ui/date_time_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('le sélecteur tient dans une feuille basse sans déborder', (
    tester,
  ) async {
    // Feuille limitée à 9/16 de 480 pt, soit 270 pt : moins que la roue
    // (192 pt) plus le bouton (80 pt).
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showColetteDateTimePicker(
              context,
              initial: DateTime(2026, 9, 30, 20),
              mode: CupertinoDatePickerMode.dateAndTime,
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ),
      viewSize: const Size(402, 480),
    );

    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoDatePicker), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
