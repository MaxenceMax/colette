import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/connectivity/connectivity_provider.dart';
import 'package:colette/core/theme/theme_service.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/dashboard/presentation/widgets/weight_card.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, List<WeightEntry> weights) async {
    final router = GoRouter(
      initialLocation: AppRoutes.today,
      routes: [
        GoRoute(
          path: AppRoutes.today,
          builder: (_, _) => const Scaffold(body: WeightCard()),
          routes: [
            GoRoute(
              path: 'weights',
              builder: (_, _) => const Scaffold(body: Text('page courbe')),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isOnlineProvider.overrideWith((ref) => Stream.value(true)),
          weightsProvider.overrideWith((ref) => Stream.value(weights)),
        ],
        child: MaterialApp.router(
          theme: const ThemeService().light(),
          locale: const Locale('fr'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final weights = [
    WeightEntry(id: 'a', measuredAt: DateTime(2026, 9, 10), grams: 3470),
    WeightEntry(id: 'b', measuredAt: DateTime(2026, 9, 14), grams: 3650),
  ];

  testWidgets('sans pesée : invite à ajouter la première', (tester) async {
    await pumpCard(tester, const []);
    expect(find.text('Poids'), findsOneWidget);
    expect(
      find.text('Aucune pesée. Ajoute la première pour suivre sa courbe.'),
      findsOneWidget,
    );
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('une pesée : poids et « Première pesée », sans courbe', (
    tester,
  ) async {
    await pumpCard(tester, [weights.first]);
    expect(find.text('3470 g'), findsOneWidget);
    expect(find.text('Première pesée'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('plusieurs pesées : évolution et mini-courbe', (tester) async {
    await pumpCard(tester, weights);
    expect(find.text('3650 g'), findsOneWidget);
    expect(find.text('Pesée du 14 sept. 2026'), findsOneWidget);
    expect(
      find.text('+180\u00A0g en 4\u00A0jours · +45\u00A0g/jour'),
      findsOneWidget,
    );
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('taper la carte ouvre la courbe de poids', (tester) async {
    await pumpCard(tester, weights);
    await tester.tap(find.byType(WeightCard));
    await tester.pumpAndSettle();
    expect(find.text('page courbe'), findsOneWidget);
  });
}
