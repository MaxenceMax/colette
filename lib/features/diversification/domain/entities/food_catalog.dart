import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/rule_source.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_catalog.freezed.dart';

/// Référence bibliographique d'une [RuleSource] ; sans lien pour un document
/// remis en consultation.
@freezed
abstract class SourceRef with _$SourceRef {
  const factory SourceRef({required String label, String? url}) = _SourceRef;
}

/// Repère sourcé de la feuille « Repères à son âge ».
@freezed
abstract class GuideItem with _$GuideItem {
  const factory GuideItem({
    required String text,
    required List<RuleSource> sources,

    /// Âge (mois révolus) à partir duquel l'étape s'applique ; absent pour
    /// un repère valable toute la phase.
    int? fromMonths,
  }) = _GuideItem;
}

/// Repères d'une phase : résumé des repas et détail textures / rythme.
@freezed
abstract class PhaseGuide with _$PhaseGuide {
  const factory PhaseGuide({
    required String mealsSummary,
    required List<GuideItem> items,
  }) = _PhaseGuide;
}

/// Contenu de la feuille « Repères à son âge ».
@freezed
abstract class AgeGuide with _$AgeGuide {
  const factory AgeGuide({
    required Map<DiversificationPhase, PhaseGuide> phases,
    required List<GuideItem> readinessSigns,
    required List<GuideItem> hungerSigns,
    required List<GuideItem> satietySigns,
    required List<GuideItem> safety,
  }) = _AgeGuide;
}

/// Catalogue embarqué : aliments, repères et sources.
@freezed
abstract class FoodCatalog with _$FoodCatalog {
  const factory FoodCatalog({
    required int version,
    required DateTime reviewedAt,
    required Map<RuleSource, SourceRef> sources,
    required AgeGuide guide,
    required List<Food> foods,
  }) = _FoodCatalog;
}
