import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_catalog.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/food_rule.dart';
import 'package:colette/features/diversification/domain/entities/rule_source.dart';

/// Lecture stricte du JSON du catalogue : toute valeur inconnue ou manquante
/// lève une exception, convertie en `Failure` par le repository.
abstract final class FoodCatalogDto {
  static FoodCatalog fromJson(Map<String, dynamic> json) => FoodCatalog(
    version: json['version'] as int,
    reviewedAt: DateTime.parse(json['reviewedAt'] as String),
    sources: {
      for (final MapEntry(:key, :value)
          in (json['sources'] as Map<String, dynamic>).entries)
        RuleSource.values.byName(key): _sourceRef(
          value as Map<String, dynamic>,
        ),
    },
    guide: _guide(json['guide'] as Map<String, dynamic>),
    foods: [
      for (final food in json['foods'] as List<dynamic>)
        _food(food as Map<String, dynamic>),
    ],
  );

  static SourceRef _sourceRef(Map<String, dynamic> json) =>
      SourceRef(label: json['label'] as String, url: json['url'] as String);

  static AgeGuide _guide(Map<String, dynamic> json) => AgeGuide(
    phases: {
      for (final MapEntry(:key, :value)
          in (json['phases'] as Map<String, dynamic>).entries)
        DiversificationPhase.values.byName(key): _phase(
          value as Map<String, dynamic>,
        ),
    },
    readinessSigns: _items(json['readinessSigns']),
    hungerSigns: _items(json['hungerSigns']),
    satietySigns: _items(json['satietySigns']),
    safety: _items(json['safety']),
  );

  static PhaseGuide _phase(Map<String, dynamic> json) => PhaseGuide(
    mealsSummary: json['mealsSummary'] as String,
    items: _items(json['items']),
  );

  static List<GuideItem> _items(Object? json) => [
    for (final item in json as List<dynamic>)
      GuideItem(
        text: (item as Map<String, dynamic>)['text'] as String,
        sources: _sources(item['sources']),
      ),
  ];

  static List<RuleSource> _sources(Object? json) => [
    for (final source in json as List<dynamic>)
      RuleSource.values.byName(source as String),
  ];

  static Food _food(Map<String, dynamic> json) => Food(
    id: json['id'] as String,
    name: json['name'] as String,
    group: FoodGroup.values.byName(json['group'] as String),
    allergens: {
      for (final allergen in json['allergens'] as List<dynamic>? ?? const [])
        Allergen.values.byName(allergen as String),
    },
    rules: [
      for (final rule in json['rules'] as List<dynamic>? ?? const [])
        _rule(rule as Map<String, dynamic>),
    ],
  );

  /// `avoid` et `prepare` exigent `untilMonths`, `info` l'interdit.
  static FoodRule _rule(Map<String, dynamic> json) {
    final kind = RuleKind.values.byName(json['kind'] as String);
    final untilMonths = json['untilMonths'] as int?;
    if ((kind == RuleKind.info) != (untilMonths == null)) {
      throw FormatException('untilMonths incohérent pour une règle $kind');
    }
    return FoodRule(
      kind: kind,
      untilMonths: untilMonths,
      sources: _sources(json['sources']),
      text: json['text'] as String,
    );
  }
}
