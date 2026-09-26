import 'package:colette/features/health/presentation/widgets/appointment_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  Future<void> pumpCarousel(WidgetTester tester, List<String> labels) =>
      pumpApp(
        tester,
        Scaffold(
          body: ListView(
            children: [
              AppointmentCarousel(pages: [for (final l in labels) Text(l)]),
            ],
          ),
        ),
      );

  testWidgets('affiche la première page et un point par page', (
    tester,
  ) async {
    await pumpCarousel(tester, ['A', 'B', 'C']);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    expect(find.bySemanticsLabel('Rendez-vous 1 sur 3'), findsOneWidget);
  });

  testWidgets('glisser vers la gauche passe à la page suivante', (
    tester,
  ) async {
    await pumpCarousel(tester, ['A', 'B', 'C']);
    await tester.fling(find.text('A'), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('B'), findsOneWidget);
    expect(find.bySemanticsLabel('Rendez-vous 2 sur 3'), findsOneWidget);
  });

  testWidgets('hauteur de la plus grande page, même non affichée', (
    tester,
  ) async {
    await pumpApp(
      tester,
      Scaffold(
        body: ListView(
          children: const [
            AppointmentCarousel(
              pages: [SizedBox(height: 20), SizedBox(height: 50)],
            ),
          ],
        ),
      ),
    );
    expect(tester.getSize(find.byType(PageView)).height, 50);
  });

  testWidgets('la liste raccourcit : revient sur la dernière page valide', (
    tester,
  ) async {
    await pumpCarousel(tester, ['A', 'B', 'C']);
    await tester.fling(find.text('A'), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    await tester.fling(find.text('B'), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    await pumpCarousel(tester, ['A', 'B']);
    await tester.pumpAndSettle();
    expect(find.text('B'), findsOneWidget);
    expect(find.bySemanticsLabel('Rendez-vous 2 sur 2'), findsOneWidget);
  });
}
