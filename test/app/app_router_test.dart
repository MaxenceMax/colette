import 'package:colette/app/colette_app.dart';
import 'package:colette/features/diversification/presentation/pages/food_detail_page.dart';
import 'package:colette/features/diversification/presentation/pages/plate_page.dart';
import 'package:colette/features/household/presentation/pages/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/colette_app_overrides.dart';

void main() {
  Future<void> pumpColetteApp(WidgetTester tester, {String? code}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: await coletteAppOverrides(householdCode: code),
        child: const ColetteApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sans code foyer, l\'app démarre sur l\'onboarding', (
    tester,
  ) async {
    await pumpColetteApp(tester);
    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('avec un code foyer, l\'app démarre sur le shell 4 onglets', (
    tester,
  ) async {
    await pumpColetteApp(tester, code: 'ABCDEFGH');
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.text('Aujourd\'hui'), findsWidgets);
    expect(find.byType(OnboardingPage), findsNothing);
  });

  testWidgets('onglet Assiette puis fiche d\'un aliment du vrai catalogue', (
    tester,
  ) async {
    await pumpColetteApp(tester, code: 'ABCDEFGH');
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Assiette'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PlatePage), findsOneWidget);
    final plateScrollable = find
        .descendant(
          of: find.byType(PlatePage),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.widgetWithText(TextField, 'Rechercher un aliment'),
      200,
      scrollable: plateScrollable,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Rechercher un aliment'),
      'miel',
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Miel'),
      200,
      scrollable: plateScrollable,
    );
    await tester.tap(find.text('Miel'));
    await tester.pumpAndSettle();
    expect(find.byType(FoodDetailPage), findsOneWidget);
    expect(find.text('À éviter avant 1 an'), findsOneWidget);
  });
}
