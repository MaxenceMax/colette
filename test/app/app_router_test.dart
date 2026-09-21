import 'package:colette/app/colette_app.dart';
import 'package:colette/core/connectivity/connectivity_provider.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/household/presentation/pages/onboarding_page.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/in_memory_household_local_store.dart';

void main() {
  Future<void> pumpColetteApp(WidgetTester tester, {String? code}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          householdLocalStoreProvider.overrideWithValue(
            InMemoryHouseholdLocalStore(householdCode: code),
          ),
          isOnlineProvider.overrideWith((ref) => Stream.value(true)),
          firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
        ],
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
