import 'package:colette/features/diversification/domain/entities/food_catalog.dart';
import 'package:colette/features/diversification/domain/entities/food_rule.dart';
import 'package:colette/features/diversification/domain/entities/food_status.dart';
import 'package:colette/features/diversification/domain/entities/rule_source.dart';
import 'package:colette/features/diversification/presentation/widgets/food_status_badge.dart';
import 'package:colette/features/diversification/presentation/widgets/guide_item_tile.dart';
import 'package:colette/features/diversification/presentation/widgets/rule_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      pumpApp(tester, Scaffold(body: Center(child: child)));

  testWidgets('badge avoid : âge en années et sources', (tester) async {
    await pump(
      tester,
      const FoodStatusBadge(
        status: FoodStatus.avoid(
          untilMonths: 12,
          sources: [RuleSource.oms, RuleSource.anses],
        ),
      ),
    );
    expect(find.text('À éviter avant 1 an · OMS, Anses'), findsOneWidget);
  });

  testWidgets('badge avoid : âge en mois', (tester) async {
    await pump(
      tester,
      const FoodStatusBadge(
        status: FoodStatus.avoid(untilMonths: 8, sources: [RuleSource.spf]),
      ),
    );
    expect(find.text('À éviter avant 8 mois · SPF'), findsOneWidget);
  });

  testWidgets('badges pas encore recommandé, goûté, pas encore', (
    tester,
  ) async {
    await pump(
      tester,
      const Column(
        children: [
          FoodStatusBadge(status: FoodStatus.notYetRecommended()),
          FoodStatusBadge(
            status: FoodStatus.tasted(count: 3, needsPreparation: false),
          ),
          FoodStatusBadge(status: FoodStatus.notTasted(needsPreparation: true)),
        ],
      ),
    );
    expect(find.text('Dès 6 mois (OMS)'), findsOneWidget);
    expect(find.text('Goûté ×3'), findsOneWidget);
    expect(find.text('Pas encore'), findsOneWidget);
    expect(find.byIcon(Icons.content_cut), findsOneWidget);
  });

  testWidgets('règle : nature, âge, texte et sources', (tester) async {
    await pump(
      tester,
      const RuleTile(
        rule: FoodRule(
          kind: RuleKind.prepare,
          untilMonths: 60,
          sources: [RuleSource.spf],
          text: 'Couper en quatre.',
        ),
      ),
    );
    expect(find.text('Précaution jusqu\'à 5 ans'), findsOneWidget);
    expect(find.text('Couper en quatre.'), findsOneWidget);
    expect(find.text('Source : SPF'), findsOneWidget);
  });

  testWidgets('repère : texte et sources', (tester) async {
    await pump(
      tester,
      const GuideItemTile(
        item: GuideItem(
          text: 'Toujours assis.',
          sources: [RuleSource.spf, RuleSource.oms],
        ),
      ),
    );
    expect(find.text('Toujours assis.'), findsOneWidget);
    expect(find.text('Source : SPF, OMS'), findsOneWidget);
  });
}
