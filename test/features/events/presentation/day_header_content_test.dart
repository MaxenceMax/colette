import 'package:colette/features/events/domain/entities/care_day_summary.dart';
import 'package:colette/features/events/presentation/widgets/day_header_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  Future<void> pumpHeader(
    WidgetTester tester, {
    String label = 'Aujourd\'hui',
    CareDaySummary? summary,
    Size? viewSize,
  }) => pumpApp(
    tester,
    Scaffold(
      body: DayHeaderContent(
        label: label,
        summary: summary,
        textStyle: const TextStyle(),
        feedingColor: const Color(0xFF000001),
        diaperColor: const Color(0xFF000002),
      ),
    ),
    viewSize: viewSize,
  );

  testWidgets('affiche le lait, les biberons, les couches et les pipis', (
    tester,
  ) async {
    await pumpHeader(
      tester,
      summary: const CareDaySummary(
        bottleMl: 620,
        bottleCount: 6,
        diapers: 5,
        pee: 4,
      ),
    );
    expect(find.text('620 ml · 6'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(
      find.bySemanticsLabel('620 ml en 6 biberons, 5 couches, 4 pipis'),
      findsOneWidget,
    );
  });

  testWidgets('masque les blocs à zéro', (tester) async {
    await pumpHeader(tester, summary: const CareDaySummary(pee: 1));
    expect(find.byIcon(Icons.local_drink_outlined), findsNothing);
    expect(find.byIcon(Icons.baby_changing_station), findsNothing);
    expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);
    expect(find.bySemanticsLabel('1 pipi'), findsOneWidget);
  });

  testWidgets('pas de bilan pour un jour vide', (tester) async {
    await pumpHeader(tester, summary: const CareDaySummary());
    expect(find.byType(Icon), findsNothing);
    await pumpHeader(tester);
    expect(find.byType(Icon), findsNothing);
    expect(find.text('Aujourd\'hui'), findsOneWidget);
  });

  testWidgets('un nom de jour long est coupé sans débordement', (tester) async {
    await pumpHeader(
      tester,
      label: 'Mercredi 30 septembre 2026, un jour très très long',
      summary: const CareDaySummary(
        bottleMl: 1240,
        bottleCount: 12,
        diapers: 10,
        pee: 10,
      ),
      viewSize: const Size(320, 200),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('1240 ml · 12'), findsOneWidget);
  });
}
