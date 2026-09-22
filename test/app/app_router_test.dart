import 'package:colette/app/colette_app.dart';
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

  testWidgets('avec un code foyer, l\'app démarre sur le shell 3 onglets', (
    tester,
  ) async {
    await pumpColetteApp(tester, code: 'ABCDEFGH');
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Aujourd\'hui'), findsWidgets);
    expect(find.byType(OnboardingPage), findsNothing);
  });
}
