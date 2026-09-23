import 'dart:convert';

import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diversification/data/data_sources/catalog_asset_data_source.dart';
import 'package:colette/features/diversification/data/repositories/asset_food_catalog_repository.dart';
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/domain/entities/food_catalog.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/food_rule.dart';
import 'package:colette/features/diversification/domain/entities/rule_source.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/catalog_fixture.dart';

/// Bundle qui renvoie [content] pour toute clé, ou échoue si [content] est `null`.
class _StringBundle extends CachingAssetBundle {
  _StringBundle(this.content);

  final String? content;

  @override
  Future<ByteData> load(String key) async {
    final text = content;
    if (text == null) throw FlutterError('Asset introuvable : $key');
    return ByteData.sublistView(utf8.encode(text));
  }
}

AssetFoodCatalogRepository _repo(String? content) =>
    AssetFoodCatalogRepository(CatalogAssetDataSource(_StringBundle(content)));

void main() {
  test('charge et mappe le catalogue', () async {
    final result = await _repo(catalogFixtureJson).load();
    final catalog = result.getOrElse((f) => throw StateError('$f'));
    expect(catalog.version, 1);
    expect(catalog.reviewedAt, DateTime(2026, 9, 23));
    expect(catalog.sources[RuleSource.oms]?.label, 'OMS 2023');
    expect(catalog.foods, hasLength(8));
    final milk = catalog.foods.firstWhere((f) => f.id == 'lait-de-vache');
    expect(milk.group, FoodGroup.dairy);
    expect(milk.allergens, {Allergen.milk});
    expect(
      milk.rules.last,
      const FoodRule(
        kind: RuleKind.avoid,
        untilMonths: 12,
        sources: [RuleSource.anses, RuleSource.spf],
        text: 'Pas comme boisson principale avant 1 an.',
      ),
    );
    expect(catalog.foods.first.allergens, isEmpty);
    expect(catalog.foods.first.rules, isEmpty);
    expect(catalog.foods.first.isCustom, isFalse);
    expect(catalog.guide.phases.keys, DiversificationPhase.values);
    expect(
      catalog.guide.phases[DiversificationPhase.months6To8]?.mealsSummary,
      '2 à 3 repas',
    );
    expect(
      catalog.guide.readinessSigns.single,
      const GuideItem(
        text: 'Tient sa tête et son dos droits.',
        sources: [RuleSource.spf],
      ),
    );
  });

  test('valeur d\'enum inconnue : échec sans exception', () async {
    final broken = catalogFixtureJson.replaceFirst(
      '"vitaminAFruitsVeg"',
      '"legumes"',
    );
    final result = await _repo(broken).load();
    expect(result.getLeft().toNullable(), isA<UnknownFailure>());
  });

  test('asset absent : échec sans exception', () async {
    final result = await _repo(null).load();
    expect(result.isLeft(), isTrue);
  });
}
