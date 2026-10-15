import 'dart:convert';
import 'dart:io';

import 'package:colette/features/diversification/data/data_sources/catalog_asset_data_source.dart';
import 'package:colette/features/diversification/data/dtos/food_catalog_dto.dart';
import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/domain/entities/food_catalog.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/food_rule.dart';
import 'package:colette/features/diversification/domain/entities/rule_source.dart';
import 'package:colette/features/diversification/domain/use_cases/food_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FoodCatalog catalog;

  setUpAll(() {
    final text = File(CatalogAssetDataSource.path).readAsStringSync();
    catalog = FoodCatalogDto.fromJson(jsonDecode(text) as Map<String, dynamic>);
  });

  test('pubspec déclare le dossier du catalogue', () {
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('assets/diversification/'),
    );
  });

  test('environ 110 aliments, chaque groupe représenté', () {
    expect(catalog.foods.length, inInclusiveRange(100, 140));
    for (final group in FoodGroup.values) {
      expect(
        catalog.foods.where((f) => f.group == group),
        isNotEmpty,
        reason: '$group',
      );
    }
  });

  test('ids uniques au format slug', () {
    final ids = catalog.foods.map((f) => f.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    for (final id in ids) {
      expect(
        RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$').hasMatch(id),
        isTrue,
        reason: id,
      );
    }
  });

  test('noms uniques, insensibles aux accents et à la casse', () {
    final names = catalog.foods.map((f) => normalizeFoodName(f.name)).toList();
    expect(names.toSet(), hasLength(names.length));
  });

  test('chaque règle a une source déclarée et un âge cohérent', () {
    for (final food in catalog.foods) {
      for (final rule in food.rules) {
        expect(rule.sources, isNotEmpty, reason: food.id);
        expect(rule.text.trim(), isNotEmpty, reason: food.id);
        for (final source in rule.sources) {
          expect(
            catalog.sources.keys,
            contains(source),
            reason: '${food.id} $source',
          );
        }
        switch (rule.kind) {
          case RuleKind.avoid || RuleKind.prepare:
            expect(rule.untilMonths, isNotNull, reason: food.id);
            expect(rule.untilMonths, inInclusiveRange(1, 120), reason: food.id);
          case RuleKind.info:
            expect(rule.untilMonths, isNull, reason: food.id);
        }
      }
    }
  });

  test('le guide couvre les 4 phases et cite des sources déclarées', () {
    expect(
      catalog.guide.phases.keys.toSet(),
      DiversificationPhase.values.toSet(),
    );
    final items = [
      for (final phase in catalog.guide.phases.values) ...phase.items,
      ...catalog.guide.readinessSigns,
      ...catalog.guide.hungerSigns,
      ...catalog.guide.satietySigns,
      ...catalog.guide.safety,
    ];
    for (final item in items) {
      expect(item.sources, isNotEmpty, reason: item.text);
      for (final source in item.sources) {
        expect(catalog.sources.keys, contains(source), reason: item.text);
      }
    }
  });

  test('consignes du pédiatre intégrées au guide et aux aliments', () {
    expect(catalog.sources.keys, contains(RuleSource.pediatre));
    final preparation = catalog.guide.phases[DiversificationPhase.preparation]!;
    final steps = preparation.items
        .where((i) => i.sources.contains(RuleSource.pediatre))
        .map((i) => i.fromMonths)
        .toSet();
    expect(steps, containsAll([3, 4, 5]));
    expect(
      catalog.guide.phases[DiversificationPhase.months6To8]!.items.any(
        (i) => i.sources.contains(RuleSource.pediatre),
      ),
      isTrue,
    );

    List<FoodRule> pediatreRules(String id) => catalog.foods
        .firstWhere((f) => f.id == id)
        .rules
        .where((r) => r.sources.contains(RuleSource.pediatre))
        .toList();
    for (final id in [
      'yaourt',
      'oeuf-cuit',
      'amande',
      'arachide',
      'huile-colza',
      'huile-tournesol',
      'semoule',
      'pomme-de-terre',
      'petit-suisse',
      'cereales-infantiles',
    ]) {
      expect(pediatreRules(id), isNotEmpty, reason: id);
    }
    expect(
      {
        for (final food in catalog.foods)
          if (food.fromMonths != null) food.id: food.fromMonths,
      },
      {'yaourt': 3},
    );
    for (final id in ['pomme', 'banane', 'fraise', 'mangue']) {
      final cooked = pediatreRules(id).single;
      expect(cooked.kind, RuleKind.prepare, reason: id);
      expect(cooked.untilMonths, 6, reason: id);
    }
  });

  test('repères datés : âge en mois cohérent avec leur phase', () {
    for (final MapEntry(key: phase, value: guide)
        in catalog.guide.phases.entries) {
      for (final item in guide.items) {
        final from = item.fromMonths;
        if (from == null) continue;
        expect(
          DiversificationPhase.forAgeMonths(from),
          phase,
          reason: item.text,
        );
      }
    }
  });

  test('interdits clés présents avec la règle attendue', () {
    FoodRule strictestAvoid(String id) => catalog.foods
        .firstWhere((f) => f.id == id)
        .rules
        .where((r) => r.kind == RuleKind.avoid)
        .reduce((a, b) => a.untilMonths! >= b.untilMonths! ? a : b);
    expect(strictestAvoid('miel').untilMonths, 12);
    expect(
      strictestAvoid('miel').sources,
      containsAll([RuleSource.oms, RuleSource.anses]),
    );
    expect(strictestAvoid('lait-de-vache').untilMonths, 12);
    expect(strictestAvoid('oeuf-cru').untilMonths, 72);
    expect(strictestAvoid('fromage-lait-cru').untilMonths, 60);
    expect(strictestAvoid('fruits-a-coque-entiers').untilMonths, 60);
    expect(strictestAvoid('sel').untilMonths, 36);
  });
}
