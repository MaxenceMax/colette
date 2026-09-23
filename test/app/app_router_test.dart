import 'package:colette/app/colette_app.dart';
import 'package:colette/app/widgets/colette_tab_bar.dart';
import 'package:colette/features/diversification/presentation/pages/food_detail_page.dart';
import 'package:colette/features/diversification/presentation/pages/plate_page.dart';
import 'package:colette/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:colette/features/health/presentation/pages/health_page.dart';
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
    expect(find.byType(ColetteTabBar), findsNothing);
  });

  testWidgets(
    'avec un code foyer, l\'app démarre sur Aujourd\'hui, au centre de 5 onglets',
    (tester) async {
      await pumpColetteApp(tester, code: 'ABCDEFGH');
      final bar = find.byType(ColetteTabBar);
      expect(bar, findsOneWidget);
      expect(find.byType(DashboardPage), findsOneWidget);
      expect(find.byType(OnboardingPage), findsNothing);
      for (final label in ['Journal', 'Assiette', 'Santé', 'Réglages']) {
        expect(
          find.descendant(of: bar, matching: find.text(label)),
          findsOneWidget,
        );
      }
      // Aujourd'hui : bouton central sans libellé visible, mais accessible.
      expect(
        find.descendant(of: bar, matching: find.text('Aujourd\'hui')),
        findsNothing,
      );
      final center = find.descendant(
        of: bar,
        matching: find.byTooltip('Aujourd\'hui'),
      );
      expect(center, findsOneWidget);
      final labels = ['Journal', 'Assiette', 'Réglages', 'Santé']
          .map(
            (l) => tester
                .getCenter(find.descendant(of: bar, matching: find.text(l)))
                .dx,
          )
          .toList();
      final centerX = tester.getCenter(center).dx;
      expect(labels[0], lessThan(centerX));
      expect(labels[1], lessThan(centerX));
      expect(labels[2], greaterThan(centerX));
      expect(labels[3], greaterThan(centerX));
    },
  );

  testWidgets('onglet Santé puis retour à Aujourd\'hui par le bouton central', (
    tester,
  ) async {
    await pumpColetteApp(tester, code: 'ABCDEFGH');
    await tester.tap(
      find.descendant(
        of: find.byType(ColetteTabBar),
        matching: find.text('Santé'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HealthPage), findsOneWidget);

    await tester.tap(find.byTooltip('Aujourd\'hui'));
    await tester.pumpAndSettle();
    expect(find.byType(HealthPage), findsNothing);
    expect(find.byType(DashboardPage), findsOneWidget);
  });

  testWidgets('onglet Assiette puis fiche d\'un aliment du vrai catalogue', (
    tester,
  ) async {
    await pumpColetteApp(tester, code: 'ABCDEFGH');
    await tester.tap(
      find.descendant(
        of: find.byType(ColetteTabBar),
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
