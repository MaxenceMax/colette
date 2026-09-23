import 'package:colette/features/diversification/presentation/widgets/food_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../helpers/diversification_overrides.dart';

void main() {
  Future<void> pump(WidgetTester tester) => pumpApp(
    tester,
    Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => showFoodPickerSheet(context),
          child: const Text('open'),
        ),
      ),
    ),
    overrides: diversificationOverrides(),
  );

  testWidgets('liste triée par ordre alphabétique du nom normalisé', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final titles = [
      for (final tile in tester.widgetList<ListTile>(find.byType(ListTile)))
        (tile.title! as Text).data,
    ];
    expect(titles.take(2), ['Arachide (poudre, pâte)', 'Brocoli']);
  });
}
