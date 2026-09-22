import 'package:colette/features/diapers/domain/entities/diaper_stock_status.dart';
import 'package:colette/features/diapers/presentation/providers/diaper_stock_providers.dart';
import 'package:colette/features/diapers/presentation/widgets/diaper_stock_alert_card.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester,
    AsyncValue<DiaperStockStatus?> status,
  ) => pumpApp(
    tester,
    const Scaffold(body: DiaperStockAlertCard()),
    overrides: [diaperStockStatusProvider.overrideWithValue(status)],
  );

  testWidgets('rien sans stock renseigné', (tester) async {
    await pumpCard(tester, const AsyncData(null));
    expect(find.byType(ColetteCardSurface), findsNothing);
    expect(find.textContaining('couche'), findsNothing);
  });

  testWidgets('rien au-dessus du seuil', (tester) async {
    await pumpCard(
      tester,
      const AsyncData(DiaperStockStatus(remaining: 20, isLow: false)),
    );
    expect(find.byType(ColetteCardSurface), findsNothing);
  });

  testWidgets('rien en erreur', (tester) async {
    await pumpCard(tester, AsyncError(Exception('x'), StackTrace.empty));
    expect(find.byType(ColetteCardSurface), findsNothing);
  });

  testWidgets('alerte sous le seuil', (tester) async {
    await pumpCard(
      tester,
      const AsyncData(DiaperStockStatus(remaining: 7, isLow: true)),
    );
    expect(find.text('Plus que 7 couches'), findsOneWidget);
  });

  testWidgets('texte à zéro', (tester) async {
    await pumpCard(
      tester,
      const AsyncData(DiaperStockStatus(remaining: 0, isLow: true)),
    );
    expect(find.text('Plus aucune couche'), findsOneWidget);
  });
}
