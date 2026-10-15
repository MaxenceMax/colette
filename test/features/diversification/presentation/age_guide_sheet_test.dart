import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/presentation/widgets/age_guide_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../helpers/diversification_overrides.dart';

void main() {
  testWidgets('repères de la phase, sources avec ou sans lien', (tester) async {
    await pumpApp(
      tester,
      const AgeGuideSheet(phase: DiversificationPhase.preparation),
      overrides: diversificationOverrides(),
    );
    expect(find.text('Dès 4 mois : purées de légumes.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Consignes du pédiatre'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Consignes du pédiatre'), findsOneWidget);
    expect(find.byType(SelectableText), findsNWidgets(3));
  });
}
