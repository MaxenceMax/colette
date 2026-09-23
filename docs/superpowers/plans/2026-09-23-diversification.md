# Diversification alimentaire — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Un 4ᵉ onglet « Assiette » pour suivre la diversification alimentaire : carnet de dégustations, catalogue d'aliments classés par groupe OMS avec règles d'âge sourcées (OMS d'abord, Anses / SPF en complément), allergènes introduits, diversité du jour, aliments à reproposer et repères par âge.

**Architecture:** Nouvelle feature `lib/features/diversification/` (domain, data, presentation). Le catalogue est un JSON embarqué (`assets/diversification/catalogue.json`) chargé par un data source `AssetBundle` ; les dégustations et aliments perso vivent dans `households/{code}/tastings` et `households/{code}/customFoods`. Tous les indicateurs sont dérivés côté app par des use cases purs.

**Tech Stack:** Flutter, Riverpod 3 codegen, freezed 3, fpdart, cloud_firestore, go_router, `fake_cloud_firestore`, `mocktail`, `pumpApp`.

Spec : `docs/superpowers/specs/2026-09-23-diversification-design.md`.

**Conventions du projet à respecter dans chaque tâche :**

- Travailler dans le worktree `.claude/worktrees/diversification` (branche `feat/diversification`). Ne jamais toucher le checkout principal, jamais de `git stash` nu.
- Après toute modification d'un fichier annoté `@freezed` ou `@riverpod` : `dart run build_runner build -d`.
- Après toute modification de `lib/l10n/app_fr.arb` : `flutter gen-l10n` (le dossier `lib/l10n/generated/` n'est pas versionné).
- Fin de tâche : `dart format lib test`, `dart analyze` (pas `flutter analyze`), `flutter test`.
- Commits en français, préfixes `feat:` / `test:` / `fix:` / `docs:` / `chore:`, `git add` explicite des fichiers de la tâche (y compris les `.g.dart` / `.freezed.dart` générés, versionnés dans ce dépôt), message terminé par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Couleurs `context.appColor(AppColors.xxx)`, espacements `AppSpacing`, tailles `AppSize`, rayons `AppRadius`, textes `S.of(context)`, styles `Theme.of(context).coletteTextStyles`. Pas de `width`/`height` en dur.
- Commentaire `///` d'une ligne sur chaque classe publique ; fichiers de moins de 300 lignes.
- Les agents ne modifient pas `docs/` (sauf la tâche 18) et ne revertent aucun changement qui n'est pas le leur.

**Précisions par rapport à la spec (alignées dans la tâche 18) :**

- La sous-titre de l'en-tête affiche « phase · repas » (ex. « Phase 6–8 mois · 2 à 3 repas ») sans l'âge, déjà affiché sur l'accueil.
- L'icône de précaution (`prepare` actif) s'affiche aussi sur « Pas encore » (utile pour le raisin avant la première dégustation). Sans profil, une règle `prepare` est considérée active (prudence).
- Textes d'interface au tutoiement, comme le reste de l'app.
- L'état des filtres du catalogue est un notifier Riverpod `CatalogFilter` (partagé entre la carte Allergènes et la section catalogue), la saisie de recherche garde son `TextEditingController` local.

---

## Carte des fichiers

```
lib/core/dates/date_extensions.dart                         (modif : completedMonthsBetween, dateAfterCompletedMonths)
lib/core/result/failure.dart                                (modif : 3 ValidationReason)
lib/core/ui/failure_message.dart                            (modif)
lib/core/firebase/firestore_paths.dart                      (modif : tastings, customFoods)
lib/features/dashboard/domain/use_cases/compute_baby_age.dart (modif : utilise completedMonthsBetween)
lib/app/router/app_router.dart                              (modif : branche /plate)
lib/app/main_shell.dart                                     (modif : 4ᵉ destination)
lib/l10n/app_fr.arb                                         (modif)
pubspec.yaml                                                (modif : assets)
firestore.rules                                             (modif : commentaire)
assets/diversification/catalogue.json                       (nouveau)

lib/features/diversification/
  domain/
    entities/food_group.dart, allergen.dart, rule_source.dart, food_rule.dart, food.dart,
             liking.dart, tasting.dart, diversification_phase.dart, diversification_timeline.dart,
             food_status.dart, food_catalog.dart, allergen_state.dart, daily_diversity.dart,
             retry_item.dart, food_filter.dart, food_group_section.dart, tasting_warning.dart
    repositories/food_catalog_repository.dart, tastings_repository.dart, custom_foods_repository.dart
    use_cases/food_name.dart, compute_diversification_phase.dart, compute_food_status.dart,
              compute_daily_diversity.dart, compute_allergen_progress.dart, compute_foods_to_retry.dart,
              check_tasting_warnings.dart, validate_custom_food.dart, filter_foods.dart
  data/
    dtos/food_catalog_dto.dart, tasting_dto.dart, custom_food_dto.dart
    data_sources/catalog_asset_data_source.dart
    repositories/asset_food_catalog_repository.dart, firestore_tastings_repository.dart,
                 firestore_custom_foods_repository.dart
  presentation/
    food_labels.dart
    providers/diversification_providers.dart, diversification_overview_providers.dart,
              catalog_filter.dart, tasting_form_controller.dart, custom_food_controller.dart
    pages/plate_page.dart, food_detail_page.dart
    widgets/food_status_badge.dart, rule_tile.dart, guide_item_tile.dart, phase_header.dart,
            age_guide_sheet.dart, preparation_card.dart, today_diversity_card.dart,
            allergens_card.dart, retry_card.dart, catalog_search_bar.dart, catalog_filter_chips.dart,
            food_catalog_sliver.dart, food_row.dart, tasting_form_sheet.dart, food_picker_sheet.dart,
            tasting_warnings_dialog.dart, custom_food_sheet.dart, tasting_history_sliver.dart

test/features/diversification/
  helpers/catalog_fixture.dart
  domain/…, data/…, presentation/…
```

---

### Task 1 : Dates — mois révolus partagés

**Files:**
- Modify: `lib/core/dates/date_extensions.dart`
- Modify: `lib/features/dashboard/domain/use_cases/compute_baby_age.dart`
- Test: `test/core/dates/date_extensions_test.dart`

- [x] **Step 1 : Tests rouges**

Ajouter à la fin du `main()` de `test/core/dates/date_extensions_test.dart` :

```dart
  group('completedMonthsBetween', () {
    test('compte les mois civils révolus', () {
      expect(completedMonthsBetween(DateTime(2026, 9, 15), DateTime(2027, 3, 14)), 5);
      expect(completedMonthsBetween(DateTime(2026, 9, 15), DateTime(2027, 3, 15)), 6);
    });

    test('ignore l\'heure', () {
      expect(
        completedMonthsBetween(DateTime(2026, 9, 15, 23), DateTime(2026, 10, 15, 1)),
        1,
      );
    });

    test('fin de mois : le 31 août atteint 6 mois le 1er mars', () {
      expect(completedMonthsBetween(DateTime(2026, 8, 31), DateTime(2027, 2, 28)), 5);
      expect(completedMonthsBetween(DateTime(2026, 8, 31), DateTime(2027, 3, 1)), 6);
    });

    test('négatif si to précède from', () {
      expect(completedMonthsBetween(DateTime(2026, 9, 15), DateTime(2026, 8, 15)), -1);
    });
  });

  group('dateAfterCompletedMonths', () {
    test('même jour du mois quand il existe', () {
      expect(dateAfterCompletedMonths(DateTime(2026, 9, 15, 10), 6), DateTime(2027, 3, 15));
    });

    test('1er du mois suivant quand le jour n\'existe pas', () {
      expect(dateAfterCompletedMonths(DateTime(2026, 8, 31), 6), DateTime(2027, 3, 1));
    });

    test('cohérent avec completedMonthsBetween', () {
      final birth = DateTime(2026, 8, 31);
      final date = dateAfterCompletedMonths(birth, 6);
      expect(completedMonthsBetween(birth, date), 6);
      expect(completedMonthsBetween(birth, date.startOfPreviousDay), 5);
    });
  });
```

- [x] **Step 2 : Vérifier l'échec**

Run: `flutter test test/core/dates/date_extensions_test.dart`
Expected: FAIL, `completedMonthsBetween` et `dateAfterCompletedMonths` non définis.

- [x] **Step 3 : Implémentation**

Ajouter à la fin de `lib/core/dates/date_extensions.dart` :

```dart
/// Mois civils révolus de [from] à [to], heure ignorée ; négatif si [to] précède [from].
int completedMonthsBetween(DateTime from, DateTime to) {
  final months = (to.year - from.year) * 12 + to.month - from.month;
  return to.day < from.day ? months - 1 : months;
}

/// Premier jour civil où [completedMonthsBetween] depuis [from] atteint [months].
/// Le 31 août + 6 mois donne le 1er mars (février n'a pas de 31).
DateTime dateAfterCompletedMonths(DateTime from, int months) {
  final target = DateTime(from.year, from.month + months);
  final daysInTarget = DateTime(target.year, target.month + 1, 0).day;
  return from.day <= daysInTarget
      ? DateTime(target.year, target.month, from.day)
      : DateTime(target.year, target.month + 1);
}
```

Dans `lib/features/dashboard/domain/use_cases/compute_baby_age.dart`, remplacer `_monthsBetween(birthDate, now)` par `completedMonthsBetween(birthDate, now)` et supprimer la méthode privée `_monthsBetween`.

- [x] **Step 4 : Vérifier le succès**

Run: `flutter test test/core/dates test/features/dashboard`
Expected: PASS (les tests de `ComputeBabyAge` restent verts sans modification).

- [x] **Step 5 : Commit**

```bash
dart format lib test && dart analyze
git add lib/core/dates/date_extensions.dart lib/features/dashboard/domain/use_cases/compute_baby_age.dart test/core/dates/date_extensions_test.dart
git commit -m "refactor: mois civils révolus partagés dans core/dates

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2 : Domaine — entités

**Files:**
- Create: `lib/features/diversification/domain/entities/food_group.dart`
- Create: `lib/features/diversification/domain/entities/allergen.dart`
- Create: `lib/features/diversification/domain/entities/rule_source.dart`
- Create: `lib/features/diversification/domain/entities/food_rule.dart`
- Create: `lib/features/diversification/domain/entities/food.dart`
- Create: `lib/features/diversification/domain/entities/liking.dart`
- Create: `lib/features/diversification/domain/entities/tasting.dart`
- Create: `lib/features/diversification/domain/entities/diversification_phase.dart`
- Create: `lib/features/diversification/domain/entities/diversification_timeline.dart`
- Create: `lib/features/diversification/domain/entities/food_status.dart`
- Create: `lib/features/diversification/domain/entities/food_catalog.dart`
- Create: `lib/features/diversification/domain/entities/allergen_state.dart`
- Create: `lib/features/diversification/domain/entities/daily_diversity.dart`
- Create: `lib/features/diversification/domain/entities/retry_item.dart`
- Create: `lib/features/diversification/domain/entities/food_filter.dart`
- Create: `lib/features/diversification/domain/entities/food_group_section.dart`
- Create: `lib/features/diversification/domain/entities/tasting_warning.dart`
- Test: `test/features/diversification/domain/entities_test.dart`

- [x] **Step 1 : Tests rouges**

`test/features/diversification/domain/entities_test.dart` :

```dart
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/food_rule.dart';
import 'package:colette/features/diversification/domain/entities/rule_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('7 groupes comptent pour la diversité, dans l\'ordre OMS', () {
    expect(FoodGroup.diversityGroups, [
      FoodGroup.grainsRootsTubers,
      FoodGroup.legumesNutsSeeds,
      FoodGroup.dairy,
      FoodGroup.fleshFoods,
      FoodGroup.eggs,
      FoodGroup.vitaminAFruitsVeg,
      FoodGroup.otherFruitsVeg,
    ]);
    expect(FoodGroup.outsideGroups.countsForDiversity, isFalse);
  });

  test('14 allergènes UE, 9 suivis', () {
    expect(Allergen.values, hasLength(14));
    expect(Allergen.tracked, hasLength(9));
    expect(Allergen.tracked.first, Allergen.milk);
  });

  test('une règle est active strictement avant untilMonths', () {
    const rule = FoodRule(
      kind: RuleKind.avoid,
      untilMonths: 12,
      sources: [RuleSource.oms],
      text: 'Botulisme',
    );
    expect(rule.isActiveAt(11), isTrue);
    expect(rule.isActiveAt(12), isFalse);
    const info = FoodRule(kind: RuleKind.info, sources: [RuleSource.spf], text: 'x');
    expect(info.isActiveAt(0), isFalse);
  });

  test('phases OMS selon les mois révolus', () {
    expect(DiversificationPhase.forAgeMonths(0), DiversificationPhase.preparation);
    expect(DiversificationPhase.forAgeMonths(5), DiversificationPhase.preparation);
    expect(DiversificationPhase.forAgeMonths(6), DiversificationPhase.months6To8);
    expect(DiversificationPhase.forAgeMonths(8), DiversificationPhase.months6To8);
    expect(DiversificationPhase.forAgeMonths(9), DiversificationPhase.months9To11);
    expect(DiversificationPhase.forAgeMonths(12), DiversificationPhase.months12To23);
    expect(DiversificationPhase.forAgeMonths(40), DiversificationPhase.months12To23);
  });

  test('Food.unknown : hors groupes, sans règle, marqué inconnu', () {
    final food = Food.unknown('disparu');
    expect(food.id, 'disparu');
    expect(food.isUnknown, isTrue);
    expect(food.group, FoodGroup.outsideGroups);
    expect(food.rules, isEmpty);
  });
}
```

- [x] **Step 2 : Vérifier l'échec**

Run: `flutter test test/features/diversification/domain/entities_test.dart`
Expected: FAIL (imports introuvables).

- [x] **Step 3 : Implémentation**

`food_group.dart` :

```dart
/// Groupes alimentaires OMS/UNICEF de la diversité alimentaire minimale, sans le
/// lait maternel, plus [outsideGroups] pour ce qui ne compte pas (graisses, sucre…).
enum FoodGroup {
  grainsRootsTubers,
  legumesNutsSeeds,
  dairy,
  fleshFoods,
  eggs,
  vitaminAFruitsVeg,
  otherFruitsVeg,
  outsideGroups;

  /// `true` si le groupe compte dans la diversité alimentaire du jour.
  bool get countsForDiversity => this != outsideGroups;

  /// Les 7 groupes comptés, dans l'ordre OMS.
  static List<FoodGroup> get diversityGroups =>
      values.where((group) => group.countsForDiversity).toList();
}
```

`allergen.dart` :

```dart
/// Les 14 allergènes réglementaires de l'UE (règlement 1169/2011, annexe II).
enum Allergen {
  milk,
  eggs,
  gluten,
  peanut,
  treeNuts,
  fish,
  crustaceans,
  sesame,
  soy,
  celery,
  mustard,
  sulphites,
  lupin,
  molluscs;

  /// Les 9 allergènes suivis par la carte Allergènes, dans l'ordre d'affichage.
  static const tracked = <Allergen>[
    Allergen.milk,
    Allergen.eggs,
    Allergen.gluten,
    Allergen.peanut,
    Allergen.treeNuts,
    Allergen.fish,
    Allergen.crustaceans,
    Allergen.sesame,
    Allergen.soy,
  ];
}
```

`rule_source.dart` :

```dart
/// Source d'une règle ou d'un repère.
enum RuleSource { oms, anses, spf, espghan, agriculture, efsa }
```

`food_rule.dart` :

```dart
import 'package:colette/features/diversification/domain/entities/rule_source.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_rule.freezed.dart';

/// Nature d'une règle : à éviter, précaution de préparation, simple conseil.
enum RuleKind { avoid, prepare, info }

/// Règle d'un aliment, avec son âge limite éventuel et ses sources.
@freezed
abstract class FoodRule with _$FoodRule {
  const FoodRule._();

  const factory FoodRule({
    required RuleKind kind,

    /// Âge (mois révolus) à partir duquel la règle ne s'applique plus ;
    /// obligatoire pour `avoid` et `prepare`, absent pour `info`.
    int? untilMonths,
    required List<RuleSource> sources,
    required String text,
  }) = _FoodRule;

  /// `true` si la règle a un âge limite et que [ageMonths] est en dessous.
  bool isActiveAt(int ageMonths) {
    final until = untilMonths;
    return until != null && ageMonths < until;
  }
}
```

`food.dart` :

```dart
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/food_rule.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'food.freezed.dart';

/// Aliment du catalogue ou ajouté par le foyer.
@freezed
abstract class Food with _$Food {
  const Food._();

  const factory Food({
    required String id,
    required String name,
    required FoodGroup group,
    @Default(<Allergen>{}) Set<Allergen> allergens,
    @Default(<FoodRule>[]) List<FoodRule> rules,
    @Default(false) bool isCustom,

    /// Référencé par une dégustation mais introuvable (catalogue et aliments perso).
    @Default(false) bool isUnknown,
  }) = _Food;

  /// Aliment introuvable : affiché « Aliment inconnu », hors diversité.
  factory Food.unknown(String id) => Food(
    id: id,
    name: '',
    group: FoodGroup.outsideGroups,
    isUnknown: true,
  );
}
```

`liking.dart` :

```dart
/// Appréciation d'une dégustation.
enum Liking { loved, meh, refused }
```

`tasting.dart` :

```dart
import 'package:colette/features/diversification/domain/entities/liking.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tasting.freezed.dart';

/// Essai d'un aliment. [id] vide tant que la dégustation n'est pas enregistrée.
@freezed
abstract class Tasting with _$Tasting {
  const factory Tasting({
    required String id,
    required String foodId,
    required DateTime at,
    Liking? liking,
    @Default(false) bool hadReaction,
    String? note,
  }) = _Tasting;
}
```

`diversification_phase.dart` :

```dart
/// Âges de référence de la diversification.
abstract final class DiversificationAges {
  /// Début recommandé par l'OMS.
  static const whoStartMonths = 6;

  /// Âge minimal selon les recommandations françaises (Anses, SPF).
  static const franceMinMonths = 4;
}

/// Phase OMS de l'alimentation complémentaire.
enum DiversificationPhase {
  preparation,
  months6To8,
  months9To11,
  months12To23;

  /// Phase à [ageMonths] mois révolus ; au-delà de 23 mois, reste en 12–23.
  static DiversificationPhase forAgeMonths(int ageMonths) => switch (ageMonths) {
    < DiversificationAges.whoStartMonths => preparation,
    < 9 => months6To8,
    < 12 => months9To11,
    _ => months12To23,
  };
}
```

`diversification_timeline.dart` :

```dart
import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'diversification_timeline.freezed.dart';

/// Phase courante, âge en mois révolus et échéance des 6 mois.
@freezed
abstract class DiversificationTimeline with _$DiversificationTimeline {
  const factory DiversificationTimeline({
    required DiversificationPhase phase,
    required int ageMonths,
    required DateTime sixMonthsDate,
    required int daysUntilSixMonths,
  }) = _DiversificationTimeline;
}
```

`food_status.dart` :

```dart
import 'package:colette/features/diversification/domain/entities/rule_source.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_status.freezed.dart';

/// Statut d'un aliment pour l'âge courant du bébé.
@freezed
sealed class FoodStatus with _$FoodStatus {
  /// Règle `avoid` active la plus prudente.
  const factory FoodStatus.avoid({
    required int untilMonths,
    required List<RuleSource> sources,
  }) = FoodStatusAvoid;

  /// Bébé n'a pas encore 6 mois.
  const factory FoodStatus.notYetRecommended() = FoodStatusNotYetRecommended;

  /// Déjà goûté [count] fois.
  const factory FoodStatus.tasted({
    required int count,
    required bool needsPreparation,
  }) = FoodStatusTasted;

  /// Jamais goûté.
  const factory FoodStatus.notTasted({required bool needsPreparation}) =
      FoodStatusNotTasted;
}
```

`food_catalog.dart` :

```dart
import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/rule_source.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_catalog.freezed.dart';

/// Référence bibliographique d'une [RuleSource].
@freezed
abstract class SourceRef with _$SourceRef {
  const factory SourceRef({required String label, required String url}) =
      _SourceRef;
}

/// Repère sourcé de la feuille « Repères à son âge ».
@freezed
abstract class GuideItem with _$GuideItem {
  const factory GuideItem({
    required String text,
    required List<RuleSource> sources,
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
```

`allergen_state.dart` :

```dart
/// Avancement d'un allergène suivi.
enum AllergenState { notYet, introduced, reaction }
```

`daily_diversity.dart` :

```dart
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_diversity.freezed.dart';

/// Groupes OMS couverts par les dégustations du jour.
@freezed
abstract class DailyDiversity with _$DailyDiversity {
  const factory DailyDiversity({
    required Set<FoodGroup> coveredGroups,
    required int tastingCount,
  }) = _DailyDiversity;
}
```

`retry_item.dart` :

```dart
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/liking.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'retry_item.freezed.dart';

/// Aliment à reproposer : dernière appréciation « bof » ou « refusé ».
@freezed
abstract class RetryItem with _$RetryItem {
  const factory RetryItem({
    required Food food,
    required Liking lastLiking,
    required int tastingCount,
  }) = _RetryItem;
}
```

`food_filter.dart` :

```dart
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_filter.freezed.dart';

/// Filtre principal du catalogue.
enum CatalogMode { all, notTasted, avoid }

/// Recherche et filtres du catalogue.
@freezed
abstract class FoodFilter with _$FoodFilter {
  const factory FoodFilter({
    @Default('') String query,
    @Default(CatalogMode.all) CatalogMode mode,
    Allergen? allergen,
  }) = _FoodFilter;
}
```

`food_group_section.dart` :

```dart
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_group_section.freezed.dart';

/// Aliments d'un groupe, après filtrage du catalogue.
@freezed
abstract class FoodGroupSection with _$FoodGroupSection {
  const factory FoodGroupSection({
    required FoodGroup group,
    required List<Food> foods,
  }) = _FoodGroupSection;
}
```

`tasting_warning.dart` :

```dart
import 'package:colette/features/diversification/domain/entities/food_rule.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tasting_warning.freezed.dart';

/// Avertissement à confirmer avant d'enregistrer une dégustation.
@freezed
sealed class TastingWarning with _$TastingWarning {
  /// Règle `avoid` active à l'âge du bébé au moment de la dégustation.
  const factory TastingWarning.avoidRule(FoodRule rule) =
      TastingWarningAvoidRule;

  /// Bébé a moins de 4 mois.
  const factory TastingWarning.tooEarly() = TastingWarningTooEarly;
}
```

- [x] **Step 4 : Génération et vérification**

Run: `dart run build_runner build -d && flutter test test/features/diversification/domain/entities_test.dart`
Expected: PASS.

- [x] **Step 5 : Commit**

```bash
dart format lib test && dart analyze
git add lib/features/diversification/domain/entities test/features/diversification/domain/entities_test.dart
git commit -m "feat: entités du domaine diversification

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3 : Use cases — phase et statut d'un aliment

**Files:**
- Create: `lib/features/diversification/domain/use_cases/compute_diversification_phase.dart`
- Create: `lib/features/diversification/domain/use_cases/compute_food_status.dart`
- Test: `test/features/diversification/domain/compute_diversification_phase_test.dart`
- Test: `test/features/diversification/domain/compute_food_status_test.dart`

- [x] **Step 1 : Tests rouges**

`compute_diversification_phase_test.dart` :

```dart
import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/domain/use_cases/compute_diversification_phase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const compute = ComputeDiversificationPhase();
  final birth = DateTime(2026, 9, 15);

  test('nouveau-né : préparation, compte à rebours jusqu\'aux 6 mois', () {
    final t = compute(birthDate: birth, now: DateTime(2026, 9, 23, 8));
    expect(t.phase, DiversificationPhase.preparation);
    expect(t.ageMonths, 0);
    expect(t.sixMonthsDate, DateTime(2027, 3, 15));
    expect(t.daysUntilSixMonths, 173);
  });

  test('la veille des 6 mois : encore préparation, 1 jour', () {
    final t = compute(birthDate: birth, now: DateTime(2027, 3, 14, 23));
    expect(t.phase, DiversificationPhase.preparation);
    expect(t.daysUntilSixMonths, 1);
  });

  test('le jour des 6 mois : phase 6–8 mois, 0 jour', () {
    final t = compute(birthDate: birth, now: DateTime(2027, 3, 15));
    expect(t.phase, DiversificationPhase.months6To8);
    expect(t.ageMonths, 6);
    expect(t.daysUntilSixMonths, 0);
  });

  test('après les 6 mois, le compte à rebours reste à 0', () {
    final t = compute(birthDate: birth, now: DateTime(2027, 7, 1));
    expect(t.phase, DiversificationPhase.months9To11);
    expect(t.daysUntilSixMonths, 0);
  });

  test('date de naissance dans le futur : âge 0', () {
    final t = compute(birthDate: birth, now: DateTime(2026, 9, 1));
    expect(t.ageMonths, 0);
  });
}
```

`compute_food_status_test.dart` :

```dart
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/food_rule.dart';
import 'package:colette/features/diversification/domain/entities/food_status.dart';
import 'package:colette/features/diversification/domain/entities/rule_source.dart';
import 'package:colette/features/diversification/domain/use_cases/compute_food_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const compute = ComputeFoodStatus();
  const carrot = Food(id: 'carotte', name: 'Carotte', group: FoodGroup.vitaminAFruitsVeg);
  const honey = Food(
    id: 'miel',
    name: 'Miel',
    group: FoodGroup.outsideGroups,
    rules: [
      FoodRule(kind: RuleKind.avoid, untilMonths: 12, sources: [RuleSource.oms, RuleSource.anses], text: 'Botulisme'),
    ],
  );
  const cowMilk = Food(
    id: 'lait-de-vache',
    name: 'Lait de vache',
    group: FoodGroup.dairy,
    rules: [
      FoodRule(kind: RuleKind.info, sources: [RuleSource.oms], text: 'Acceptable dès 6 mois'),
      FoodRule(kind: RuleKind.avoid, untilMonths: 12, sources: [RuleSource.anses, RuleSource.spf], text: 'Pas en boisson'),
    ],
  );
  const wholeNuts = Food(
    id: 'fruits-a-coque-entiers',
    name: 'Fruits à coque entiers',
    group: FoodGroup.legumesNutsSeeds,
    rules: [
      FoodRule(kind: RuleKind.avoid, untilMonths: 36, sources: [RuleSource.anses], text: '3 ans'),
      FoodRule(kind: RuleKind.avoid, untilMonths: 60, sources: [RuleSource.spf], text: '5 ans'),
    ],
  );
  const grape = Food(
    id: 'raisin',
    name: 'Raisin',
    group: FoodGroup.otherFruitsVeg,
    rules: [
      FoodRule(kind: RuleKind.prepare, untilMonths: 60, sources: [RuleSource.spf], text: 'Couper'),
    ],
  );

  test('règle avoid active : à éviter, avec ses sources', () {
    expect(
      compute(food: honey, ageMonths: 8, tastingCount: 0),
      const FoodStatus.avoid(untilMonths: 12, sources: [RuleSource.oms, RuleSource.anses]),
    );
  });

  test('avoid prime sur « pas encore 6 mois » et sur les dégustations', () {
    expect(compute(food: honey, ageMonths: 3, tastingCount: 2), isA<FoodStatusAvoid>());
  });

  test('règle échue : statut normal', () {
    expect(
      compute(food: honey, ageMonths: 12, tastingCount: 0),
      const FoodStatus.notTasted(needsPreparation: false),
    );
  });

  test('sources divergentes : la règle active la plus prudente l\'emporte', () {
    expect(
      compute(food: cowMilk, ageMonths: 7, tastingCount: 0),
      const FoodStatus.avoid(untilMonths: 12, sources: [RuleSource.anses, RuleSource.spf]),
    );
    expect(
      compute(food: wholeNuts, ageMonths: 40, tastingCount: 0),
      const FoodStatus.avoid(untilMonths: 60, sources: [RuleSource.spf]),
    );
    expect(
      compute(food: wholeNuts, ageMonths: 20, tastingCount: 0),
      const FoodStatus.avoid(untilMonths: 60, sources: [RuleSource.spf]),
    );
  });

  test('avant 6 mois : pas encore recommandé', () {
    expect(
      compute(food: carrot, ageMonths: 5, tastingCount: 1),
      const FoodStatus.notYetRecommended(),
    );
  });

  test('goûté ou pas encore, avec précaution de préparation active', () {
    expect(
      compute(food: grape, ageMonths: 8, tastingCount: 0),
      const FoodStatus.notTasted(needsPreparation: true),
    );
    expect(
      compute(food: grape, ageMonths: 8, tastingCount: 3),
      const FoodStatus.tasted(count: 3, needsPreparation: true),
    );
    expect(
      compute(food: grape, ageMonths: 60, tastingCount: 3),
      const FoodStatus.tasted(count: 3, needsPreparation: false),
    );
  });

  test('sans profil : ni avoid ni « pas encore », prepare considéré actif', () {
    expect(
      compute(food: honey, ageMonths: null, tastingCount: 0),
      const FoodStatus.notTasted(needsPreparation: false),
    );
    expect(
      compute(food: grape, ageMonths: null, tastingCount: 1),
      const FoodStatus.tasted(count: 1, needsPreparation: true),
    );
  });
}
```

- [x] **Step 2 : Vérifier l'échec**

Run: `flutter test test/features/diversification/domain`
Expected: FAIL (use cases absents).

- [x] **Step 3 : Implémentation**

`compute_diversification_phase.dart` :

```dart
import 'dart:math';

import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/domain/entities/diversification_timeline.dart';

/// Phase OMS, mois révolus et jours restants avant 6 mois.
class ComputeDiversificationPhase {
  const ComputeDiversificationPhase();

  DiversificationTimeline call({
    required DateTime birthDate,
    required DateTime now,
  }) {
    final ageMonths = max(0, completedMonthsBetween(birthDate, now));
    final sixMonths = dateAfterCompletedMonths(
      birthDate,
      DiversificationAges.whoStartMonths,
    );
    return DiversificationTimeline(
      phase: DiversificationPhase.forAgeMonths(ageMonths),
      ageMonths: ageMonths,
      sixMonthsDate: sixMonths,
      daysUntilSixMonths: max(0, calendarDaysBetween(now, sixMonths)),
    );
  }
}
```

`compute_food_status.dart` :

```dart
import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_rule.dart';
import 'package:colette/features/diversification/domain/entities/food_status.dart';

/// Statut d'un aliment : règle `avoid` la plus prudente, puis « dès 6 mois »,
/// puis goûté / pas encore. Sans âge ([ageMonths] `null`), seules les
/// dégustations comptent et toute règle `prepare` est considérée active.
class ComputeFoodStatus {
  const ComputeFoodStatus();

  FoodStatus call({
    required Food food,
    required int? ageMonths,
    required int tastingCount,
  }) {
    if (ageMonths != null) {
      final avoid = _strictestActiveAvoid(food.rules, ageMonths);
      if (avoid != null) {
        return FoodStatus.avoid(
          untilMonths: avoid.untilMonths!,
          sources: avoid.sources,
        );
      }
      if (ageMonths < DiversificationAges.whoStartMonths) {
        return const FoodStatus.notYetRecommended();
      }
    }
    final needsPreparation = food.rules.any(
      (rule) =>
          rule.kind == RuleKind.prepare &&
          (ageMonths == null || rule.isActiveAt(ageMonths)),
    );
    return tastingCount > 0
        ? FoodStatus.tasted(
            count: tastingCount,
            needsPreparation: needsPreparation,
          )
        : FoodStatus.notTasted(needsPreparation: needsPreparation);
  }

  static FoodRule? _strictestActiveAvoid(List<FoodRule> rules, int ageMonths) {
    FoodRule? strictest;
    for (final rule in rules) {
      if (rule.kind != RuleKind.avoid || !rule.isActiveAt(ageMonths)) continue;
      if (strictest == null || rule.untilMonths! > strictest.untilMonths!) {
        strictest = rule;
      }
    }
    return strictest;
  }
}
```

- [x] **Step 4 : Vérifier le succès**

Run: `flutter test test/features/diversification/domain`
Expected: PASS.

- [x] **Step 5 : Commit**

```bash
dart format lib test && dart analyze
git add lib/features/diversification/domain/use_cases test/features/diversification/domain
git commit -m "feat: phase de diversification et statut d'un aliment selon l'âge

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4 : Use cases — diversité du jour, allergènes, à reproposer

**Files:**
- Create: `lib/features/diversification/domain/use_cases/compute_daily_diversity.dart`
- Create: `lib/features/diversification/domain/use_cases/compute_allergen_progress.dart`
- Create: `lib/features/diversification/domain/use_cases/compute_foods_to_retry.dart`
- Test: `test/features/diversification/domain/tasting_summaries_test.dart`

- [x] **Step 1 : Tests rouges**

`tasting_summaries_test.dart` :

```dart
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/allergen_state.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/liking.dart';
import 'package:colette/features/diversification/domain/entities/retry_item.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/domain/use_cases/compute_allergen_progress.dart';
import 'package:colette/features/diversification/domain/use_cases/compute_daily_diversity.dart';
import 'package:colette/features/diversification/domain/use_cases/compute_foods_to_retry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const carrot = Food(id: 'carotte', name: 'Carotte', group: FoodGroup.vitaminAFruitsVeg);
  const pasta = Food(id: 'pates', name: 'Pâtes', group: FoodGroup.grainsRootsTubers, allergens: {Allergen.gluten});
  const egg = Food(id: 'oeuf', name: 'Œuf', group: FoodGroup.eggs, allergens: {Allergen.eggs});
  const oil = Food(id: 'huile', name: 'Huile', group: FoodGroup.outsideGroups);
  const broccoli = Food(id: 'brocoli', name: 'Brocoli', group: FoodGroup.otherFruitsVeg);
  final foods = {for (final f in [carrot, pasta, egg, oil, broccoli]) f.id: f};

  Tasting tasting(String foodId, DateTime at, {Liking? liking, bool reaction = false}) =>
      Tasting(id: '$foodId-$at', foodId: foodId, at: at, liking: liking, hadReaction: reaction);

  group('ComputeDailyDiversity', () {
    const compute = ComputeDailyDiversity();
    final now = DateTime(2027, 4, 10, 18);

    test('groupes du jour local, hors « hors groupes » et inconnus', () {
      final result = compute(
        tastings: [
          tasting('carotte', DateTime(2027, 4, 10, 12)),
          tasting('pates', DateTime(2027, 4, 10, 0)),
          tasting('huile', DateTime(2027, 4, 10, 12)),
          tasting('disparu', DateTime(2027, 4, 10, 12)),
          tasting('oeuf', DateTime(2027, 4, 9, 23, 59)),
        ],
        foodsById: foods,
        now: now,
      );
      expect(result.coveredGroups, {FoodGroup.vitaminAFruitsVeg, FoodGroup.grainsRootsTubers});
      expect(result.tastingCount, 4);
    });

    test('aucune dégustation : vide', () {
      final result = compute(tastings: const [], foodsById: foods, now: now);
      expect(result.coveredGroups, isEmpty);
      expect(result.tastingCount, 0);
    });
  });

  group('ComputeAllergenProgress', () {
    const compute = ComputeAllergenProgress();

    test('9 allergènes suivis dans l\'ordre, pas encore par défaut', () {
      final result = compute(tastings: const [], foodsById: foods);
      expect(result.keys.toList(), Allergen.tracked);
      expect(result.values.toSet(), {AllergenState.notYet});
    });

    test('introduit après une dégustation sans réaction', () {
      final result = compute(tastings: [tasting('pates', DateTime(2027, 4, 1))], foodsById: foods);
      expect(result[Allergen.gluten], AllergenState.introduced);
      expect(result[Allergen.eggs], AllergenState.notYet);
    });

    test('une réaction l\'emporte, même suivie de dégustations sans réaction', () {
      final result = compute(
        tastings: [
          tasting('oeuf', DateTime(2027, 4, 5)),
          tasting('oeuf', DateTime(2027, 4, 2), reaction: true),
          tasting('oeuf', DateTime(2027, 4, 1)),
        ],
        foodsById: foods,
      );
      expect(result[Allergen.eggs], AllergenState.reaction);
    });

    test('aliment inconnu ignoré', () {
      final result = compute(tastings: [tasting('disparu', DateTime(2027, 4, 1))], foodsById: foods);
      expect(result.values.toSet(), {AllergenState.notYet});
    });
  });

  group('ComputeFoodsToRetry', () {
    const compute = ComputeFoodsToRetry();

    test('dernière appréciation bof ou refusé, avec le nombre d\'essais', () {
      final result = compute(
        tastings: [
          tasting('brocoli', DateTime(2027, 4, 9), liking: Liking.refused),
          tasting('carotte', DateTime(2027, 4, 8), liking: Liking.loved),
          tasting('brocoli', DateTime(2027, 4, 3), liking: Liking.meh),
          tasting('carotte', DateTime(2027, 4, 2), liking: Liking.refused),
        ],
        foodsById: foods,
      );
      expect(result, [
        const RetryItem(food: broccoli, lastLiking: Liking.refused, tastingCount: 2),
      ]);
    });

    test('une appréciation absente est ignorée, la précédente compte', () {
      final result = compute(
        tastings: [
          tasting('brocoli', DateTime(2027, 4, 9)),
          tasting('brocoli', DateTime(2027, 4, 3), liking: Liking.meh),
        ],
        foodsById: foods,
      );
      expect(result.single.lastLiking, Liking.meh);
      expect(result.single.tastingCount, 2);
    });

    test('ordre : dégustation la plus récente d\'abord, entrée non triée acceptée', () {
      final result = compute(
        tastings: [
          tasting('carotte', DateTime(2027, 4, 1), liking: Liking.meh),
          tasting('brocoli', DateTime(2027, 4, 5), liking: Liking.refused),
        ],
        foodsById: foods,
      );
      expect(result.map((r) => r.food.id), ['brocoli', 'carotte']);
    });

    test('aliment inconnu ignoré', () {
      final result = compute(
        tastings: [tasting('disparu', DateTime(2027, 4, 1), liking: Liking.refused)],
        foodsById: foods,
      );
      expect(result, isEmpty);
    });
  });
}
```

- [x] **Step 2 : Vérifier l'échec**

Run: `flutter test test/features/diversification/domain/tasting_summaries_test.dart`
Expected: FAIL.

- [x] **Step 3 : Implémentation**

`compute_daily_diversity.dart` :

```dart
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/diversification/domain/entities/daily_diversity.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';

/// Groupes OMS couverts le jour civil de [now] ; les aliments inconnus et
/// « hors groupes » comptent comme dégustations mais pas comme groupes.
class ComputeDailyDiversity {
  const ComputeDailyDiversity();

  DailyDiversity call({
    required List<Tasting> tastings,
    required Map<String, Food> foodsById,
    required DateTime now,
  }) {
    final today = [
      for (final tasting in tastings)
        if (tasting.at.isSameDay(now)) tasting,
    ];
    return DailyDiversity(
      coveredGroups: {
        for (final tasting in today)
          if (foodsById[tasting.foodId]?.group case final group?
              when group.countsForDiversity)
            group,
      },
      tastingCount: today.length,
    );
  }
}
```

`compute_allergen_progress.dart` :

```dart
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/allergen_state.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';

/// État des 9 allergènes suivis : une réaction signalée l'emporte toujours,
/// sinon une dégustation sans réaction suffit à « introduit ».
class ComputeAllergenProgress {
  const ComputeAllergenProgress();

  Map<Allergen, AllergenState> call({
    required List<Tasting> tastings,
    required Map<String, Food> foodsById,
  }) {
    final states = {
      for (final allergen in Allergen.tracked) allergen: AllergenState.notYet,
    };
    for (final tasting in tastings) {
      final allergens = foodsById[tasting.foodId]?.allergens ?? const {};
      for (final allergen in allergens) {
        final current = states[allergen];
        if (current == null) continue;
        if (tasting.hadReaction) {
          states[allergen] = AllergenState.reaction;
        } else if (current == AllergenState.notYet) {
          states[allergen] = AllergenState.introduced;
        }
      }
    }
    return states;
  }
}
```

`compute_foods_to_retry.dart` :

```dart
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/liking.dart';
import 'package:colette/features/diversification/domain/entities/retry_item.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';

/// Aliments dont la dernière dégustation appréciée vaut « bof » ou « refusé »,
/// la dégustation la plus récente d'abord. Aliments inconnus ignorés.
class ComputeFoodsToRetry {
  const ComputeFoodsToRetry();

  List<RetryItem> call({
    required List<Tasting> tastings,
    required Map<String, Food> foodsById,
  }) {
    final sorted = [...tastings]..sort((a, b) => b.at.compareTo(a.at));
    final counts = <String, int>{};
    final lastLiking = <String, Liking>{};
    for (final tasting in sorted) {
      counts[tasting.foodId] = (counts[tasting.foodId] ?? 0) + 1;
      if (tasting.liking case final liking?
          when !lastLiking.containsKey(tasting.foodId)) {
        lastLiking[tasting.foodId] = liking;
      }
    }
    return [
      for (final foodId in counts.keys)
        if ((foodsById[foodId], lastLiking[foodId])
            case (final food?, final liking?) when liking != Liking.loved)
          RetryItem(
            food: food,
            lastLiking: liking,
            tastingCount: counts[foodId]!,
          ),
    ];
  }
}
```

(`counts` est une `LinkedHashMap` : ses clés gardent l'ordre de première rencontre, donc de la dégustation la plus récente.)

- [x] **Step 4 : Vérifier le succès**

Run: `flutter test test/features/diversification/domain`
Expected: PASS.

- [x] **Step 5 : Commit**

```bash
dart format lib test && dart analyze
git add lib/features/diversification/domain/use_cases test/features/diversification/domain/tasting_summaries_test.dart
git commit -m "feat: diversité du jour, allergènes introduits et aliments à reproposer

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5 : Use cases — avertissements, aliment perso, filtre du catalogue

**Files:**
- Create: `lib/features/diversification/domain/use_cases/food_name.dart`
- Create: `lib/features/diversification/domain/use_cases/check_tasting_warnings.dart`
- Create: `lib/features/diversification/domain/use_cases/validate_custom_food.dart`
- Create: `lib/features/diversification/domain/use_cases/filter_foods.dart`
- Modify: `lib/core/result/failure.dart` (enum `ValidationReason`)
- Modify: `lib/core/ui/failure_message.dart`
- Modify: `lib/l10n/app_fr.arb`
- Test: `test/features/diversification/domain/tasting_rules_test.dart`
- Test: `test/features/diversification/domain/filter_foods_test.dart`

- [x] **Step 1 : Tests rouges**

`tasting_rules_test.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/food_rule.dart';
import 'package:colette/features/diversification/domain/entities/rule_source.dart';
import 'package:colette/features/diversification/domain/entities/tasting_warning.dart';
import 'package:colette/features/diversification/domain/use_cases/check_tasting_warnings.dart';
import 'package:colette/features/diversification/domain/use_cases/food_name.dart';
import 'package:colette/features/diversification/domain/use_cases/validate_custom_food.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeFoodName : minuscules, sans accents, espaces réduits', () {
    expect(normalizeFoodName('  Œuf   Dur '), 'oeuf dur');
    expect(normalizeFoodName('Épinard'), 'epinard');
    expect(normalizeFoodName('Comté'), 'comte');
  });

  group('CheckTastingWarnings', () {
    const check = CheckTastingWarnings();
    const honeyRule = FoodRule(kind: RuleKind.avoid, untilMonths: 12, sources: [RuleSource.oms], text: 'Botulisme');
    const honey = Food(id: 'miel', name: 'Miel', group: FoodGroup.outsideGroups, rules: [
      honeyRule,
      FoodRule(kind: RuleKind.info, sources: [RuleSource.spf], text: 'Info'),
    ]);
    const carrot = Food(id: 'carotte', name: 'Carotte', group: FoodGroup.vitaminAFruitsVeg);
    final birth = DateTime(2026, 9, 15);

    test('règle avoid active à la date de la dégustation', () {
      expect(
        check(food: honey, at: DateTime(2027, 5, 1), birthDate: birth),
        [const TastingWarning.avoidRule(honeyRule)],
      );
      expect(check(food: honey, at: DateTime(2027, 9, 15), birthDate: birth), isEmpty);
    });

    test('avant 4 mois : trop tôt', () {
      expect(
        check(food: carrot, at: DateTime(2027, 1, 14), birthDate: birth),
        [const TastingWarning.tooEarly()],
      );
      expect(check(food: carrot, at: DateTime(2027, 1, 15), birthDate: birth), isEmpty);
    });

    test('sans date de naissance : aucun avertissement', () {
      expect(check(food: honey, at: DateTime(2027, 1, 1), birthDate: null), isEmpty);
    });
  });

  group('ValidateCustomFood', () {
    const validate = ValidateCustomFood();

    test('nom vide', () {
      expect(validate(name: '   ', existingNames: const []), ValidationReason.emptyName);
    });

    test('nom trop long', () {
      expect(validate(name: 'a' * 41, existingNames: const []), ValidationReason.foodNameTooLong);
      expect(validate(name: 'a' * 40, existingNames: const []), isNull);
    });

    test('doublon insensible aux accents et à la casse', () {
      expect(
        validate(name: 'epinard ', existingNames: const ['Épinard']),
        ValidationReason.duplicateFoodName,
      );
      expect(validate(name: 'Kaki', existingNames: const ['Épinard']), isNull);
    });
  });
}
```

`filter_foods_test.dart` :

```dart
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_filter.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/food_status.dart';
import 'package:colette/features/diversification/domain/entities/rule_source.dart';
import 'package:colette/features/diversification/domain/use_cases/filter_foods.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const filter = FilterFoods();
  const carrot = Food(id: 'carotte', name: 'Carotte', group: FoodGroup.vitaminAFruitsVeg);
  const squash = Food(id: 'courge', name: 'Courge', group: FoodGroup.vitaminAFruitsVeg);
  const egg = Food(id: 'oeuf', name: 'Œuf dur', group: FoodGroup.eggs, allergens: {Allergen.eggs});
  const honey = Food(id: 'miel', name: 'Miel', group: FoodGroup.outsideGroups);
  final unknown = Food.unknown('disparu');
  final foods = [honey, squash, egg, carrot, unknown];
  final statuses = <String, FoodStatus>{
    'carotte': const FoodStatus.tasted(count: 2, needsPreparation: false),
    'courge': const FoodStatus.notTasted(needsPreparation: false),
    'oeuf': const FoodStatus.notTasted(needsPreparation: false),
    'miel': const FoodStatus.avoid(untilMonths: 12, sources: [RuleSource.oms]),
  };
  const counts = {'carotte': 2, 'miel': 1};

  List<(FoodGroup, List<String>)> run(FoodFilter f) => [
    for (final section in filter(foods: foods, filter: f, statuses: statuses, tastingCounts: counts))
      (section.group, section.foods.map((food) => food.id).toList()),
  ];

  test('tous : groupés dans l\'ordre OMS, triés par nom, inconnus exclus', () {
    expect(run(const FoodFilter()), [
      (FoodGroup.eggs, ['oeuf']),
      (FoodGroup.vitaminAFruitsVeg, ['carotte', 'courge']),
      (FoodGroup.outsideGroups, ['miel']),
    ]);
  });

  test('recherche insensible aux accents', () {
    expect(run(const FoodFilter(query: 'OEUF')), [(FoodGroup.eggs, ['oeuf'])]);
  });

  test('pas goûtés : sans aucune dégustation, quel que soit le statut', () {
    expect(run(const FoodFilter(mode: CatalogMode.notTasted)), [
      (FoodGroup.eggs, ['oeuf']),
      (FoodGroup.vitaminAFruitsVeg, ['courge']),
    ]);
  });

  test('à éviter : statut avoid', () {
    expect(run(const FoodFilter(mode: CatalogMode.avoid)), [(FoodGroup.outsideGroups, ['miel'])]);
  });

  test('filtre allergène', () {
    expect(run(const FoodFilter(allergen: Allergen.eggs)), [(FoodGroup.eggs, ['oeuf'])]);
  });

  test('aucun résultat : liste vide', () {
    expect(run(const FoodFilter(query: 'zzz')), isEmpty);
  });
}
```

- [x] **Step 2 : Vérifier l'échec**

Run: `flutter test test/features/diversification/domain`
Expected: FAIL.

- [x] **Step 3 : Implémentation**

Dans `lib/core/result/failure.dart`, ajouter à la fin de l'enum `ValidationReason` (après `invalidDiaperCount`) :

```dart
  foodNameTooLong,
  duplicateFoodName,
  customFoodInUse,
```

Dans `lib/core/ui/failure_message.dart`, ajouter dans le `switch (reason)` :

```dart
    ValidationReason.foodNameTooLong => s.errorFoodNameTooLong,
    ValidationReason.duplicateFoodName => s.errorDuplicateFoodName,
    ValidationReason.customFoodInUse => s.errorCustomFoodInUse,
```

Dans `lib/l10n/app_fr.arb`, ajouter avant la dernière accolade (penser à la virgule après la dernière entrée existante) :

```json
  "errorFoodNameTooLong": "40 caractères maximum.",
  "errorDuplicateFoodName": "Cet aliment existe déjà.",
  "errorCustomFoodInUse": "Cet aliment a des dégustations : il ne peut pas être supprimé."
```

`food_name.dart` :

```dart
const _folded = {
  'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a',
  'ç': 'c',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'î': 'i', 'ï': 'i', 'í': 'i',
  'ô': 'o', 'ö': 'o', 'ó': 'o',
  'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
  'ÿ': 'y', 'ñ': 'n', 'œ': 'oe', 'æ': 'ae',
};

final _spaces = RegExp(r'\s+');

/// Nom normalisé pour la recherche et les doublons : minuscules, sans accents,
/// espaces de bord retirés et espaces internes réduits à un seul.
String normalizeFoodName(String name) {
  final buffer = StringBuffer();
  for (final char in name.trim().toLowerCase().split('')) {
    buffer.write(_folded[char] ?? char);
  }
  return buffer.toString().replaceAll(_spaces, ' ');
}
```

`check_tasting_warnings.dart` :

```dart
import 'dart:math';

import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_rule.dart';
import 'package:colette/features/diversification/domain/entities/tasting_warning.dart';

/// Avertissements à confirmer avant d'enregistrer : bébé de moins de 4 mois
/// à la date [at], règles `avoid` actives à cet âge. Vide sans date de naissance.
class CheckTastingWarnings {
  const CheckTastingWarnings();

  List<TastingWarning> call({
    required Food food,
    required DateTime at,
    required DateTime? birthDate,
  }) {
    if (birthDate == null) return const [];
    final ageMonths = max(0, completedMonthsBetween(birthDate, at));
    return [
      if (ageMonths < DiversificationAges.franceMinMonths)
        const TastingWarning.tooEarly(),
      for (final rule in food.rules)
        if (rule.kind == RuleKind.avoid && rule.isActiveAt(ageMonths))
          TastingWarning.avoidRule(rule),
    ];
  }
}
```

`validate_custom_food.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diversification/domain/use_cases/food_name.dart';

/// Contrôle le nom d'un aliment perso ; `null` s'il est valide.
class ValidateCustomFood {
  const ValidateCustomFood();

  static const maxNameLength = 40;

  ValidationReason? call({
    required String name,
    required Iterable<String> existingNames,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return ValidationReason.emptyName;
    if (trimmed.length > maxNameLength) return ValidationReason.foodNameTooLong;
    final normalized = normalizeFoodName(trimmed);
    final duplicate = existingNames.any(
      (existing) => normalizeFoodName(existing) == normalized,
    );
    return duplicate ? ValidationReason.duplicateFoodName : null;
  }
}
```

`filter_foods.dart` :

```dart
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_filter.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/food_group_section.dart';
import 'package:colette/features/diversification/domain/entities/food_status.dart';
import 'package:colette/features/diversification/domain/use_cases/food_name.dart';

/// Applique recherche et filtres, puis groupe par [FoodGroup] (ordre de l'enum)
/// avec les aliments triés par nom normalisé. Les aliments inconnus sont exclus.
class FilterFoods {
  const FilterFoods();

  List<FoodGroupSection> call({
    required Iterable<Food> foods,
    required FoodFilter filter,
    required Map<String, FoodStatus> statuses,
    required Map<String, int> tastingCounts,
  }) {
    final query = normalizeFoodName(filter.query);
    bool keep(Food food) {
      if (food.isUnknown) return false;
      if (query.isNotEmpty && !normalizeFoodName(food.name).contains(query)) {
        return false;
      }
      if (filter.allergen case final allergen?
          when !food.allergens.contains(allergen)) {
        return false;
      }
      return switch (filter.mode) {
        CatalogMode.all => true,
        CatalogMode.notTasted => (tastingCounts[food.id] ?? 0) == 0,
        CatalogMode.avoid => statuses[food.id] is FoodStatusAvoid,
      };
    }

    final kept = foods.where(keep).toList()
      ..sort(
        (a, b) => normalizeFoodName(a.name).compareTo(normalizeFoodName(b.name)),
      );
    return [
      for (final group in FoodGroup.values)
        if (kept.where((food) => food.group == group).toList()
            case final groupFoods when groupFoods.isNotEmpty)
          FoodGroupSection(group: group, foods: groupFoods),
    ];
  }
}
```

- [x] **Step 4 : Vérifier le succès**

Run: `flutter gen-l10n && flutter test test/features/diversification/domain test/core`
Expected: PASS.

- [x] **Step 5 : Commit**

```bash
dart format lib test && dart analyze && flutter test
git add lib/features/diversification/domain/use_cases lib/core/result/failure.dart lib/core/ui/failure_message.dart lib/l10n/app_fr.arb test/features/diversification/domain
git commit -m "feat: avertissements de dégustation, validation des aliments perso et filtre du catalogue

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6 : Data — catalogue (DTO, data source asset, repository)

**Files:**
- Create: `lib/features/diversification/domain/repositories/food_catalog_repository.dart`
- Create: `lib/features/diversification/data/dtos/food_catalog_dto.dart`
- Create: `lib/features/diversification/data/data_sources/catalog_asset_data_source.dart`
- Create: `lib/features/diversification/data/repositories/asset_food_catalog_repository.dart`
- Create: `test/features/diversification/helpers/catalog_fixture.dart`
- Test: `test/features/diversification/data/food_catalog_repository_test.dart`

- [x] **Step 1 : Fixture de test**

`test/features/diversification/helpers/catalog_fixture.dart` (réutilisée par les tests de présentation) :

```dart
import 'dart:convert';

import 'package:colette/features/diversification/data/dtos/food_catalog_dto.dart';
import 'package:colette/features/diversification/domain/entities/food_catalog.dart';

/// Petit catalogue représentatif : une règle avoid, des sources divergentes,
/// une précaution de préparation, des allergènes.
const catalogFixtureJson = '''
{
  "version": 1,
  "reviewedAt": "2026-09-23",
  "sources": {
    "oms": { "label": "OMS 2023", "url": "https://www.who.int/publications/i/item/9789240081864" },
    "anses": { "label": "Anses 2019", "url": "https://www.anses.fr/fr/system/files/NUT2017SA0145.pdf" },
    "spf": { "label": "SPF 2021", "url": "https://www.mangerbouger.fr" }
  },
  "guide": {
    "phases": {
      "preparation": { "mealsSummary": "Lait uniquement", "items": [ { "text": "Lait maternel ou infantile.", "sources": ["oms"] } ] },
      "months6To8": { "mealsSummary": "2 à 3 repas", "items": [ { "text": "Purées lisses puis écrasées.", "sources": ["oms", "spf"] } ] },
      "months9To11": { "mealsSummary": "3 à 4 repas", "items": [ { "text": "Haché fin, morceaux fondants.", "sources": ["oms"] } ] },
      "months12To23": { "mealsSummary": "3 à 4 repas", "items": [ { "text": "Plats familiaux.", "sources": ["oms"] } ] }
    },
    "readinessSigns": [ { "text": "Tient sa tête et son dos droits.", "sources": ["spf"] } ],
    "hungerSigns": [ { "text": "Ouvre la bouche.", "sources": ["spf"] } ],
    "satietySigns": [ { "text": "Tourne la tête.", "sources": ["spf"] } ],
    "safety": [ { "text": "Toujours assis et surveillé.", "sources": ["spf"] } ]
  },
  "foods": [
    { "id": "carotte", "name": "Carotte", "group": "vitaminAFruitsVeg" },
    { "id": "brocoli", "name": "Brocoli", "group": "otherFruitsVeg" },
    { "id": "pates", "name": "Pâtes", "group": "grainsRootsTubers", "allergens": ["gluten"] },
    { "id": "oeuf-cuit", "name": "Œuf bien cuit", "group": "eggs", "allergens": ["eggs"] },
    { "id": "miel", "name": "Miel", "group": "outsideGroups", "rules": [
      { "kind": "avoid", "untilMonths": 12, "sources": ["oms", "anses"], "text": "Risque de botulisme infantile." }
    ] },
    { "id": "lait-de-vache", "name": "Lait de vache (boisson)", "group": "dairy", "allergens": ["milk"], "rules": [
      { "kind": "info", "sources": ["oms"], "text": "L'OMS l'accepte dès 6 mois." },
      { "kind": "avoid", "untilMonths": 12, "sources": ["anses", "spf"], "text": "Pas comme boisson principale avant 1 an." }
    ] },
    { "id": "raisin", "name": "Raisin", "group": "otherFruitsVeg", "rules": [
      { "kind": "prepare", "untilMonths": 60, "sources": ["spf"], "text": "Couper en quatre, retirer les pépins." }
    ] },
    { "id": "arachide", "name": "Arachide (poudre, pâte)", "group": "legumesNutsSeeds", "allergens": ["peanut"], "rules": [
      { "kind": "prepare", "untilMonths": 60, "sources": ["spf"], "text": "Jamais entière : en pâte ou en poudre." }
    ] }
  ]
}
''';

/// [catalogFixtureJson] décodé.
FoodCatalog catalogFixture() => FoodCatalogDto.fromJson(
  jsonDecode(catalogFixtureJson) as Map<String, dynamic>,
);
```

- [x] **Step 2 : Tests rouges**

`test/features/diversification/data/food_catalog_repository_test.dart` :

```dart
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
    expect(milk.rules.last, const FoodRule(
      kind: RuleKind.avoid,
      untilMonths: 12,
      sources: [RuleSource.anses, RuleSource.spf],
      text: 'Pas comme boisson principale avant 1 an.',
    ));
    expect(catalog.foods.first.allergens, isEmpty);
    expect(catalog.foods.first.rules, isEmpty);
    expect(catalog.foods.first.isCustom, isFalse);
    expect(catalog.guide.phases.keys, DiversificationPhase.values);
    expect(catalog.guide.phases[DiversificationPhase.months6To8]?.mealsSummary, '2 à 3 repas');
    expect(catalog.guide.readinessSigns.single, const GuideItem(
      text: 'Tient sa tête et son dos droits.',
      sources: [RuleSource.spf],
    ));
  });

  test('valeur d\'enum inconnue : échec sans exception', () async {
    final broken = catalogFixtureJson.replaceFirst('"vitaminAFruitsVeg"', '"legumes"');
    final result = await _repo(broken).load();
    expect(result.getLeft().toNullable(), isA<UnknownFailure>());
  });

  test('asset absent : échec sans exception', () async {
    final result = await _repo(null).load();
    expect(result.isLeft(), isTrue);
  });
}
```

- [x] **Step 3 : Vérifier l'échec**

Run: `flutter test test/features/diversification/data`
Expected: FAIL.

- [x] **Step 4 : Implémentation**

`domain/repositories/food_catalog_repository.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diversification/domain/entities/food_catalog.dart';
import 'package:fpdart/fpdart.dart';

/// Catalogue d'aliments embarqué.
abstract interface class FoodCatalogRepository {
  Future<Either<Failure, FoodCatalog>> load();
}
```

`data/dtos/food_catalog_dto.dart` :

```dart
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
        RuleSource.values.byName(key): _sourceRef(value as Map<String, dynamic>),
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

  static FoodRule _rule(Map<String, dynamic> json) => FoodRule(
    kind: RuleKind.values.byName(json['kind'] as String),
    untilMonths: json['untilMonths'] as int?,
    sources: _sources(json['sources']),
    text: json['text'] as String,
  );
}
```

`data/data_sources/catalog_asset_data_source.dart` :

```dart
import 'dart:convert';

import 'package:flutter/services.dart';

/// Lit le JSON du catalogue embarqué.
class CatalogAssetDataSource {
  const CatalogAssetDataSource(this._bundle);

  /// Chemin déclaré dans `pubspec.yaml`.
  static const path = 'assets/diversification/catalogue.json';

  final AssetBundle _bundle;

  Future<Map<String, dynamic>> load() async =>
      jsonDecode(await _bundle.loadString(path, cache: false))
          as Map<String, dynamic>;
}
```

`data/repositories/asset_food_catalog_repository.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/diversification/data/data_sources/catalog_asset_data_source.dart';
import 'package:colette/features/diversification/data/dtos/food_catalog_dto.dart';
import 'package:colette/features/diversification/domain/entities/food_catalog.dart';
import 'package:colette/features/diversification/domain/repositories/food_catalog_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Catalogue lu depuis l'asset JSON.
class AssetFoodCatalogRepository implements FoodCatalogRepository {
  const AssetFoodCatalogRepository(this._source);

  final CatalogAssetDataSource _source;

  @override
  Future<Either<Failure, FoodCatalog>> load() =>
      guard(() async => FoodCatalogDto.fromJson(await _source.load()));
}
```

- [x] **Step 5 : Vérifier le succès**

Run: `flutter test test/features/diversification/data`
Expected: PASS.

- [x] **Step 6 : Commit**

```bash
dart format lib test && dart analyze
git add lib/features/diversification/domain/repositories/food_catalog_repository.dart lib/features/diversification/data test/features/diversification/helpers test/features/diversification/data
git commit -m "feat: lecture du catalogue d'aliments embarqué

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7 : Contenu — `catalogue.json` et test de validation

**Cette tâche est rédigée par le coordinateur (contenu médical), pas par un sous-agent.**

**Files:**
- Create: `assets/diversification/catalogue.json`
- Modify: `pubspec.yaml` (section `flutter:`)
- Test: `test/features/diversification/data/catalogue_content_test.dart`

- [x] **Step 1 : Test de validation (rouge)**

`test/features/diversification/data/catalogue_content_test.dart` :

```dart
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
    expect(File('pubspec.yaml').readAsStringSync(), contains('assets/diversification/'));
  });

  test('environ 110 aliments, chaque groupe représenté', () {
    expect(catalog.foods.length, inInclusiveRange(100, 140));
    for (final group in FoodGroup.values) {
      expect(catalog.foods.where((f) => f.group == group), isNotEmpty, reason: '$group');
    }
  });

  test('ids uniques au format slug', () {
    final ids = catalog.foods.map((f) => f.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    for (final id in ids) {
      expect(RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$').hasMatch(id), isTrue, reason: id);
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
          expect(catalog.sources.keys, contains(source), reason: '${food.id} $source');
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
    expect(catalog.guide.phases.keys.toSet(), DiversificationPhase.values.toSet());
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

  test('interdits clés présents avec la règle attendue', () {
    FoodRule strictestAvoid(String id) => catalog.foods
        .firstWhere((f) => f.id == id)
        .rules
        .where((r) => r.kind == RuleKind.avoid)
        .reduce((a, b) => a.untilMonths! >= b.untilMonths! ? a : b);
    expect(strictestAvoid('miel').untilMonths, 12);
    expect(strictestAvoid('miel').sources, containsAll([RuleSource.oms, RuleSource.anses]));
    expect(strictestAvoid('lait-de-vache').untilMonths, 12);
    expect(strictestAvoid('oeuf-cru').untilMonths, 72);
    expect(strictestAvoid('fromage-lait-cru').untilMonths, 60);
    expect(strictestAvoid('fruits-a-coque-entiers').untilMonths, 60);
    expect(strictestAvoid('sel').untilMonths, 36);
  });
}
```

Run: `flutter test test/features/diversification/data/catalogue_content_test.dart`
Expected: FAIL (fichier absent).

- [x] **Step 2 : Déclarer l'asset**

Dans `pubspec.yaml`, section `flutter:` (après `uses-material-design: true`) :

```yaml
  assets:
    - assets/diversification/
```

- [x] **Step 3 : Rédiger `assets/diversification/catalogue.json`**

Structure : celle de la fixture de la tâche 6, avec `"reviewedAt": "2026-09-23"` et les sources de la spec §5.1 (`oms`, `anses`, `spf`, `espghan`, `agriculture`, `efsa`, avec leurs URL).

**Guide** (textes à reprendre tels quels) :

| Clé | `mealsSummary` | Items (texte → sources) |
| --- | --- | --- |
| `preparation` | `Lait uniquement` | « L'OMS recommande le lait seul jusqu'à 6 mois, puis des aliments en complément du lait. » → oms · « En France, la diversification peut commencer entre 4 et 6 mois révolus, jamais avant 4 mois. » → anses, spf · « Prématuré : demander l'avis du pédiatre pour le bon moment. » → spf |
| `months6To8` | `2 à 3 repas` | « 2 à 3 repas par jour en plus du lait, et 1 à 2 collations selon l'appétit. » → oms · « Textures : bouillie épaisse, aliments bien écrasés, puis plats familiaux écrasés. » → oms · « Commencer par 2 à 3 cuillères, jusqu'à un demi-bol de 250 ml. » → oms · « Vers 8 mois : aliments hachés ou écrasés grossièrement, morceaux très fondants. » → spf · « Au moins 500 ml de lait maternel ou infantile par jour jusqu'à 1 an. » → anses · « Viande, poisson ou œuf : environ 10 g par jour. » → anses · « Ajouter une cuillère à café d'huile (colza, noix, olive en alternance) ou une noisette de beurre. » → anses, spf |
| `months9To11` | `3 à 4 repas` | « 3 à 4 repas par jour et 1 à 2 collations. » → oms · « Textures : haché fin, écrasé, aliments à prendre avec les doigts. » → oms · « Un demi-bol de 250 ml par repas. » → oms · « Des morceaux à croquer et à mâcher dès 10 mois ; ne pas dépasser 10 mois pour les textures non lisses. » → spf, anses |
| `months12To23` | `3 à 4 repas` | « 3 à 4 repas par jour et 1 à 2 collations. » → oms · « Plats familiaux, hachés ou écrasés si besoin. » → oms · « Trois quarts à un bol de 250 ml par repas. » → oms · « Dès 1 an : 3 repas et un goûter. » → spf · « Viande, poisson ou œuf : environ 20 g par jour. » → anses · « Lait : environ 500 ml par jour, pas plus de 800 ml. » → spf, anses |

- `readinessSigns` : « Tient sa tête et son dos bien droits. » · « Avale bien les purées lisses. » · « Attrape les aliments et les porte à sa bouche. » · « Fait des mouvements de mâchonnement. » → spf pour chacun.
- `hungerSigns` : « Pleure ou s'agite. » · « Ouvre la bouche à l'approche de la cuillère. » → spf.
- `satietySigns` : « Ralentit, tourne la tête, regarde ailleurs. » · « Ferme la bouche ou repousse la cuillère. » → spf.
- `safety` : « Proposer sans jamais forcer, ne pas obliger à finir. » → oms, spf · « Toujours assis et surveillé pendant tout le repas. » → spf · « Pas d'écran pendant le repas, pas d'aliment en récompense. » → spf · « Aliments petits, durs et ronds (fruits à coque entiers, cacahuètes) : jamais avant 5 ans. » → spf · « Couper en deux ou en quatre les aliments ronds et mous (raisin, tomate cerise), retirer pépins et noyaux. » → spf · « Présenter un nouvel aliment seul, pour qu'elle en découvre le goût. Un refus n'est pas une allergie : reproposer jusqu'à 8 à 10 fois. » → spf, anses · « Ne pas retarder l'œuf, l'arachide, le gluten et le lait, même en cas de terrain allergique. » → anses, espghan.

**Aliments** (`id` · nom · groupe · allergènes · règles). Règles réutilisées :

- `CRU36` : `avoid` 36, anses, « Cru ou peu cuit : risque de bactéries (Listeria, E. coli…). Bien cuire à cœur avant 3 ans. »
- `PREP_ROND` : `prepare` 60, spf, « Aliment rond : couper en quatre dans la longueur, retirer pépins ou noyau. »
- `PREP_POUDRE` : `prepare` 60, spf, « Jamais entier avant 5 ans : en poudre ou en purée lisse, mélangé à une purée. »
- `ALLERGENE_TOT` : `info`, anses, spf, « Allergène à ne pas retarder : à proposer dès le début de la diversification. »
- `GRAS` : `info`, anses, spf, « Matière grasse à ajouter aux repas : une cuillère à café d'huile ou une noisette de beurre. »
- `PREDATEUR` : `info`, anses, « Grand prédateur, riche en mercure : à limiter avant 3 ans. »
- `LEGUME_FEUILLE` : `info`, efsa, « Riche en nitrates : ne pas garder cuit à température ambiante, éviter en cas d'infection digestive. »

1. `grainsRootsTubers` (12) : `pates` Pâtes [gluten] ALLERGENE_TOT · `semoule` Semoule de blé [gluten] · `pain` Pain [gluten] + `info` spf « Proposer en morceaux mous ; retirer un quignon trop imbibé de salive. » · `riz` Riz · `pomme-de-terre` Pomme de terre · `quinoa` Quinoa · `avoine` Flocons d'avoine [gluten] · `polenta` Polenta (maïs) · `boulgour` Boulgour [gluten] · `sarrasin` Sarrasin · `millet` Millet · `cereales-infantiles` Céréales infantiles [gluten] + `info` oms, spf « Choisir sans sucre ajouté. »
2. `legumesNutsSeeds` (13) : `lentilles` Lentilles · `pois-chiches` Pois chiches · `haricots-rouges` Haricots rouges · `pois-casses` Pois cassés · `houmous` Houmous [sesame] + `info` oms, spf « Maison sans sel ajouté. » · `arachide` Arachide (poudre, pâte) [peanut] PREP_POUDRE, ALLERGENE_TOT · `amande` Amande (poudre, purée) [treeNuts] PREP_POUDRE, ALLERGENE_TOT · `noisette` Noisette (poudre, purée) [treeNuts] PREP_POUDRE · `noix` Noix (poudre) [treeNuts] PREP_POUDRE · `cajou` Noix de cajou (purée) [treeNuts] PREP_POUDRE · `sesame` Sésame (purée, tahini) [sesame] ALLERGENE_TOT · `fruits-a-coque-entiers` Fruits à coque et cacahuètes entiers [peanut, treeNuts] `avoid` 60 spf « Risque d'étouffement : jamais entiers avant 5 ans. » + `avoid` 36 anses « Déconseillés entiers avant 3 ans (étouffement). » · `tofu` Tofu [soy] `avoid` 36 anses, spf « Produits au soja déconseillés avant 3 ans (phyto-œstrogènes). »
3. `dairy` (8) : `yaourt` Yaourt nature au lait entier [milk] `info` spf « Nature, au lait entier, sans sucre ajouté ; pas de laitage 0 %. » · `fromage-blanc` Fromage blanc [milk] · `petit-suisse` Petit-suisse [milk] · `comte` Comté, emmental, gruyère [milk] `info` agriculture « Pâtes pressées cuites : autorisées même au lait cru. » · `fromage-pasteurise` Fromage au lait pasteurisé [milk] · `fromage-lait-cru` Fromage au lait cru (hors comté, emmental…) [milk] `avoid` 60 agriculture « Risque de bactéries (E. coli, Listeria) : pas avant 5 ans. » + `avoid` 36 anses « Lait cru et fromages au lait cru déconseillés avant 3 ans. » · `lait-de-vache` Lait de vache (en boisson) [milk] `info` oms « L'OMS juge acceptable le lait entier pasteurisé dès 6 mois. » + `avoid` 12 anses, spf « Pas comme boisson principale avant 1 an : lait maternel ou infantile. Possible en petite quantité dans les préparations. » · `lait-cru` Lait cru [milk] `avoid` 60 agriculture « Pas avant 5 ans. » + `avoid` 36 anses « Déconseillé avant 3 ans. »
4. `fleshFoods` (26) : `poulet` Poulet · `dinde` Dinde · `boeuf` Bœuf · `veau` Veau · `porc` Porc · `agneau` Agneau · `jambon-blanc` Jambon blanc · `foie` Foie · `viande-crue` Viande crue ou rosée (tartare, carpaccio) CRU36 en `avoid` · `charcuterie-crue` Charcuterie crue (saucisson, jambon cru) CRU36 · `saumon` Saumon [fish] ALLERGENE_TOT · `cabillaud` Cabillaud [fish] · `colin` Colin [fish] · `sardine` Sardine [fish] · `maquereau` Maquereau [fish] · `truite` Truite [fish] · `sole` Sole [fish] · `thon` Thon [fish] PREDATEUR · `grands-predateurs` Bar, dorade, lotte, brochet, raie [fish] PREDATEUR · `espadon` Espadon, marlin, requin, lamproie [fish] `avoid` 36 anses « Très riche en mercure : à éviter avant 3 ans. » · `poisson-fume` Poisson fumé (saumon fumé…) [fish] `avoid` 36 anses « Risque de Listeria : pas avant 3 ans. » · `poisson-cru` Poisson cru (sushi, tartare) [fish] CRU36 · `poissons-eau-douce` Anguille, carpe, brème, barbeau, silure [fish] `info` anses « Riche en polluants (PCB) : au plus une fois tous les 2 mois. » · `crevettes` Crevettes cuites [crustaceans] · `moules` Moules cuites [molluscs] · `coquillages-crus` Coquillages crus (huîtres…) [molluscs] CRU36
5. `eggs` (3) : `oeuf-cuit` Œuf dur ou bien cuit [eggs] ALLERGENE_TOT · `jaune-oeuf` Jaune d'œuf cuit [eggs] · `oeuf-cru` Œuf cru ou peu cuit (mayonnaise, mousse maison, œuf coque) [eggs] `avoid` 72 anses « Risque de salmonelle : jaune et blanc bien cuits avant 6 ans. »
6. `vitaminAFruitsVeg` (12) : `carotte` Carotte · `potiron` Potiron · `butternut` Courge butternut · `patate-douce` Patate douce · `epinard` Épinard LEGUME_FEUILLE · `blette` Blette LEGUME_FEUILLE · `poivron-rouge` Poivron rouge · `mangue` Mangue · `abricot` Abricot · `melon` Melon · `papaye` Papaye · `kaki` Kaki
7. `otherFruitsVeg` (34) : `courgette` Courgette · `haricots-verts` Haricots verts · `petits-pois` Petits pois · `brocoli` Brocoli · `chou-fleur` Chou-fleur · `poireau` Poireau · `panais` Panais · `navet` Navet · `betterave` Betterave · `tomate` Tomate · `tomate-cerise` Tomate cerise PREP_ROND · `concombre` Concombre · `aubergine` Aubergine · `fenouil` Fenouil · `avocat` Avocat · `artichaut` Artichaut · `celeri` Céleri [celery] · `asperge` Asperge · `champignon` Champignon · `pomme` Pomme · `poire` Poire · `banane` Banane · `peche` Pêche · `prune` Prune · `fraise` Fraise · `framboise` Framboise · `myrtille` Myrtille PREP_ROND · `raisin` Raisin PREP_ROND · `clementine` Clémentine · `kiwi` Kiwi · `cerise` Cerise PREP_ROND · `ananas` Ananas · `pasteque` Pastèque · `figue` Figue
8. `outsideGroups` (14) : `huile-colza` Huile de colza GRAS · `huile-olive` Huile d'olive GRAS · `huile-noix` Huile de noix GRAS · `beurre` Beurre [milk] GRAS · `creme-fraiche` Crème fraîche [milk] · `miel` Miel `avoid` 12 oms, anses « Risque de botulisme infantile, même cuit ou dans une préparation. » · `sel` Sel ajouté `avoid` 36 spf, oms « Ne pas saler les plats avant 3 ans. » · `sucre` Sucre ajouté, confiseries, édulcorants `avoid` 36 oms, spf « Pas de sucre ajouté ni d'édulcorant avant 3 ans. » · `boissons-sucrees` Boissons sucrées, sodas `avoid` 36 oms, spf « À proscrire : l'eau est la seule boisson à proposer en plus du lait. » · `jus-de-fruits` Jus de fruits `info` oms, spf « Pas recommandé, même 100 % pur jus : préférer le fruit entier et l'eau. » · `the-cafe` Thé, café `avoid` 36 anses « Caféine et théine : pas avant 3 ans. » · `chocolat` Chocolat `info` anses « À limiter avant 3 ans (nickel, sucre). » · `boisson-vegetale` Boisson végétale (soja, amande, avoine, riz) `avoid` 12 anses, spf « Ne remplace pas le lait maternel ou infantile avant 1 an : risque de carences. » · `herbes` Herbes aromatiques

Chaque aliment sans règle omet `rules` ; sans allergène, omet `allergens`.

- [x] **Step 4 : Vérifier le succès**

Run: `flutter test test/features/diversification/data`
Expected: PASS.

- [x] **Step 5 : Commit**

```bash
git add assets/diversification/catalogue.json pubspec.yaml test/features/diversification/data/catalogue_content_test.dart
git commit -m "feat: catalogue d'aliments sourcé OMS, Anses et SPF

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8 : Data — dégustations et aliments perso dans Firestore

**Files:**
- Modify: `lib/core/firebase/firestore_paths.dart`
- Modify: `firestore.rules` (commentaire)
- Create: `lib/features/diversification/domain/repositories/tastings_repository.dart`
- Create: `lib/features/diversification/domain/repositories/custom_foods_repository.dart`
- Create: `lib/features/diversification/data/dtos/tasting_dto.dart`
- Create: `lib/features/diversification/data/dtos/custom_food_dto.dart`
- Create: `lib/features/diversification/data/repositories/firestore_tastings_repository.dart`
- Create: `lib/features/diversification/data/repositories/firestore_custom_foods_repository.dart`
- Test: `test/features/diversification/data/firestore_tastings_repository_test.dart`
- Test: `test/features/diversification/data/firestore_custom_foods_repository_test.dart`

- [x] **Step 1 : Tests rouges**

`firestore_tastings_repository_test.dart` :

```dart
import 'package:colette/features/diversification/data/repositories/firestore_tastings_repository.dart';
import 'package:colette/features/diversification/domain/entities/liking.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const code = 'ABCDEFGH';
  late FakeFirebaseFirestore db;
  late FirestoreTastingsRepository repo;

  CollectionReference<Map<String, dynamic>> tastings() =>
      db.collection('households').doc(code).collection('tastings');

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreTastingsRepository(db);
  });

  final full = Tasting(
    id: 't1',
    foodId: 'carotte',
    at: DateTime(2027, 4, 10, 12, 5),
    liking: Liking.loved,
    hadReaction: true,
    note: 'Rougeurs',
  );

  test('save puis watchAll : aller-retour complet', () async {
    await repo.save(code, full);
    expect(await repo.watchAll(code).first, [full]);
  });

  test('champs optionnels absents du document', () async {
    await repo.save(code, Tasting(id: 't2', foodId: 'miel', at: DateTime(2027, 4, 10)));
    final data = (await tastings().doc('t2').get()).data()!;
    expect(data.containsKey('liking'), isFalse);
    expect(data.containsKey('note'), isFalse);
    expect(data['hadReaction'], isFalse);
    expect(data['at'], isA<Timestamp>());
  });

  test('save remplace : retirer l\'appréciation l\'efface', () async {
    await repo.save(code, full);
    await repo.save(code, full.copyWith(liking: null));
    expect((await repo.watchAll(code).first).single.liking, isNull);
  });

  test('tri par at décroissant', () async {
    await repo.save(code, full.copyWith(id: 'a', at: DateTime(2027, 4, 1)));
    await repo.save(code, full.copyWith(id: 'b', at: DateTime(2027, 4, 3)));
    expect((await repo.watchAll(code).first).map((t) => t.id), ['b', 'a']);
  });

  test('lecture tolérante : liking inconnu, document invalide ignoré', () async {
    await tastings().doc('x').set({
      'foodId': 'carotte',
      'at': Timestamp.fromDate(DateTime(2027, 4, 2)),
      'liking': 'adored',
    });
    await tastings().doc('y').set({'foodId': 'carotte', 'at': 'hier'});
    final list = await repo.watchAll(code).first;
    expect(list.single.id, 'x');
    expect(list.single.liking, isNull);
    expect(list.single.hadReaction, isFalse);
  });

  test('delete', () async {
    await repo.save(code, full);
    await repo.delete(code, 't1');
    expect(await repo.watchAll(code).first, isEmpty);
  });
}
```

`firestore_custom_foods_repository_test.dart` :

```dart
import 'package:colette/features/diversification/data/repositories/firestore_custom_foods_repository.dart';
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const code = 'ABCDEFGH';
  late FakeFirebaseFirestore db;
  late FirestoreCustomFoodsRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreCustomFoodsRepository(db);
  });

  const kaki = Food(
    id: 'c1',
    name: 'Kaki séché',
    group: FoodGroup.vitaminAFruitsVeg,
    allergens: {Allergen.sulphites},
    isCustom: true,
  );

  test('save puis watchAll', () async {
    await repo.save(code, kaki);
    expect(await repo.watchAll(code).first, [kaki]);
  });

  test('lecture tolérante : groupe et allergène inconnus, nom vide ignoré', () async {
    final foods = db.collection('households').doc(code).collection('customFoods');
    await foods.doc('a').set({'name': 'Datte', 'group': 'fruits', 'allergens': ['milk', 'nuts']});
    await foods.doc('b').set({'name': '  ', 'group': 'dairy'});
    final list = await repo.watchAll(code).first;
    expect(list.single.name, 'Datte');
    expect(list.single.group, FoodGroup.outsideGroups);
    expect(list.single.allergens, {Allergen.milk});
    expect(list.single.isCustom, isTrue);
  });

  test('delete', () async {
    await repo.save(code, kaki);
    await repo.delete(code, 'c1');
    expect(await repo.watchAll(code).first, isEmpty);
  });
}
```

- [x] **Step 2 : Vérifier l'échec**

Run: `flutter test test/features/diversification/data`
Expected: FAIL.

- [x] **Step 3 : Implémentation**

`lib/core/firebase/firestore_paths.dart` : ajouter

```dart
  static const tastings = 'tastings';
  static const customFoods = 'customFoods';
```

`firestore.rules` : remplacer le commentaire `// Sous-collections : events, weights, devices.` par `// Sous-collections : events, weights, devices, tastings, customFoods.`

`domain/repositories/tastings_repository.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:fpdart/fpdart.dart';

/// Dégustations d'un foyer.
abstract interface class TastingsRepository {
  /// Toutes les dégustations, de la plus récente à la plus ancienne.
  Stream<List<Tasting>> watchAll(String householdCode);

  /// Crée ou remplace la dégustation (clé : `tasting.id`).
  Future<Either<Failure, void>> save(String householdCode, Tasting tasting);

  Future<Either<Failure, void>> delete(String householdCode, String tastingId);
}
```

`domain/repositories/custom_foods_repository.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:fpdart/fpdart.dart';

/// Aliments ajoutés par le foyer.
abstract interface class CustomFoodsRepository {
  Stream<List<Food>> watchAll(String householdCode);

  /// Crée ou remplace l'aliment (clé : `food.id`).
  Future<Either<Failure, void>> save(String householdCode, Food food);

  Future<Either<Failure, void>> delete(String householdCode, String foodId);
}
```

`data/dtos/tasting_dto.dart` :

```dart
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/diversification/domain/entities/liking.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';

/// Conversion `Tasting` ↔ document `tastings/{id}`.
abstract final class TastingDto {
  static Map<String, dynamic> toMap(Tasting tasting) => {
    'foodId': tasting.foodId,
    'at': Timestamp.fromDate(tasting.at),
    if (tasting.liking case final liking?) 'liking': liking.name,
    'hadReaction': tasting.hadReaction,
    if (tasting.note?.trim() case final note? when note.isNotEmpty)
      'note': note,
  };

  /// `null` (journalisé) si `foodId` ou `at` sont invalides ; `liking` inconnu lu `null`.
  static Tasting? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final foodId = data?['foodId'];
    final at = data?['at'];
    if (data == null ||
        foodId is! String ||
        foodId.isEmpty ||
        at is! Timestamp) {
      developer.log('Dégustation ${doc.id} ignorée', name: 'colette');
      return null;
    }
    final note = data['note'];
    return Tasting(
      id: doc.id,
      foodId: foodId,
      at: at.toDate(),
      liking: Liking.values.asNameMap()[data['liking']],
      hadReaction: data['hadReaction'] == true,
      note: note is String && note.isNotEmpty ? note : null,
    );
  }
}
```

`data/dtos/custom_food_dto.dart` :

```dart
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';

/// Conversion aliment perso ↔ document `customFoods/{id}`.
abstract final class CustomFoodDto {
  static Map<String, dynamic> toMap(Food food) => {
    'name': food.name,
    'group': food.group.name,
    'allergens': [for (final allergen in food.allergens) allergen.name],
  };

  /// `null` (journalisé) sans nom ; groupe inconnu lu « hors groupes »,
  /// allergènes inconnus ignorés.
  static Food? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final name = data?['name'];
    if (data == null || name is! String || name.trim().isEmpty) {
      developer.log('Aliment perso ${doc.id} ignoré', name: 'colette');
      return null;
    }
    final allergens = data['allergens'];
    return Food(
      id: doc.id,
      name: name.trim(),
      group:
          FoodGroup.values.asNameMap()[data['group']] ?? FoodGroup.outsideGroups,
      allergens: {
        if (allergens is List)
          for (final value in allergens)
            if (Allergen.values.asNameMap()[value] case final allergen?)
              allergen,
      },
      isCustom: true,
    );
  }
}
```

`data/repositories/firestore_tastings_repository.dart` :

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/firebase/firestore_paths.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/diversification/data/dtos/tasting_dto.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/domain/repositories/tastings_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Dégustations dans `households/{code}/tastings`.
class FirestoreTastingsRepository implements TastingsRepository {
  FirestoreTastingsRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _tastings(String code) => _db
      .collection(FirestorePaths.households)
      .doc(code)
      .collection(FirestorePaths.tastings);

  @override
  Stream<List<Tasting>> watchAll(String householdCode) =>
      _tastings(householdCode)
          .orderBy('at', descending: true)
          .snapshots()
          .map((snap) => [for (final doc in snap.docs) ?TastingDto.fromDoc(doc)]);

  @override
  Future<Either<Failure, void>> save(String householdCode, Tasting tasting) =>
      guard(
        () => _tastings(householdCode)
            .doc(tasting.id)
            .set(TastingDto.toMap(tasting)),
      );

  @override
  Future<Either<Failure, void>> delete(String householdCode, String tastingId) =>
      guard(() => _tastings(householdCode).doc(tastingId).delete());
}
```

`data/repositories/firestore_custom_foods_repository.dart` :

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/firebase/firestore_paths.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/diversification/data/dtos/custom_food_dto.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/repositories/custom_foods_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Aliments perso dans `households/{code}/customFoods`.
class FirestoreCustomFoodsRepository implements CustomFoodsRepository {
  FirestoreCustomFoodsRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _foods(String code) => _db
      .collection(FirestorePaths.households)
      .doc(code)
      .collection(FirestorePaths.customFoods);

  @override
  Stream<List<Food>> watchAll(String householdCode) => _foods(householdCode)
      .snapshots()
      .map((snap) => [for (final doc in snap.docs) ?CustomFoodDto.fromDoc(doc)]);

  @override
  Future<Either<Failure, void>> save(String householdCode, Food food) => guard(
    () => _foods(householdCode).doc(food.id).set(CustomFoodDto.toMap(food)),
  );

  @override
  Future<Either<Failure, void>> delete(String householdCode, String foodId) =>
      guard(() => _foods(householdCode).doc(foodId).delete());
}
```

- [x] **Step 4 : Vérifier le succès**

Run: `flutter test test/features/diversification/data`
Expected: PASS.

- [x] **Step 5 : Commit**

```bash
dart format lib test && dart analyze
git add lib/core/firebase/firestore_paths.dart firestore.rules lib/features/diversification/domain/repositories lib/features/diversification/data test/features/diversification/data
git commit -m "feat: dégustations et aliments perso dans Firestore

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9 : Providers — sources, fusion et indicateurs dérivés

**Files:**
- Create: `lib/features/diversification/presentation/providers/diversification_providers.dart`
- Create: `lib/features/diversification/presentation/providers/diversification_overview_providers.dart`
- Create: `lib/features/diversification/presentation/providers/catalog_filter.dart`
- Test: `test/features/diversification/presentation/diversification_providers_test.dart`

- [x] **Step 1 : Tests rouges**

`diversification_providers_test.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/allergen_state.dart';
import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_filter.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/food_status.dart';
import 'package:colette/features/diversification/domain/entities/liking.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/presentation/providers/catalog_filter.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_overview_providers.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/catalog_fixture.dart';

void main() {
  final now = DateTime(2027, 4, 10, 18);
  const kaki = Food(id: 'c1', name: 'Kaki', group: FoodGroup.vitaminAFruitsVeg, isCustom: true);
  final tastings = [
    Tasting(id: '1', foodId: 'carotte', at: DateTime(2027, 4, 10, 12), liking: Liking.loved),
    Tasting(id: '2', foodId: 'oeuf-cuit', at: DateTime(2027, 4, 10, 8), hadReaction: true),
    Tasting(id: '3', foodId: 'brocoli', at: DateTime(2027, 4, 9), liking: Liking.refused),
    Tasting(id: '4', foodId: 'carotte', at: DateTime(2027, 4, 2)),
  ];

  Future<ProviderContainer> container({BabyProfile? profile}) async {
    final c = ProviderContainer(
      overrides: [
        foodCatalogProvider.overrideWith((ref) async => catalogFixture()),
        customFoodsProvider.overrideWith((ref) => Stream.value(const [kaki])),
        tastingsProvider.overrideWith((ref) => Stream.value(tastings)),
        babyProfileProvider.overrideWith((ref) => Stream.value(profile)),
        clockProvider.overrideWithValue(FixedClock(now)),
        minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
      ],
    );
    addTearDown(c.dispose);
    // Garde les providers autoDispose en vie et attend les premières valeurs.
    c.listen(foodsProvider, (_, _) {});
    c.listen(diversificationTimelineProvider, (_, _) {});
    await c.read(foodCatalogProvider.future);
    await c.read(customFoodsProvider.future);
    await c.read(tastingsProvider.future);
    await c.read(babyProfileProvider.future);
    return c;
  }

  final profile = BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 15));

  test('foods fusionne catalogue et aliments perso', () async {
    final c = await container();
    final foods = c.read(foodsProvider).value!;
    expect(foods, hasLength(9));
    expect(foods['c1'], kaki);
    expect(foods['miel']?.isCustom, isFalse);
  });

  test('timeline : null sans profil, phase selon l\'âge sinon', () async {
    expect((await container()).read(diversificationTimelineProvider), isNull);
    final c = await container(profile: profile);
    final timeline = c.read(diversificationTimelineProvider)!;
    expect(timeline.phase, DiversificationPhase.months6To8);
    expect(timeline.ageMonths, 6);
  });

  test('indicateurs dérivés', () async {
    final c = await container(profile: profile);
    expect(c.read(tastingCountsProvider), {'carotte': 2, 'oeuf-cuit': 1, 'brocoli': 1});
    expect(c.read(dailyDiversityProvider).coveredGroups, {FoodGroup.vitaminAFruitsVeg, FoodGroup.eggs});
    expect(c.read(allergenProgressProvider)[Allergen.eggs], AllergenState.reaction);
    expect(c.read(foodsToRetryProvider).single.food.id, 'brocoli');
    expect(c.read(tastingsForFoodProvider('carotte')).map((t) => t.id), ['1', '4']);
  });

  test('statuts selon l\'âge', () async {
    final c = await container(profile: profile);
    final statuses = c.read(foodStatusesProvider);
    expect(statuses['miel'], isA<FoodStatusAvoid>());
    expect(statuses['carotte'], const FoodStatus.tasted(count: 2, needsPreparation: false));
    expect(statuses['c1'], const FoodStatus.notTasted(needsPreparation: false));
  });

  test('catalogue filtré selon CatalogFilter', () async {
    final c = await container(profile: profile);
    c.listen(filteredCatalogProvider, (_, _) {});
    expect(c.read(filteredCatalogProvider).expand((s) => s.foods), hasLength(9));
    c.read(catalogFilterProvider.notifier).setAllergen(Allergen.eggs);
    expect(c.read(filteredCatalogProvider).single.foods.single.id, 'oeuf-cuit');
    c.read(catalogFilterProvider.notifier)
      ..setAllergen(null)
      ..setMode(CatalogMode.avoid);
    expect(
      c.read(filteredCatalogProvider).expand((s) => s.foods).map((f) => f.id),
      unorderedEquals(['miel', 'lait-de-vache']),
    );
    c.read(catalogFilterProvider.notifier)
      ..setMode(CatalogMode.all)
      ..setQuery('kak');
    expect(c.read(filteredCatalogProvider).single.foods.single, kaki);
  });

  test('erreur du catalogue propagée par foods', () async {
    final c = ProviderContainer(
      overrides: [
        foodCatalogProvider.overrideWith((ref) async => throw StateError('KO')),
        customFoodsProvider.overrideWith((ref) => Stream.value(const [])),
      ],
    );
    addTearDown(c.dispose);
    c.listen(foodsProvider, (_, _) {});
    await expectLater(c.read(foodCatalogProvider.future), throwsStateError);
    await c.read(customFoodsProvider.future);
    expect(c.read(foodsProvider), isA<AsyncError<Map<String, Food>>>());
  });
}
```

- [x] **Step 2 : Vérifier l'échec**

Run: `flutter test test/features/diversification/presentation/diversification_providers_test.dart`
Expected: FAIL.

- [x] **Step 3 : Implémentation**

`diversification_providers.dart` :

```dart
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/result/no_retry.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/diversification/data/data_sources/catalog_asset_data_source.dart';
import 'package:colette/features/diversification/data/repositories/asset_food_catalog_repository.dart';
import 'package:colette/features/diversification/data/repositories/firestore_custom_foods_repository.dart';
import 'package:colette/features/diversification/data/repositories/firestore_tastings_repository.dart';
import 'package:colette/features/diversification/domain/entities/diversification_timeline.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_catalog.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/domain/repositories/custom_foods_repository.dart';
import 'package:colette/features/diversification/domain/repositories/food_catalog_repository.dart';
import 'package:colette/features/diversification/domain/repositories/tastings_repository.dart';
import 'package:colette/features/diversification/domain/use_cases/compute_diversification_phase.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'diversification_providers.g.dart';

/// Sans état et partagé : `keepAlive`.
@Riverpod(keepAlive: true)
FoodCatalogRepository foodCatalogRepository(Ref ref) =>
    AssetFoodCatalogRepository(CatalogAssetDataSource(rootBundle));

/// Sans état et partagé : `keepAlive`.
@Riverpod(keepAlive: true)
TastingsRepository tastingsRepository(Ref ref) =>
    FirestoreTastingsRepository(ref.watch(firestoreProvider));

/// Sans état et partagé : `keepAlive`.
@Riverpod(keepAlive: true)
CustomFoodsRepository customFoodsRepository(Ref ref) =>
    FirestoreCustomFoodsRepository(ref.watch(firestoreProvider));

/// Catalogue embarqué, chargé une fois ; la `Failure` éventuelle devient l'erreur.
@Riverpod(keepAlive: true, retry: noRetry)
Future<FoodCatalog> foodCatalog(Ref ref) async {
  final result = await ref.watch(foodCatalogRepositoryProvider).load();
  return result.fold((failure) => throw failure, (catalog) => catalog);
}

/// Dégustations du foyer courant, de la plus récente à la plus ancienne.
@Riverpod(retry: noRetry)
Stream<List<Tasting>> tastings(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(const []);
  return ref.watch(tastingsRepositoryProvider).watchAll(code);
}

/// Aliments perso du foyer courant.
@Riverpod(retry: noRetry)
Stream<List<Food>> customFoods(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(const []);
  return ref.watch(customFoodsRepositoryProvider).watchAll(code);
}

/// Catalogue et aliments perso indexés par id ; en erreur si l'une des sources l'est.
@riverpod
AsyncValue<Map<String, Food>> foods(Ref ref) =>
    switch ((ref.watch(foodCatalogProvider), ref.watch(customFoodsProvider))) {
      (AsyncError(:final error, :final stackTrace), _) ||
      (_, AsyncError(:final error, :final stackTrace)) => AsyncError(
        error,
        stackTrace,
      ),
      (AsyncData(value: final catalog), AsyncData(value: final custom)) =>
        AsyncData({
          for (final food in catalog.foods) food.id: food,
          for (final food in custom) food.id: food,
        }),
      _ => const AsyncLoading(),
    };

/// Phase et âge de diversification ; `null` sans profil.
@riverpod
DiversificationTimeline? diversificationTimeline(Ref ref) {
  final profile = ref.watch(babyProfileProvider).value;
  if (profile == null) return null;
  return const ComputeDiversificationPhase()(
    birthDate: profile.birthDate,
    now: ref.watch(todayProvider),
  );
}
```

`diversification_overview_providers.dart` :

```dart
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/allergen_state.dart';
import 'package:colette/features/diversification/domain/entities/daily_diversity.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group_section.dart';
import 'package:colette/features/diversification/domain/entities/food_status.dart';
import 'package:colette/features/diversification/domain/entities/retry_item.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/domain/use_cases/compute_allergen_progress.dart';
import 'package:colette/features/diversification/domain/use_cases/compute_daily_diversity.dart';
import 'package:colette/features/diversification/domain/use_cases/compute_food_status.dart';
import 'package:colette/features/diversification/domain/use_cases/compute_foods_to_retry.dart';
import 'package:colette/features/diversification/domain/use_cases/filter_foods.dart';
import 'package:colette/features/diversification/presentation/providers/catalog_filter.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'diversification_overview_providers.g.dart';

List<Tasting> _tastings(Ref ref) =>
    ref.watch(tastingsProvider).value ?? const <Tasting>[];

Map<String, Food> _foods(Ref ref) =>
    ref.watch(foodsProvider).value ?? const <String, Food>{};

/// Nombre de dégustations par aliment.
@riverpod
Map<String, int> tastingCounts(Ref ref) {
  final counts = <String, int>{};
  for (final tasting in _tastings(ref)) {
    counts[tasting.foodId] = (counts[tasting.foodId] ?? 0) + 1;
  }
  return counts;
}

/// Dégustations d'un aliment, de la plus récente à la plus ancienne.
@riverpod
List<Tasting> tastingsForFood(Ref ref, String foodId) => [
  for (final tasting in _tastings(ref))
    if (tasting.foodId == foodId) tasting,
];

/// Groupes OMS couverts aujourd'hui.
@riverpod
DailyDiversity dailyDiversity(Ref ref) => const ComputeDailyDiversity()(
  tastings: _tastings(ref),
  foodsById: _foods(ref),
  now: ref.watch(currentMinuteProvider),
);

/// État des 9 allergènes suivis.
@riverpod
Map<Allergen, AllergenState> allergenProgress(Ref ref) =>
    const ComputeAllergenProgress()(
      tastings: _tastings(ref),
      foodsById: _foods(ref),
    );

/// Aliments à reproposer.
@riverpod
List<RetryItem> foodsToRetry(Ref ref) => const ComputeFoodsToRetry()(
  tastings: _tastings(ref),
  foodsById: _foods(ref),
);

/// Statut de chaque aliment pour l'âge courant (sans âge si pas de profil).
@riverpod
Map<String, FoodStatus> foodStatuses(Ref ref) {
  final ageMonths = ref.watch(diversificationTimelineProvider)?.ageMonths;
  final counts = ref.watch(tastingCountsProvider);
  return {
    for (final food in _foods(ref).values)
      food.id: const ComputeFoodStatus()(
        food: food,
        ageMonths: ageMonths,
        tastingCount: counts[food.id] ?? 0,
      ),
  };
}

/// Catalogue filtré par [CatalogFilter], groupé par groupe OMS.
@riverpod
List<FoodGroupSection> filteredCatalog(Ref ref) => const FilterFoods()(
  foods: _foods(ref).values,
  filter: ref.watch(catalogFilterProvider),
  statuses: ref.watch(foodStatusesProvider),
  tastingCounts: ref.watch(tastingCountsProvider),
);
```

`catalog_filter.dart` :

```dart
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/food_filter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'catalog_filter.g.dart';

/// Recherche et filtres du catalogue, partagés entre la carte Allergènes et la liste.
@riverpod
class CatalogFilter extends _$CatalogFilter {
  @override
  FoodFilter build() => const FoodFilter();

  void setQuery(String query) => state = state.copyWith(query: query);

  void setMode(CatalogMode mode) => state = state.copyWith(mode: mode);

  void setAllergen(Allergen? allergen) =>
      state = state.copyWith(allergen: allergen);
}
```

- [x] **Step 4 : Génération et vérification**

Run: `dart run build_runner build -d && flutter test test/features/diversification/presentation/diversification_providers_test.dart`
Expected: PASS. Si `dart analyze` (riverpod_lint) signale une dépendance manquante ou un `ref` mal utilisé, corriger selon le message.

- [x] **Step 5 : Commit**

```bash
dart format lib test && dart analyze
git add lib/features/diversification/presentation/providers test/features/diversification/presentation/diversification_providers_test.dart
git commit -m "feat: providers de la diversification et indicateurs dérivés

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 10 : Contrôleurs — dégustation et aliment perso

**Files:**
- Create: `lib/features/diversification/presentation/providers/tasting_form_controller.dart`
- Create: `lib/features/diversification/presentation/providers/custom_food_controller.dart`
- Test: `test/features/diversification/presentation/diversification_controllers_test.dart`

- [x] **Step 1 : Tests rouges**

`diversification_controllers_test.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/domain/repositories/custom_foods_repository.dart';
import 'package:colette/features/diversification/domain/repositories/tastings_repository.dart';
import 'package:colette/features/diversification/presentation/providers/custom_food_controller.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:colette/features/diversification/presentation/providers/tasting_form_controller.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../helpers/catalog_fixture.dart';

class MockTastingsRepository extends Mock implements TastingsRepository {}

class MockCustomFoodsRepository extends Mock implements CustomFoodsRepository {}

void main() {
  const code = 'ABCDEFGH';
  final now = DateTime(2027, 4, 10, 18);
  late MockTastingsRepository tastingsRepo;
  late MockCustomFoodsRepository foodsRepo;
  late ProviderContainer container;
  const kaki = Food(id: 'c1', name: 'Kaki', group: FoodGroup.vitaminAFruitsVeg, isCustom: true);

  setUpAll(() {
    registerFallbackValue(Tasting(id: '', foodId: '', at: DateTime(2000)));
    registerFallbackValue(kaki);
  });

  setUp(() async {
    tastingsRepo = MockTastingsRepository();
    foodsRepo = MockCustomFoodsRepository();
    when(() => tastingsRepo.save(any(), any())).thenAnswer((_) async => right(null));
    when(() => tastingsRepo.delete(any(), any())).thenAnswer((_) async => right(null));
    when(() => foodsRepo.save(any(), any())).thenAnswer((_) async => right(null));
    when(() => foodsRepo.delete(any(), any())).thenAnswer((_) async => right(null));
    container = ProviderContainer(
      overrides: [
        tastingsRepositoryProvider.overrideWithValue(tastingsRepo),
        customFoodsRepositoryProvider.overrideWithValue(foodsRepo),
        clockProvider.overrideWithValue(FixedClock(now)),
        idGeneratorProvider.overrideWithValue(const FixedIdGenerator('new-id')),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: code),
        ),
        foodCatalogProvider.overrideWith((ref) async => catalogFixture()),
        customFoodsProvider.overrideWith((ref) => Stream.value(const [kaki])),
        tastingsProvider.overrideWith(
          (ref) => Stream.value([Tasting(id: 't1', foodId: 'c1', at: DateTime(2027, 4, 1))]),
        ),
      ],
    );
    addTearDown(container.dispose);
    container
      ..listen(foodsProvider, (_, _) {})
      ..listen(tastingFormControllerProvider, (_, _) {})
      ..listen(customFoodControllerProvider, (_, _) {});
    await container.read(foodCatalogProvider.future);
    await container.read(customFoodsProvider.future);
    await container.read(tastingsProvider.future);
  });

  group('TastingFormController', () {
    TastingFormController controller() =>
        container.read(tastingFormControllerProvider.notifier);

    test('nouvelle dégustation : id généré, note nettoyée', () async {
      final ok = await controller().save(
        Tasting(id: '', foodId: 'carotte', at: now, note: '  '),
      );
      expect(ok, isTrue);
      final saved = verify(() => tastingsRepo.save(code, captureAny())).captured.single as Tasting;
      expect(saved.id, 'new-id');
      expect(saved.note, isNull);
    });

    test('modification : id conservé', () async {
      await controller().save(Tasting(id: 't1', foodId: 'carotte', at: now, note: ' Aimé '));
      final saved = verify(() => tastingsRepo.save(code, captureAny())).captured.single as Tasting;
      expect(saved.id, 't1');
      expect(saved.note, 'Aimé');
    });

    test('date future refusée', () async {
      final ok = await controller().save(
        Tasting(id: '', foodId: 'carotte', at: now.add(const Duration(minutes: 1))),
      );
      expect(ok, isFalse);
      verifyNever(() => tastingsRepo.save(any(), any()));
      final state = container.read(tastingFormControllerProvider);
      expect((state.error! as ValidationFailure).reason, ValidationReason.startInFuture);
    });

    test('échec du repository : état en erreur', () async {
      when(() => tastingsRepo.save(any(), any())).thenAnswer((_) async => left(const NetworkFailure()));
      expect(await controller().save(Tasting(id: '', foodId: 'carotte', at: now)), isFalse);
      expect(container.read(tastingFormControllerProvider).error, isA<NetworkFailure>());
    });

    test('delete', () async {
      expect(await controller().delete('t1'), isTrue);
      verify(() => tastingsRepo.delete(code, 't1')).called(1);
    });
  });

  group('CustomFoodController', () {
    CustomFoodController controller() =>
        container.read(customFoodControllerProvider.notifier);

    test('création : id généré, nom nettoyé, marqué perso', () async {
      final ok = await controller().save(
        name: ' Datte ',
        group: FoodGroup.otherFruitsVeg,
        allergens: const {Allergen.sulphites},
      );
      expect(ok, isTrue);
      final saved = verify(() => foodsRepo.save(code, captureAny())).captured.single as Food;
      expect(saved, const Food(
        id: 'new-id',
        name: 'Datte',
        group: FoodGroup.otherFruitsVeg,
        allergens: {Allergen.sulphites},
        isCustom: true,
      ));
    });

    test('doublon avec le catalogue refusé', () async {
      final ok = await controller().save(name: 'carotte', group: FoodGroup.dairy, allergens: const {});
      expect(ok, isFalse);
      expect(
        (container.read(customFoodControllerProvider).error! as ValidationFailure).reason,
        ValidationReason.duplicateFoodName,
      );
    });

    test('renommer un aliment perso sans changer son nom n\'est pas un doublon', () async {
      final ok = await controller().save(id: 'c1', name: 'Kaki', group: FoodGroup.otherFruitsVeg, allergens: const {});
      expect(ok, isTrue);
    });

    test('suppression refusée si des dégustations existent', () async {
      expect(await controller().delete('c1'), isFalse);
      verifyNever(() => foodsRepo.delete(any(), any()));
      expect(
        (container.read(customFoodControllerProvider).error! as ValidationFailure).reason,
        ValidationReason.customFoodInUse,
      );
    });

    test('suppression sans dégustation', () async {
      expect(await controller().delete('c2'), isTrue);
      verify(() => foodsRepo.delete(code, 'c2')).called(1);
    });
  });
}
```

- [x] **Step 2 : Vérifier l'échec**

Run: `flutter test test/features/diversification/presentation/diversification_controllers_test.dart`
Expected: FAIL.

- [x] **Step 3 : Implémentation**

`tasting_form_controller.dart` :

```dart
import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tasting_form_controller.g.dart';

/// Enregistrement et suppression d'une dégustation. L'état porte l'échec éventuel.
@riverpod
class TastingFormController extends _$TastingFormController {
  @override
  FutureOr<void> build() {}

  /// Crée ([Tasting.id] vide) ou remplace la dégustation ; `false` si refusée
  /// (date future) ou en échec.
  Future<bool> save(Tasting draft) async {
    if (draft.at.isAfter(ref.read(clockProvider).now())) {
      state = AsyncError(
        const ValidationFailure(ValidationReason.startInFuture),
        StackTrace.current,
      );
      return false;
    }
    final note = draft.note?.trim();
    final tasting = draft.copyWith(
      id: draft.id.isEmpty ? ref.read(idGeneratorProvider).newId() : draft.id,
      note: note == null || note.isEmpty ? null : note,
    );
    return _run(
      (code) => ref.read(tastingsRepositoryProvider).save(code, tasting),
    );
  }

  Future<bool> delete(String tastingId) => _run(
    (code) => ref.read(tastingsRepositoryProvider).delete(code, tastingId),
  );

  Future<bool> _run(
    Future<Either<Failure, void>> Function(String code) action,
  ) async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return false;
    state = const AsyncLoading();
    final result = await action(code);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    return result.isRight();
  }
}
```

`custom_food_controller.dart` :

```dart
import 'dart:async';

import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/domain/use_cases/validate_custom_food.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'custom_food_controller.g.dart';

/// Création, modification et suppression d'un aliment perso.
@riverpod
class CustomFoodController extends _$CustomFoodController {
  @override
  FutureOr<void> build() {}

  /// Crée ([id] `null`) ou remplace l'aliment ; le nom doit être unique parmi
  /// le catalogue et les autres aliments perso.
  Future<bool> save({
    String? id,
    required String name,
    required FoodGroup group,
    required Set<Allergen> allergens,
  }) async {
    final foods = ref.read(foodsProvider).value ?? const <String, Food>{};
    final reason = const ValidateCustomFood()(
      name: name,
      existingNames: [
        for (final food in foods.values)
          if (food.id != id && !food.isUnknown) food.name,
      ],
    );
    if (reason != null) return _reject(reason);
    final food = Food(
      id: id ?? ref.read(idGeneratorProvider).newId(),
      name: name.trim(),
      group: group,
      allergens: allergens,
      isCustom: true,
    );
    return _run((code) => ref.read(customFoodsRepositoryProvider).save(code, food));
  }

  /// Supprime l'aliment ; refusé s'il a au moins une dégustation.
  Future<bool> delete(String foodId) async {
    final tastings = ref.read(tastingsProvider).value ?? const <Tasting>[];
    if (tastings.any((tasting) => tasting.foodId == foodId)) {
      return _reject(ValidationReason.customFoodInUse);
    }
    return _run(
      (code) => ref.read(customFoodsRepositoryProvider).delete(code, foodId),
    );
  }

  bool _reject(ValidationReason reason) {
    state = AsyncError(ValidationFailure(reason), StackTrace.current);
    return false;
  }

  Future<bool> _run(
    Future<Either<Failure, void>> Function(String code) action,
  ) async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return false;
    state = const AsyncLoading();
    final result = await action(code);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    return result.isRight();
  }
}
```

- [x] **Step 4 : Génération et vérification**

Run: `dart run build_runner build -d && flutter test test/features/diversification/presentation`
Expected: PASS.

- [x] **Step 5 : Commit**

```bash
dart format lib test && dart analyze
git add lib/features/diversification/presentation/providers test/features/diversification/presentation/diversification_controllers_test.dart
git commit -m "feat: contrôleurs de dégustation et d'aliment perso

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 11 : Présentation — libellés, badge de statut, règle, repère

**Files:**
- Modify: `lib/l10n/app_fr.arb`
- Create: `lib/features/diversification/presentation/food_labels.dart`
- Create: `lib/features/diversification/presentation/widgets/food_status_badge.dart`
- Create: `lib/features/diversification/presentation/widgets/rule_tile.dart`
- Create: `lib/features/diversification/presentation/widgets/guide_item_tile.dart`
- Test: `test/features/diversification/presentation/food_widgets_test.dart`

- [x] **Step 1 : Clés ARB**

Ajouter dans `lib/l10n/app_fr.arb` :

```json
  "foodGroupGrains": "Céréales et féculents",
  "foodGroupLegumes": "Légumineuses, fruits à coque et graines",
  "foodGroupDairy": "Produits laitiers",
  "foodGroupFlesh": "Viandes, poissons et abats",
  "foodGroupEggs": "Œufs",
  "foodGroupVitaminA": "Fruits et légumes riches en vitamine A",
  "foodGroupOtherFruitsVeg": "Autres fruits et légumes",
  "foodGroupOutside": "Hors groupes",
  "foodGroupShortGrains": "Céréales",
  "foodGroupShortLegumes": "Légumineuses",
  "foodGroupShortDairy": "Laitiers",
  "foodGroupShortFlesh": "Chairs",
  "foodGroupShortEggs": "Œufs",
  "foodGroupShortVitaminA": "Vitamine A",
  "foodGroupShortOtherFruitsVeg": "Fruits et légumes",
  "foodGroupShortOutside": "Hors groupes",
  "allergenMilk": "Lait",
  "allergenEggs": "Œuf",
  "allergenGluten": "Gluten",
  "allergenPeanut": "Arachide",
  "allergenTreeNuts": "Fruits à coque",
  "allergenFish": "Poisson",
  "allergenCrustaceans": "Crustacés",
  "allergenSesame": "Sésame",
  "allergenSoy": "Soja",
  "allergenCelery": "Céleri",
  "allergenMustard": "Moutarde",
  "allergenSulphites": "Sulfites",
  "allergenLupin": "Lupin",
  "allergenMolluscs": "Mollusques",
  "likingLoved": "Aimé",
  "likingMeh": "Bof",
  "likingRefused": "Refusé",
  "sourceOms": "OMS",
  "sourceAnses": "Anses",
  "sourceSpf": "SPF",
  "sourceEspghan": "ESPGHAN",
  "sourceAgriculture": "Min. Agriculture",
  "sourceEfsa": "EFSA",
  "ageYears": "{count, plural, =1{1 an} other{{count} ans}}",
  "@ageYears": { "placeholders": { "count": { "type": "int" } } },
  "statusAvoid": "À éviter avant {age} · {sources}",
  "@statusAvoid": { "placeholders": { "age": { "type": "String" }, "sources": { "type": "String" } } },
  "statusNotYet": "Dès 6 mois (OMS)",
  "statusNotYetFrance": "Possible dès 4 mois selon les repères français.",
  "statusTasted": "Goûté ×{count}",
  "@statusTasted": { "placeholders": { "count": { "type": "int" } } },
  "statusNotTasted": "Pas encore",
  "statusPrepare": "Précaution de préparation",
  "ruleAvoidUntil": "À éviter avant {age}",
  "@ruleAvoidUntil": { "placeholders": { "age": { "type": "String" } } },
  "rulePrepareUntil": "Précaution jusqu'à {age}",
  "@rulePrepareUntil": { "placeholders": { "age": { "type": "String" } } },
  "ruleInfo": "Conseil",
  "ruleSources": "Source : {sources}",
  "@ruleSources": { "placeholders": { "sources": { "type": "String" } } },
  "foodUnknown": "Aliment inconnu"
```

Run: `flutter gen-l10n`

- [x] **Step 2 : Tests rouges**

`food_widgets_test.dart` :

```dart
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
    await pump(tester, const FoodStatusBadge(
      status: FoodStatus.avoid(untilMonths: 12, sources: [RuleSource.oms, RuleSource.anses]),
    ));
    expect(find.text('À éviter avant 1 an · OMS, Anses'), findsOneWidget);
  });

  testWidgets('badge avoid : âge en mois', (tester) async {
    await pump(tester, const FoodStatusBadge(
      status: FoodStatus.avoid(untilMonths: 8, sources: [RuleSource.spf]),
    ));
    expect(find.text('À éviter avant 8 mois · SPF'), findsOneWidget);
  });

  testWidgets('badges pas encore recommandé, goûté, pas encore', (tester) async {
    await pump(tester, const Column(children: [
      FoodStatusBadge(status: FoodStatus.notYetRecommended()),
      FoodStatusBadge(status: FoodStatus.tasted(count: 3, needsPreparation: false)),
      FoodStatusBadge(status: FoodStatus.notTasted(needsPreparation: true)),
    ]));
    expect(find.text('Dès 6 mois (OMS)'), findsOneWidget);
    expect(find.text('Goûté ×3'), findsOneWidget);
    expect(find.text('Pas encore'), findsOneWidget);
    expect(find.byIcon(Icons.content_cut), findsOneWidget);
  });

  testWidgets('règle : nature, âge, texte et sources', (tester) async {
    await pump(tester, const RuleTile(rule: FoodRule(
      kind: RuleKind.prepare,
      untilMonths: 60,
      sources: [RuleSource.spf],
      text: 'Couper en quatre.',
    )));
    expect(find.text('Précaution jusqu\'à 5 ans'), findsOneWidget);
    expect(find.text('Couper en quatre.'), findsOneWidget);
    expect(find.text('Source : SPF'), findsOneWidget);
  });

  testWidgets('repère : texte et sources', (tester) async {
    await pump(tester, const GuideItemTile(item: GuideItem(
      text: 'Toujours assis.',
      sources: [RuleSource.spf, RuleSource.oms],
    )));
    expect(find.text('Toujours assis.'), findsOneWidget);
    expect(find.text('Source : SPF, OMS'), findsOneWidget);
  });
}
```

Run: `flutter test test/features/diversification/presentation/food_widgets_test.dart`
Expected: FAIL.

- [x] **Step 3 : Implémentation**

`presentation/food_labels.dart` :

```dart
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/liking.dart';
import 'package:colette/features/diversification/domain/entities/rule_source.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Libellés des groupes alimentaires.
extension FoodGroupLabels on FoodGroup {
  String label(S s) => switch (this) {
    FoodGroup.grainsRootsTubers => s.foodGroupGrains,
    FoodGroup.legumesNutsSeeds => s.foodGroupLegumes,
    FoodGroup.dairy => s.foodGroupDairy,
    FoodGroup.fleshFoods => s.foodGroupFlesh,
    FoodGroup.eggs => s.foodGroupEggs,
    FoodGroup.vitaminAFruitsVeg => s.foodGroupVitaminA,
    FoodGroup.otherFruitsVeg => s.foodGroupOtherFruitsVeg,
    FoodGroup.outsideGroups => s.foodGroupOutside,
  };

  /// Libellé court, pour les puces.
  String shortLabel(S s) => switch (this) {
    FoodGroup.grainsRootsTubers => s.foodGroupShortGrains,
    FoodGroup.legumesNutsSeeds => s.foodGroupShortLegumes,
    FoodGroup.dairy => s.foodGroupShortDairy,
    FoodGroup.fleshFoods => s.foodGroupShortFlesh,
    FoodGroup.eggs => s.foodGroupShortEggs,
    FoodGroup.vitaminAFruitsVeg => s.foodGroupShortVitaminA,
    FoodGroup.otherFruitsVeg => s.foodGroupShortOtherFruitsVeg,
    FoodGroup.outsideGroups => s.foodGroupShortOutside,
  };
}

/// Libellés des allergènes.
extension AllergenLabels on Allergen {
  String label(S s) => switch (this) {
    Allergen.milk => s.allergenMilk,
    Allergen.eggs => s.allergenEggs,
    Allergen.gluten => s.allergenGluten,
    Allergen.peanut => s.allergenPeanut,
    Allergen.treeNuts => s.allergenTreeNuts,
    Allergen.fish => s.allergenFish,
    Allergen.crustaceans => s.allergenCrustaceans,
    Allergen.sesame => s.allergenSesame,
    Allergen.soy => s.allergenSoy,
    Allergen.celery => s.allergenCelery,
    Allergen.mustard => s.allergenMustard,
    Allergen.sulphites => s.allergenSulphites,
    Allergen.lupin => s.allergenLupin,
    Allergen.molluscs => s.allergenMolluscs,
  };
}

/// Libellés et icônes des appréciations.
extension LikingLabels on Liking {
  String label(S s) => switch (this) {
    Liking.loved => s.likingLoved,
    Liking.meh => s.likingMeh,
    Liking.refused => s.likingRefused,
  };

  IconData get icon => switch (this) {
    Liking.loved => Icons.sentiment_satisfied_alt_outlined,
    Liking.meh => Icons.sentiment_neutral_outlined,
    Liking.refused => Icons.sentiment_dissatisfied_outlined,
  };
}

/// Libellés courts des sources.
extension RuleSourceLabels on RuleSource {
  String label(S s) => switch (this) {
    RuleSource.oms => s.sourceOms,
    RuleSource.anses => s.sourceAnses,
    RuleSource.spf => s.sourceSpf,
    RuleSource.espghan => s.sourceEspghan,
    RuleSource.agriculture => s.sourceAgriculture,
    RuleSource.efsa => s.sourceEfsa,
  };
}

/// « OMS, Anses ».
String sourcesLabel(Iterable<RuleSource> sources, S s) =>
    sources.map((source) => source.label(s)).join(', ');

/// « 1 an », « 5 ans » ou « 8 mois ».
String ageLimitLabel(int months, S s) =>
    months % 12 == 0 ? s.ageYears(months ~/ 12) : s.ageMonths(months);

/// Nom affiché : « Aliment inconnu » pour un aliment introuvable.
String foodDisplayName(Food food, S s) =>
    food.isUnknown ? s.foodUnknown : food.name;
```

`widgets/food_status_badge.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diversification/domain/entities/food_status.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Statut d'un aliment : texte coloré et icône de précaution éventuelle.
class FoodStatusBadge extends StatelessWidget {
  const FoodStatusBadge({super.key, required this.status});

  final FoodStatus status;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final (label, color) = switch (status) {
      FoodStatusAvoid(:final untilMonths, :final sources) => (
        s.statusAvoid(ageLimitLabel(untilMonths, s), sourcesLabel(sources, s)),
        AppColors.error,
      ),
      FoodStatusNotYetRecommended() => (s.statusNotYet, AppColors.textSecondary),
      FoodStatusTasted(:final count) => (s.statusTasted(count), AppColors.success),
      FoodStatusNotTasted() => (s.statusNotTasted, AppColors.textSecondary),
    };
    final needsPreparation = switch (status) {
      FoodStatusTasted(:final needsPreparation) ||
      FoodStatusNotTasted(:final needsPreparation) => needsPreparation,
      _ => false,
    };
    return Row(
      mainAxisSize: .min,
      spacing: AppSpacing.xs.value,
      children: [
        if (needsPreparation)
          Icon(
            Icons.content_cut,
            size: AppSize.xs.value,
            color: context.appColor(AppColors.warning),
            semanticLabel: s.statusPrepare,
          ),
        Flexible(
          child: Text(
            label,
            textAlign: .end,
            style: Theme.of(context).coletteTextStyles.small
                .copyWith(color: context.appColor(color)),
          ),
        ),
      ],
    );
  }
}
```

`widgets/rule_tile.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diversification/domain/entities/food_rule.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Règle d'un aliment : nature et âge limite, texte, sources.
class RuleTile extends StatelessWidget {
  const RuleTile({super.key, required this.rule});

  final FoodRule rule;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final until = ageLimitLabel(rule.untilMonths ?? 0, s);
    final (title, icon, color) = switch (rule.kind) {
      RuleKind.avoid => (s.ruleAvoidUntil(until), Icons.block, AppColors.error),
      RuleKind.prepare => (
        s.rulePrepareUntil(until),
        Icons.content_cut,
        AppColors.warning,
      ),
      RuleKind.info => (s.ruleInfo, Icons.info_outline, AppColors.textSecondary),
    };
    return Padding(
      padding: AppSpacing.xs.vertical,
      child: Row(
        crossAxisAlignment: .start,
        spacing: AppSpacing.sm.value,
        children: [
          Icon(icon, size: AppSize.sm.value, color: context.appColor(color)),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              spacing: AppSpacing.xxs.value,
              children: [
                Text(
                  title,
                  style: styles.label.copyWith(color: context.appColor(color)),
                ),
                Text(rule.text, style: styles.body),
                Text(
                  s.ruleSources(sourcesLabel(rule.sources, s)),
                  style: styles.small.copyWith(
                    color: context.appColor(AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

`widgets/guide_item_tile.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diversification/domain/entities/food_catalog.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Repère sourcé, présenté en puce.
class GuideItemTile extends StatelessWidget {
  const GuideItemTile({super.key, required this.item});

  final GuideItem item;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    return Padding(
      padding: AppSpacing.xs.vertical,
      child: Row(
        crossAxisAlignment: .start,
        spacing: AppSpacing.sm.value,
        children: [
          Padding(
            padding: AppSpacing.sm.top,
            child: Icon(Icons.circle, size: AppSize.nano.value, color: secondary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(item.text, style: styles.body),
                Text(
                  s.ruleSources(sourcesLabel(item.sources, s)),
                  style: styles.small.copyWith(color: secondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [x] **Step 4 : Vérifier le succès**

Run: `flutter test test/features/diversification/presentation/food_widgets_test.dart`
Expected: PASS.

- [x] **Step 5 : Commit**

```bash
dart format lib test && dart analyze
git add lib/l10n/app_fr.arb lib/features/diversification/presentation/food_labels.dart lib/features/diversification/presentation/widgets test/features/diversification/presentation/food_widgets_test.dart
git commit -m "feat: libellés, badge de statut et règles sourcées des aliments

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 12 : Présentation — feuille Dégustation, sélecteur d'aliment, avertissements

**Files:**
- Modify: `lib/l10n/app_fr.arb`
- Create: `lib/features/diversification/presentation/widgets/tasting_form_sheet.dart`
- Create: `lib/features/diversification/presentation/widgets/food_picker_sheet.dart`
- Create: `lib/features/diversification/presentation/widgets/tasting_warnings_dialog.dart`
- Create: `lib/features/diversification/presentation/widgets/add_tasting_button.dart`
- Create: `test/features/diversification/helpers/diversification_overrides.dart`
- Test: `test/features/diversification/presentation/tasting_form_sheet_test.dart`

- [x] **Step 1 : Clés ARB**

```json
  "actionAddTasting": "Noter une dégustation",
  "tastingNewTitle": "Nouvelle dégustation",
  "tastingEditTitle": "Modifier la dégustation",
  "tastingFieldFood": "Aliment",
  "tastingChooseFood": "Choisir un aliment",
  "tastingFoodRequired": "Choisis un aliment.",
  "tastingFieldWhen": "Quand",
  "tastingFieldLiking": "Appréciation",
  "tastingFieldReaction": "Réaction",
  "tastingReactionNone": "Aucune",
  "tastingReactionObserved": "Réaction observée",
  "tastingEmergency": "En cas de gêne respiratoire, de gonflement du visage ou de malaise : appelle le 15.",
  "tastingFieldNote": "Note",
  "tastingAllergens": "Allergènes : {names}",
  "@tastingAllergens": { "placeholders": { "names": { "type": "String" } } },
  "tastingWarningsTitle": "À vérifier avant d'enregistrer",
  "tastingWarningTooEarly": "Avant 4 mois, aucun aliment autre que le lait n'est recommandé (OMS, France).",
  "tastingWarningsConfirm": "Enregistrer quand même",
  "catalogSearchHint": "Rechercher un aliment",
  "catalogEmpty": "Aucun aliment ne correspond."
```

Run: `flutter gen-l10n`

- [x] **Step 2 : Overrides partagés des tests de présentation**

`test/features/diversification/helpers/diversification_overrides.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_catalog.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/domain/repositories/custom_foods_repository.dart';
import 'package:colette/features/diversification/domain/repositories/tastings_repository.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import 'catalog_fixture.dart';

/// Repository de dégustations simulé.
class MockTastingsRepository extends Mock implements TastingsRepository {}

/// Repository d'aliments perso simulé.
class MockCustomFoodsRepository extends Mock implements CustomFoodsRepository {}

/// Née le 15 septembre 2026.
final testBirthDate = DateTime(2026, 9, 15);

/// 10 avril 2027 à 18 h : 6 mois révolus.
final testNow = DateTime(2027, 4, 10, 18);

/// Enregistre les valeurs de repli mocktail ; à appeler dans `setUpAll`.
void registerDiversificationFallbacks() {
  registerFallbackValue(Tasting(id: '', foodId: '', at: DateTime(2000)));
  registerFallbackValue(Food.unknown(''));
}

/// Mocks dont `save` et `delete` réussissent.
(MockTastingsRepository, MockCustomFoodsRepository) succeedingRepositories() {
  final tastings = MockTastingsRepository();
  final foods = MockCustomFoodsRepository();
  when(() => tastings.save(any(), any())).thenAnswer((_) async => right(null));
  when(() => tastings.delete(any(), any())).thenAnswer((_) async => right(null));
  when(() => foods.save(any(), any())).thenAnswer((_) async => right(null));
  when(() => foods.delete(any(), any())).thenAnswer((_) async => right(null));
  return (tastings, foods);
}

/// Overrides pour monter un écran de la diversification en test.
List<Override> diversificationOverrides({
  DateTime? now,
  DateTime? birthDate,
  bool withProfile = true,
  List<Tasting> tastings = const [],
  List<Food> customFoods = const [],
  FoodCatalog? catalog,
  Object? catalogError,
  TastingsRepository? tastingsRepository,
  CustomFoodsRepository? customFoodsRepository,
}) => [
  foodCatalogProvider.overrideWith(
    (ref) async => catalogError != null
        ? throw catalogError
        : catalog ?? catalogFixture(),
  ),
  tastingsProvider.overrideWith((ref) => Stream.value(tastings)),
  customFoodsProvider.overrideWith((ref) => Stream.value(customFoods)),
  babyProfileProvider.overrideWith(
    (ref) => Stream.value(
      withProfile
          ? BabyProfile(name: 'Colette', birthDate: birthDate ?? testBirthDate)
          : null,
    ),
  ),
  clockProvider.overrideWithValue(FixedClock(now ?? testNow)),
  minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
  idGeneratorProvider.overrideWithValue(const FixedIdGenerator('new-id')),
  householdLocalStoreProvider.overrideWithValue(
    InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
  ),
  if (tastingsRepository != null)
    tastingsRepositoryProvider.overrideWithValue(tastingsRepository),
  if (customFoodsRepository != null)
    customFoodsRepositoryProvider.overrideWithValue(customFoodsRepository),
];
```

Dans `test/features/diversification/presentation/diversification_controllers_test.dart` (tâche 10), remplacer les deux classes `Mock…Repository` locales par l'import de `../helpers/diversification_overrides.dart` (mêmes noms), sans autre changement.

- [x] **Step 3 : Tests rouges**

`tasting_form_sheet_test.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diversification/domain/entities/liking.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/presentation/widgets/tasting_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';
import '../helpers/catalog_fixture.dart';
import '../helpers/diversification_overrides.dart';

void main() {
  late MockTastingsRepository repo;

  setUpAll(registerDiversificationFallbacks);

  setUp(() => repo = succeedingRepositories().$1);

  final carrot = catalogFixture().foods.firstWhere((f) => f.id == 'carotte');

  Future<void> open(WidgetTester tester, {bool withFood = false}) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showTastingFormSheet(context, food: withFood ? carrot : null),
            child: const Text('open'),
          ),
        ),
      ),
      overrides: diversificationOverrides(tastingsRepository: repo),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Tasting saved() =>
      verify(() => repo.save('ABCDEFGH', captureAny())).captured.single as Tasting;

  testWidgets('aliment présélectionné : enregistre à l\'heure courante et ferme', (tester) async {
    await open(tester, withFood: true);
    expect(find.text('Nouvelle dégustation'), findsOneWidget);
    expect(find.text('Carotte'), findsOneWidget);
    await tester.ensureVisible(find.text('Bof'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bof'));
    await tester.ensureVisible(find.text('Réaction observée'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Réaction observée'));
    await tester.pumpAndSettle();
    expect(
      find.text('En cas de gêne respiratoire, de gonflement du visage ou de malaise : appelle le 15.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Enregistrer'));
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final tasting = saved();
    expect(tasting.foodId, 'carotte');
    expect(tasting.at, testNow);
    expect(tasting.liking, Liking.meh);
    expect(tasting.hadReaction, isTrue);
    expect(find.text('Nouvelle dégustation'), findsNothing);
  });

  testWidgets('sans aliment : message, pas d\'écriture', (tester) async {
    await open(tester);
    await tester.ensureVisible(find.text('Enregistrer'));
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Choisis un aliment.'), findsOneWidget);
    verifyNever(() => repo.save(any(), any()));
  });

  testWidgets('aliment à éviter : règles affichées, confirmation demandée', (tester) async {
    await open(tester);
    await tester.tap(find.text('Choisir un aliment'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Rechercher un aliment'),
      'mie',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Miel'));
    await tester.pumpAndSettle();
    expect(find.text('À éviter avant 1 an'), findsOneWidget);

    await tester.ensureVisible(find.text('Enregistrer'));
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('À vérifier avant d\'enregistrer'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    verifyNever(() => repo.save(any(), any()));

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer quand même'));
    await tester.pumpAndSettle();
    expect(saved().foodId, 'miel');
  });

  testWidgets('échec d\'écriture : message dans la feuille, feuille ouverte', (tester) async {
    when(() => repo.save(any(), any())).thenAnswer((_) async => left(const NetworkFailure()));
    await open(tester, withFood: true);
    await tester.ensureVisible(find.text('Enregistrer'));
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Pas de connexion. Réessaie dans un instant.'), findsOneWidget);
    expect(find.text('Nouvelle dégustation'), findsOneWidget);
  });
}
```

Run: `flutter test test/features/diversification/presentation/tasting_form_sheet_test.dart`
Expected: FAIL.

- [x] **Step 4 : Implémentation**

`widgets/tasting_warnings_dialog.dart` :

```dart
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/diversification/domain/entities/tasting_warning.dart';
import 'package:colette/features/diversification/presentation/widgets/rule_tile.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Liste les avertissements ; `true` si l'utilisateur confirme l'enregistrement.
Future<bool> showTastingWarningsDialog(
  BuildContext context,
  List<TastingWarning> warnings,
) async {
  final s = S.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(s.tastingWarningsTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            for (final warning in warnings)
              switch (warning) {
                TastingWarningTooEarly() => Padding(
                  padding: AppSpacing.xs.vertical,
                  child: Text(s.tastingWarningTooEarly),
                ),
                TastingWarningAvoidRule(:final rule) => RuleTile(rule: rule),
              },
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(s.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(s.tastingWarningsConfirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
```

`widgets/food_picker_sheet.dart` :

```dart
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_filter.dart';
import 'package:colette/features/diversification/domain/use_cases/filter_foods.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_overview_providers.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:colette/features/diversification/presentation/widgets/food_status_badge.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre la liste des aliments ; renvoie l'aliment choisi ou `null`.
Future<Food?> showFoodPickerSheet(BuildContext context) =>
    showModalBottomSheet<Food>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const FoodPickerSheet(),
    );

/// Recherche et choix d'un aliment du catalogue ou perso.
class FoodPickerSheet extends ConsumerStatefulWidget {
  const FoodPickerSheet({super.key});

  @override
  ConsumerState<FoodPickerSheet> createState() => _FoodPickerSheetState();
}

class _FoodPickerSheetState extends ConsumerState<FoodPickerSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final foods = ref.watch(foodsProvider).value ?? const <String, Food>{};
    final statuses = ref.watch(foodStatusesProvider);
    final list = [
      for (final section in const FilterFoods()(
        foods: foods.values,
        filter: FoodFilter(query: _query),
        statuses: statuses,
        tastingCounts: const {},
      ))
        ...section.foods,
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        children: [
          Padding(
            padding: AppSpacing.md.all,
            child: TextField(
              controller: _search,
              autofocus: true,
              decoration: InputDecoration(
                hintText: s.catalogSearchHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? EmptyState(icon: Icons.search_off, message: s.catalogEmpty)
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final food = list[index];
                      final status = statuses[food.id];
                      return ListTile(
                        title: Text(food.name),
                        trailing: status == null
                            ? null
                            : FoodStatusBadge(status: status),
                        onTap: () => Navigator.of(context).pop(food),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
```

`widgets/add_tasting_button.dart` :

```dart
import 'package:colette/features/diversification/presentation/widgets/tasting_form_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Bouton « Noter une dégustation », sans aliment présélectionné.
class AddTastingButton extends StatelessWidget {
  const AddTastingButton({super.key});

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: () => showTastingFormSheet(context),
    icon: const Icon(Icons.add),
    label: Text(S.of(context).actionAddTasting),
  );
}
```

`widgets/tasting_form_sheet.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/liking.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/domain/use_cases/check_tasting_warnings.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/features/diversification/presentation/providers/tasting_form_controller.dart';
import 'package:colette/features/diversification/presentation/widgets/food_picker_sheet.dart';
import 'package:colette/features/diversification/presentation/widgets/rule_tile.dart';
import 'package:colette/features/diversification/presentation/widgets/tasting_warnings_dialog.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre la saisie d'une dégustation ; [tasting] renseignée pour la modifier.
Future<void> showTastingFormSheet(
  BuildContext context, {
  Food? food,
  Tasting? tasting,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => TastingFormSheet(food: food, tasting: tasting),
);

/// Aliment, moment, appréciation, réaction et note d'une dégustation.
class TastingFormSheet extends ConsumerStatefulWidget {
  const TastingFormSheet({super.key, this.food, this.tasting});

  final Food? food;
  final Tasting? tasting;

  @override
  ConsumerState<TastingFormSheet> createState() => _TastingFormSheetState();
}

class _TastingFormSheetState extends ConsumerState<TastingFormSheet> {
  static const _maxNoteLength = 500;

  late Food? _food = widget.food;
  late DateTime _at;
  late Liking? _liking = widget.tasting?.liking;
  late bool _hadReaction = widget.tasting?.hadReaction ?? false;
  late final TextEditingController _note = TextEditingController(
    text: widget.tasting?.note ?? '',
  );
  bool _missingFood = false;

  @override
  void initState() {
    super.initState();
    _at = widget.tasting?.at ?? ref.read(clockProvider).now();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickFood() async {
    final food = await showFoodPickerSheet(context);
    if (food == null || !mounted) return;
    setState(() {
      _food = food;
      _missingFood = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: _at,
      mode: CupertinoDatePickerMode.dateAndTime,
      maximum: ref.read(clockProvider).now(),
      minimum: ref.read(babyProfileProvider).value?.birthDate,
    );
    if (picked != null && mounted) setState(() => _at = picked);
  }

  Future<void> _save() async {
    final food = _food;
    if (food == null) {
      setState(() => _missingFood = true);
      return;
    }
    final warnings = const CheckTastingWarnings()(
      food: food,
      at: _at,
      birthDate: ref.read(babyProfileProvider).value?.birthDate,
    );
    if (warnings.isNotEmpty) {
      final confirmed = await showTastingWarningsDialog(context, warnings);
      if (!confirmed || !mounted) return;
    }
    final ok = await ref
        .read(tastingFormControllerProvider.notifier)
        .save(
          Tasting(
            id: widget.tasting?.id ?? '',
            foodId: food.id,
            at: _at,
            liking: _liking,
            hadReaction: _hadReaction,
            note: _note.text,
          ),
        );
    if (ok && mounted) await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    // Garde le contrôleur autoDispose vivant pendant l'await de _save.
    final saveState = ref.watch(tastingFormControllerProvider);
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final errorColor = context.appColor(AppColors.error);
    final food = _food;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        shrinkWrap: true,
        padding: AppSpacing.lg.all,
        children: [
          Text(
            widget.tasting == null ? s.tastingNewTitle : s.tastingEditTitle,
            style: styles.heading2,
          ),
          AppSpacing.md.verticalSpace,
          _PickerField(
            label: s.tastingFieldFood,
            value: food == null ? s.tastingChooseFood : foodDisplayName(food, s),
            onTap: widget.tasting == null ? _pickFood : null,
          ),
          if (_missingFood)
            Text(
              s.tastingFoodRequired,
              style: styles.small.copyWith(color: errorColor),
            ),
          if (food != null) _FoodRulesSection(food: food),
          AppSpacing.md.verticalSpace,
          _PickerField(
            label: s.tastingFieldWhen,
            value: formatDayAndTime(_at),
            onTap: _pickDate,
          ),
          AppSpacing.md.verticalSpace,
          Text(s.tastingFieldLiking, style: styles.label),
          AppSpacing.xs.verticalSpace,
          SegmentedButton<Liking>(
            showSelectedIcon: false,
            emptySelectionAllowed: true,
            segments: [
              for (final liking in Liking.values)
                ButtonSegment(
                  value: liking,
                  icon: Icon(liking.icon),
                  label: Text(liking.label(s)),
                ),
            ],
            selected: {?_liking},
            onSelectionChanged: (selection) =>
                setState(() => _liking = selection.firstOrNull),
          ),
          AppSpacing.md.verticalSpace,
          Text(s.tastingFieldReaction, style: styles.label),
          AppSpacing.xs.verticalSpace,
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: false, label: Text(s.tastingReactionNone)),
              ButtonSegment(value: true, label: Text(s.tastingReactionObserved)),
            ],
            selected: {_hadReaction},
            onSelectionChanged: (selection) =>
                setState(() => _hadReaction = selection.first),
          ),
          if (_hadReaction)
            Padding(
              padding: AppSpacing.sm.top,
              child: Text(
                s.tastingEmergency,
                style: styles.body.copyWith(color: errorColor),
              ),
            ),
          AppSpacing.md.verticalSpace,
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: s.tastingFieldNote),
            maxLength: _maxNoteLength,
            minLines: 1,
            maxLines: 3,
          ),
          if (saveState case AsyncError(:final error))
            Text(
              failureMessage(error, s),
              style: styles.body.copyWith(color: errorColor),
            ),
          AppSpacing.lg.verticalSpace,
          FilledButton(
            onPressed: saveState is AsyncLoading ? null : _save,
            child: Text(s.actionSave),
          ),
        ],
      ),
    );
  }
}

/// Champ cliquable : libellé au-dessus, valeur, chevron.
class _PickerField extends StatelessWidget {
  const _PickerField({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    return ColetteCardSurface(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(label, style: styles.small.copyWith(color: secondary)),
                Text(value, style: styles.body),
              ],
            ),
          ),
          if (onTap != null) Icon(Icons.chevron_right, color: secondary),
        ],
      ),
    );
  }
}

/// Allergènes et règles de l'aliment choisi.
class _FoodRulesSection extends StatelessWidget {
  const _FoodRulesSection({required this.food});

  final Food food;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: AppSpacing.sm.top,
      child: Column(
        crossAxisAlignment: .start,
        children: [
          if (food.allergens.isNotEmpty)
            Text(
              s.tastingAllergens(
                food.allergens.map((allergen) => allergen.label(s)).join(', '),
              ),
              style: Theme.of(context).coletteTextStyles.label.copyWith(
                color: context.appColor(AppColors.warning),
              ),
            ),
          for (final rule in food.rules) RuleTile(rule: rule),
        ],
      ),
    );
  }
}
```

(En modification, l'aliment n'est pas modifiable : `onTap: null`. Pour changer d'aliment, supprimer la dégustation et en noter une nouvelle.)

- [x] **Step 5 : Vérifier le succès**

Run: `flutter test test/features/diversification/presentation`
Expected: PASS. Si le `SegmentedButton` à trois segments déborde dans le test (largeur 800), réduire à `label` seul sans `icon`.

- [x] **Step 6 : Commit**

```bash
dart format lib test && dart analyze
git add lib/l10n/app_fr.arb lib/features/diversification/presentation/widgets test/features/diversification/helpers test/features/diversification/presentation
git commit -m "feat: feuille de dégustation avec règles de l'aliment et avertissements

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 13 : Présentation — feuille Aliment perso

**Files:**
- Modify: `lib/l10n/app_fr.arb`
- Create: `lib/features/diversification/presentation/widgets/custom_food_sheet.dart`
- Test: `test/features/diversification/presentation/custom_food_sheet_test.dart`

- [x] **Step 1 : Clés ARB**

```json
  "customFoodNewTitle": "Nouvel aliment",
  "customFoodEditTitle": "Modifier l'aliment",
  "customFoodFieldName": "Nom",
  "customFoodFieldGroup": "Groupe",
  "customFoodFieldAllergens": "Allergènes"
```

Run: `flutter gen-l10n`

- [x] **Step 2 : Tests rouges**

`custom_food_sheet_test.dart` :

```dart
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/presentation/widgets/custom_food_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';
import '../helpers/diversification_overrides.dart';

void main() {
  late MockCustomFoodsRepository repo;
  const kaki = Food(id: 'c1', name: 'Kaki séché', group: FoodGroup.vitaminAFruitsVeg, isCustom: true);

  setUpAll(registerDiversificationFallbacks);

  setUp(() => repo = succeedingRepositories().$2);

  Future<void> open(WidgetTester tester, {Food? food}) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showCustomFoodSheet(context, food: food),
            child: const Text('open'),
          ),
        ),
      ),
      overrides: diversificationOverrides(
        customFoods: const [kaki],
        customFoodsRepository: repo,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Food saved() =>
      verify(() => repo.save('ABCDEFGH', captureAny())).captured.single as Food;

  testWidgets('création : nom, groupe et allergènes', (tester) async {
    await open(tester);
    expect(find.text('Nouvel aliment'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Datte');
    await tester.tap(find.text('Fruits et légumes'));
    await tester.ensureVisible(find.text('Sulfites'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sulfites'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Enregistrer'));
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(saved(), const Food(
      id: 'new-id',
      name: 'Datte',
      group: FoodGroup.otherFruitsVeg,
      allergens: {Allergen.sulphites},
      isCustom: true,
    ));
    expect(find.text('Nouvel aliment'), findsNothing);
  });

  testWidgets('doublon du catalogue : message, pas d\'écriture', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), 'carotte');
    await tester.ensureVisible(find.text('Enregistrer'));
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Cet aliment existe déjà.'), findsOneWidget);
    verifyNever(() => repo.save(any(), any()));
  });

  testWidgets('modification : champs préremplis, id conservé', (tester) async {
    await open(tester, food: kaki);
    expect(find.text('Modifier l\'aliment'), findsOneWidget);
    expect(find.text('Kaki séché'), findsOneWidget);
    await tester.ensureVisible(find.text('Enregistrer'));
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(saved().id, 'c1');
  });
}
```

Run: `flutter test test/features/diversification/presentation/custom_food_sheet_test.dart`
Expected: FAIL.

- [x] **Step 3 : Implémentation**

`widgets/custom_food_sheet.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/use_cases/validate_custom_food.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/features/diversification/presentation/providers/custom_food_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre la création (ou la modification si [food]) d'un aliment perso.
Future<void> showCustomFoodSheet(BuildContext context, {Food? food}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CustomFoodSheet(food: food),
    );

/// Nom, groupe OMS et allergènes d'un aliment perso.
class CustomFoodSheet extends ConsumerStatefulWidget {
  const CustomFoodSheet({super.key, this.food});

  final Food? food;

  @override
  ConsumerState<CustomFoodSheet> createState() => _CustomFoodSheetState();
}

class _CustomFoodSheetState extends ConsumerState<CustomFoodSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.food?.name ?? '',
  );
  late FoodGroup _group = widget.food?.group ?? FoodGroup.otherFruitsVeg;
  late final Set<Allergen> _allergens = {...?widget.food?.allergens};

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _toggle(Allergen allergen, bool selected) => setState(() {
    if (selected) {
      _allergens.add(allergen);
    } else {
      _allergens.remove(allergen);
    }
  });

  Future<void> _save() async {
    final ok = await ref
        .read(customFoodControllerProvider.notifier)
        .save(
          id: widget.food?.id,
          name: _name.text,
          group: _group,
          allergens: {..._allergens},
        );
    if (ok && mounted) await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    // Garde le contrôleur autoDispose vivant pendant l'await de _save.
    final saveState = ref.watch(customFoodControllerProvider);
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        shrinkWrap: true,
        padding: AppSpacing.lg.all,
        children: [
          Text(
            widget.food == null ? s.customFoodNewTitle : s.customFoodEditTitle,
            style: styles.heading2,
          ),
          AppSpacing.md.verticalSpace,
          TextField(
            controller: _name,
            autofocus: widget.food == null,
            maxLength: ValidateCustomFood.maxNameLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: s.customFoodFieldName),
          ),
          AppSpacing.sm.verticalSpace,
          Text(s.customFoodFieldGroup, style: styles.label),
          AppSpacing.xs.verticalSpace,
          Wrap(
            spacing: AppSpacing.sm.value,
            runSpacing: AppSpacing.xs.value,
            children: [
              for (final group in FoodGroup.values)
                ChoiceChip(
                  label: Text(group.shortLabel(s)),
                  selected: _group == group,
                  onSelected: (_) => setState(() => _group = group),
                ),
            ],
          ),
          AppSpacing.md.verticalSpace,
          Text(s.customFoodFieldAllergens, style: styles.label),
          AppSpacing.xs.verticalSpace,
          Wrap(
            spacing: AppSpacing.sm.value,
            runSpacing: AppSpacing.xs.value,
            children: [
              for (final allergen in Allergen.values)
                FilterChip(
                  label: Text(allergen.label(s)),
                  selected: _allergens.contains(allergen),
                  onSelected: (selected) => _toggle(allergen, selected),
                ),
            ],
          ),
          if (saveState case AsyncError(:final error)) ...[
            AppSpacing.md.verticalSpace,
            Text(
              failureMessage(error, s),
              style: styles.body.copyWith(color: context.appColor(AppColors.error)),
            ),
          ],
          AppSpacing.lg.verticalSpace,
          FilledButton(
            onPressed: saveState is AsyncLoading ? null : _save,
            child: Text(s.actionSave),
          ),
        ],
      ),
    );
  }
}
```

- [x] **Step 4 : Vérifier le succès**

Run: `flutter test test/features/diversification/presentation/custom_food_sheet_test.dart`
Expected: PASS. Note : « Fruits et légumes » est le libellé court de `otherFruitsVeg` ; s'il apparaît plusieurs fois, cibler `find.widgetWithText(ChoiceChip, 'Fruits et légumes')`.

- [x] **Step 5 : Commit**

```bash
dart format lib test && dart analyze
git add lib/l10n/app_fr.arb lib/features/diversification/presentation/widgets/custom_food_sheet.dart test/features/diversification/presentation/custom_food_sheet_test.dart
git commit -m "feat: feuille d'ajout et de modification d'un aliment perso

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 14 : Présentation — en-tête de phase et feuille « Repères à son âge »

**Files:**
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/features/diversification/presentation/food_labels.dart`
- Create: `lib/features/diversification/presentation/widgets/phase_header.dart`
- Create: `lib/features/diversification/presentation/widgets/age_guide_sheet.dart`
- Test: `test/features/diversification/presentation/phase_header_test.dart`

- [x] **Step 1 : Clés ARB**

```json
  "tabPlate": "Assiette",
  "plateTitle": "Assiette",
  "plateSubtitle": "{phase} · {meals}",
  "@plateSubtitle": { "placeholders": { "phase": { "type": "String" }, "meals": { "type": "String" } } },
  "plateNoProfile": "Renseigne le profil du bébé dans Réglages pour voir les repères selon son âge.",
  "plateGuideTooltip": "Repères à son âge",
  "phasePreparation": "Préparation",
  "phaseMonths6To8": "Phase 6–8 mois",
  "phaseMonths9To11": "Phase 9–11 mois",
  "phaseMonths12To23": "Phase 12–23 mois",
  "guideTitle": "Repères à son âge",
  "guideMealsFor": "Repas et textures · {phase}",
  "@guideMealsFor": { "placeholders": { "phase": { "type": "String" } } },
  "guideReadiness": "Signes que bébé est prêt",
  "guideHunger": "Signes de faim",
  "guideSatiety": "Signes de satiété",
  "guideSafety": "Sécurité et bonnes pratiques",
  "guideSources": "Sources",
  "guideReviewedAt": "Sources consultées le {date}.",
  "@guideReviewedAt": { "placeholders": { "date": { "type": "String" } } },
  "guideDisclaimer": "Informations générales : elles ne remplacent pas l'avis de ton pédiatre."
```

Run: `flutter gen-l10n`

Ajouter à `food_labels.dart` (avec l'import de `diversification_phase.dart`) :

```dart
/// Libellés des phases.
extension DiversificationPhaseLabels on DiversificationPhase {
  String label(S s) => switch (this) {
    DiversificationPhase.preparation => s.phasePreparation,
    DiversificationPhase.months6To8 => s.phaseMonths6To8,
    DiversificationPhase.months9To11 => s.phaseMonths9To11,
    DiversificationPhase.months12To23 => s.phaseMonths12To23,
  };
}
```

- [x] **Step 2 : Tests rouges**

`phase_header_test.dart` :

```dart
import 'package:colette/features/diversification/presentation/widgets/phase_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../helpers/diversification_overrides.dart';

void main() {
  Future<void> pump(WidgetTester tester, {DateTime? now, bool withProfile = true}) =>
      pumpApp(
        tester,
        const Scaffold(body: PhaseHeader()),
        overrides: diversificationOverrides(now: now, withProfile: withProfile),
      );

  testWidgets('phase 6–8 mois et repas', (tester) async {
    await pump(tester);
    expect(find.text('Assiette'), findsOneWidget);
    expect(find.text('Phase 6–8 mois · 2 à 3 repas'), findsOneWidget);
  });

  testWidgets('préparation', (tester) async {
    await pump(tester, now: DateTime(2026, 10, 1));
    expect(find.text('Préparation · Lait uniquement'), findsOneWidget);
  });

  testWidgets('sans profil : invitation à le renseigner', (tester) async {
    await pump(tester, withProfile: false);
    expect(
      find.text('Renseigne le profil du bébé dans Réglages pour voir les repères selon son âge.'),
      findsOneWidget,
    );
  });

  testWidgets('ⓘ ouvre les repères de la phase, les sources et l\'avertissement', (tester) async {
    await pump(tester);
    await tester.tap(find.byTooltip('Repères à son âge'));
    await tester.pumpAndSettle();
    expect(find.text('Repas et textures · Phase 6–8 mois'), findsOneWidget);
    expect(find.text('Purées lisses puis écrasées.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('OMS 2023'), 200);
    expect(find.text('OMS 2023'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Informations générales : elles ne remplacent pas l\'avis de ton pédiatre.'),
      200,
    );
  });
}
```

Run: `flutter test test/features/diversification/presentation/phase_header_test.dart`
Expected: FAIL.

- [x] **Step 3 : Implémentation**

`widgets/phase_header.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:colette/features/diversification/presentation/widgets/age_guide_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Titre de l'onglet, phase OMS et repas conseillés, accès aux repères.
class PhaseHeader extends ConsumerWidget {
  const PhaseHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final phase = ref.watch(diversificationTimelineProvider)?.phase;
    final guide = ref.watch(foodCatalogProvider).value?.guide;
    final meals = phase == null ? null : guide?.phases[phase]?.mealsSummary;
    final subtitle = switch ((phase, meals)) {
      (final phase?, final meals?) => s.plateSubtitle(phase.label(s), meals),
      (final phase?, null) => phase.label(s),
      _ => s.plateNoProfile,
    };
    return Row(
      crossAxisAlignment: .start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            spacing: AppSpacing.xxs.value,
            children: [
              Text(s.plateTitle, style: styles.heading1),
              Text(
                subtitle,
                style: styles.body.copyWith(
                  color: context.appColor(AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: s.plateGuideTooltip,
          icon: const Icon(Icons.info_outline),
          onPressed: guide == null
              ? null
              : () => showAgeGuideSheet(
                  context,
                  phase: phase ?? DiversificationPhase.preparation,
                ),
        ),
      ],
    );
  }
}
```

`widgets/age_guide_sheet.dart` :

```dart
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/domain/entities/food_catalog.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:colette/features/diversification/presentation/widgets/guide_item_tile.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre les repères de [phase].
Future<void> showAgeGuideSheet(
  BuildContext context, {
  required DiversificationPhase phase,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => AgeGuideSheet(phase: phase),
);

/// Repas et textures de la phase, signes, sécurité, sources et avertissement.
class AgeGuideSheet extends ConsumerWidget {
  const AgeGuideSheet({super.key, required this.phase});

  final DiversificationPhase phase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(foodCatalogProvider).value;
    if (catalog == null) return const SizedBox.shrink();
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    final guide = catalog.guide;
    return ListView(
      padding: AppSpacing.lg.all,
      children: [
        Text(s.guideTitle, style: styles.heading2),
        _GuideSection(
          title: s.guideMealsFor(phase.label(s)),
          items: guide.phases[phase]?.items ?? const [],
        ),
        _GuideSection(title: s.guideReadiness, items: guide.readinessSigns),
        _GuideSection(title: s.guideHunger, items: guide.hungerSigns),
        _GuideSection(title: s.guideSatiety, items: guide.satietySigns),
        _GuideSection(title: s.guideSafety, items: guide.safety),
        SectionHeader(title: s.guideSources),
        for (final source in catalog.sources.values)
          Padding(
            padding: AppSpacing.xs.vertical,
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(source.label, style: styles.body),
                SelectableText(
                  source.url,
                  style: styles.small.copyWith(color: secondary),
                ),
              ],
            ),
          ),
        AppSpacing.sm.verticalSpace,
        Text(
          s.guideReviewedAt(formatShortDate(catalog.reviewedAt)),
          style: styles.small.copyWith(color: secondary),
        ),
        AppSpacing.md.verticalSpace,
        Text(s.guideDisclaimer, style: styles.label),
      ],
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({required this.title, required this.items});

  final String title;
  final List<GuideItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: .start,
      children: [
        SectionHeader(title: title),
        for (final item in items) GuideItemTile(item: item),
      ],
    );
  }
}
```

- [x] **Step 4 : Vérifier le succès**

Run: `flutter test test/features/diversification/presentation/phase_header_test.dart`
Expected: PASS.

- [x] **Step 5 : Commit**

```bash
dart format lib test && dart analyze
git add lib/l10n/app_fr.arb lib/features/diversification/presentation test/features/diversification/presentation/phase_header_test.dart
git commit -m "feat: en-tête de phase et feuille des repères à son âge

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 15 : Présentation — cartes Préparation, Aujourd'hui, Allergènes, À reproposer

**Files:**
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/app/router/app_router.dart` (constantes `AppRoutes` seulement)
- Create: `lib/features/diversification/presentation/widgets/preparation_card.dart`
- Create: `lib/features/diversification/presentation/widgets/today_diversity_card.dart`
- Create: `lib/features/diversification/presentation/widgets/allergens_card.dart`
- Create: `lib/features/diversification/presentation/widgets/retry_card.dart`
- Test: `test/features/diversification/presentation/plate_cards_test.dart`

- [x] **Step 1 : Clés ARB et routes**

```json
  "preparationTitle": "Bientôt la diversification",
  "preparationCountdown": "{days, plural, =0{6 mois aujourd'hui} =1{6 mois demain} other{6 mois dans {days} jours}}",
  "@preparationCountdown": { "placeholders": { "days": { "type": "int" } } },
  "preparationReferences": "OMS : à 6 mois · France : entre 4 et 6 mois, jamais avant 4 mois",
  "todayDiversityTitle": "Aujourd'hui",
  "todayDiversityTastings": "{count, plural, =0{Aucune dégustation} =1{1 dégustation} other{{count} dégustations}}",
  "@todayDiversityTastings": { "placeholders": { "count": { "type": "int" } } },
  "todayDiversityGroups": "{count, plural, =0{0 groupe sur 7} =1{1 groupe sur 7} other{{count} groupes sur 7}}",
  "@todayDiversityGroups": { "placeholders": { "count": { "type": "int" } } },
  "todayDiversityReference": "Repère OMS : au moins 5 groupes sur 8 par jour, lait compris.",
  "allergensTitle": "Allergènes",
  "allergensIntroduced": "{count, plural, =0{Aucun introduit sur {total}} =1{1 introduit sur {total}} other{{count} introduits sur {total}}}",
  "@allergensIntroduced": { "placeholders": { "count": { "type": "int" }, "total": { "type": "int" } } },
  "allergensHint": "Touche un allergène pour voir les aliments qui en contiennent.",
  "allergenStateNotYet": "pas encore",
  "allergenStateIntroduced": "introduit",
  "allergenStateReaction": "réaction signalée",
  "allergenSemantics": "{allergen} : {state}",
  "@allergenSemantics": { "placeholders": { "allergen": { "type": "String" }, "state": { "type": "String" } } },
  "retryTitle": "À reproposer",
  "retryHint": "Il faut souvent 8 à 10 essais avant qu'un aliment soit accepté.",
  "retryItem": "{liking} · {count, plural, =1{1 essai} other{{count} essais}}",
  "@retryItem": { "placeholders": { "liking": { "type": "String" }, "count": { "type": "int" } } }
```

Run: `flutter gen-l10n`

Dans `AppRoutes` (`lib/app/router/app_router.dart`), ajouter :

```dart
  static const plate = '/plate';

  /// Fiche d'un aliment de l'onglet Assiette.
  static String plateFood(String foodId) => '$plate/food/$foodId';
```

- [x] **Step 2 : Tests rouges**

`plate_cards_test.dart` :

```dart
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/allergen_state.dart';
import 'package:colette/features/diversification/domain/entities/daily_diversity.dart';
import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/domain/entities/diversification_timeline.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/liking.dart';
import 'package:colette/features/diversification/domain/entities/retry_item.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_overview_providers.dart';
import 'package:colette/features/diversification/presentation/widgets/allergens_card.dart';
import 'package:colette/features/diversification/presentation/widgets/preparation_card.dart';
import 'package:colette/features/diversification/presentation/widgets/retry_card.dart';
import 'package:colette/features/diversification/presentation/widgets/today_diversity_card.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../helpers/diversification_overrides.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child, [List<Override> extra = const []]) =>
      pumpApp(
        tester,
        Scaffold(body: SingleChildScrollView(child: child)),
        overrides: [...diversificationOverrides(), ...extra],
      );

  testWidgets('préparation : compte à rebours, repères, signes', (tester) async {
    await pump(tester, PreparationCard(timeline: DiversificationTimeline(
      phase: DiversificationPhase.preparation,
      ageMonths: 0,
      sixMonthsDate: DateTime(2027, 3, 15),
      daysUntilSixMonths: 173,
    )));
    expect(find.text('Bientôt la diversification'), findsOneWidget);
    expect(find.text('6 mois dans 173 jours'), findsOneWidget);
    expect(find.text('OMS : à 6 mois · France : entre 4 et 6 mois, jamais avant 4 mois'), findsOneWidget);
    expect(find.text('Tient sa tête et son dos droits.'), findsOneWidget);
    expect(find.text('Noter une dégustation'), findsOneWidget);
  });

  testWidgets('aujourd\'hui : groupes couverts et dégustations', (tester) async {
    await pump(tester, const TodayDiversityCard(), [
      dailyDiversityProvider.overrideWithValue(const DailyDiversity(
        coveredGroups: {FoodGroup.eggs, FoodGroup.vitaminAFruitsVeg},
        tastingCount: 3,
      )),
    ]);
    expect(find.text('2 groupes sur 7'), findsOneWidget);
    expect(find.text('3 dégustations'), findsOneWidget);
    expect(find.text('Œufs'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNWidgets(2));
    expect(find.text('Repère OMS : au moins 5 groupes sur 8 par jour, lait compris.'), findsOneWidget);
  });

  testWidgets('allergènes : décompte et tap', (tester) async {
    Allergen? tapped;
    await pump(tester, AllergensCard(onAllergenTap: (a) => tapped = a), [
      allergenProgressProvider.overrideWithValue({
        for (final a in Allergen.tracked)
          a: switch (a) {
            Allergen.milk => AllergenState.introduced,
            Allergen.eggs => AllergenState.reaction,
            _ => AllergenState.notYet,
          },
      }),
    ]);
    expect(find.text('2 introduits sur 9'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    await tester.tap(find.text('Œuf'));
    expect(tapped, Allergen.eggs);
  });

  testWidgets('à reproposer : liste, masquée si vide', (tester) async {
    const broccoli = Food(id: 'brocoli', name: 'Brocoli', group: FoodGroup.otherFruitsVeg);
    await pump(tester, const RetryCard(), [
      foodsToRetryProvider.overrideWithValue(const [
        RetryItem(food: broccoli, lastLiking: Liking.refused, tastingCount: 3),
      ]),
    ]);
    expect(find.text('À reproposer'), findsOneWidget);
    expect(find.text('Brocoli'), findsOneWidget);
    expect(find.text('Refusé · 3 essais'), findsOneWidget);
  });

  testWidgets('à reproposer vide : rien', (tester) async {
    await pump(tester, const RetryCard(), [foodsToRetryProvider.overrideWithValue(const [])]);
    expect(find.byType(ColetteCardSurface), findsNothing);
  });
}
```

Run: `flutter test test/features/diversification/presentation/plate_cards_test.dart`
Expected: FAIL.

- [x] **Step 3 : Implémentation**

`widgets/preparation_card.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diversification/domain/entities/diversification_timeline.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:colette/features/diversification/presentation/widgets/add_tasting_button.dart';
import 'package:colette/features/diversification/presentation/widgets/guide_item_tile.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Avant 6 mois : compte à rebours, repères OMS / France, signes que bébé est prêt.
class PreparationCard extends ConsumerWidget {
  const PreparationCard({super.key, required this.timeline});

  final DiversificationTimeline timeline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final signs =
        ref.watch(foodCatalogProvider).value?.guide.readinessSigns ?? const [];
    return ColetteCardSurface(
      backgroundColor: AppColors.primaryContainer,
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.sm.value,
        children: [
          Text(s.preparationTitle, style: styles.heading3),
          Text(
            s.preparationCountdown(timeline.daysUntilSixMonths),
            style: styles.heading2,
          ),
          Text(
            s.preparationReferences,
            style: styles.small.copyWith(
              color: context.appColor(AppColors.textSecondary),
            ),
          ),
          if (signs.isNotEmpty) ...[
            Text(s.guideReadiness, style: styles.label),
            for (final sign in signs) GuideItemTile(item: sign),
          ],
          const AddTastingButton(),
        ],
      ),
    );
  }
}
```

`widgets/today_diversity_card.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_overview_providers.dart';
import 'package:colette/features/diversification/presentation/widgets/add_tasting_button.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Diversité du jour : groupes OMS couverts par les dégustations.
class TodayDiversityCard extends ConsumerWidget {
  const TodayDiversityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    final diversity = ref.watch(dailyDiversityProvider);
    return ColetteCardSurface(
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.sm.value,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(s.todayDiversityTitle, style: styles.heading3),
              ),
              Text(
                s.todayDiversityTastings(diversity.tastingCount),
                style: styles.small.copyWith(color: secondary),
              ),
            ],
          ),
          Text(
            s.todayDiversityGroups(diversity.coveredGroups.length),
            style: styles.heading2,
          ),
          Wrap(
            spacing: AppSpacing.xs.value,
            runSpacing: AppSpacing.xs.value,
            children: [
              for (final group in FoodGroup.diversityGroups)
                _GroupChip(
                  label: group.shortLabel(s),
                  covered: diversity.coveredGroups.contains(group),
                ),
            ],
          ),
          Text(
            s.todayDiversityReference,
            style: styles.small.copyWith(color: secondary),
          ),
          const AddTastingButton(),
        ],
      ),
    );
  }
}

class _GroupChip extends StatelessWidget {
  const _GroupChip({required this.label, required this.covered});

  final String label;
  final bool covered;

  @override
  Widget build(BuildContext context) {
    final color = context.appColor(
      covered ? AppColors.success : AppColors.textSecondary,
    );
    return Container(
      padding: AppSpacing.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: covered ? context.appColor(AppColors.primaryContainer) : null,
        border: Border.all(color: context.appColor(AppColors.border)),
        borderRadius: AppRadius.round.circular,
      ),
      child: Row(
        mainAxisSize: .min,
        spacing: AppSpacing.xxs.value,
        children: [
          if (covered) Icon(Icons.check, size: AppSize.xs.value, color: color),
          Text(
            label,
            style: Theme.of(context).coletteTextStyles.small.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
```

`widgets/allergens_card.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/allergen_state.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_overview_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Les 9 allergènes suivis : pas encore, introduit ou réaction signalée.
class AllergensCard extends ConsumerWidget {
  const AllergensCard({super.key, required this.onAllergenTap});

  /// Filtre le catalogue sur l'allergène touché.
  final ValueChanged<Allergen> onAllergenTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final states = ref.watch(allergenProgressProvider);
    final introduced = states.values
        .where((state) => state != AllergenState.notYet)
        .length;
    return ColetteCardSurface(
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.sm.value,
        children: [
          Row(
            children: [
              Expanded(child: Text(s.allergensTitle, style: styles.heading3)),
              Text(
                s.allergensIntroduced(introduced, Allergen.tracked.length),
                style: styles.small.copyWith(
                  color: context.appColor(AppColors.textSecondary),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: AppSpacing.xs.value,
            runSpacing: AppSpacing.xs.value,
            children: [
              for (final MapEntry(key: allergen, value: state) in states.entries)
                _AllergenChip(
                  allergen: allergen,
                  state: state,
                  onTap: () => onAllergenTap(allergen),
                ),
            ],
          ),
          Text(
            s.allergensHint,
            style: styles.small.copyWith(
              color: context.appColor(AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllergenChip extends StatelessWidget {
  const _AllergenChip({
    required this.allergen,
    required this.state,
    required this.onTap,
  });

  final Allergen allergen;
  final AllergenState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final (icon, color, stateLabel) = switch (state) {
      AllergenState.notYet => (
        Icons.radio_button_unchecked,
        AppColors.textSecondary,
        s.allergenStateNotYet,
      ),
      AllergenState.introduced => (
        Icons.check_circle_outline,
        AppColors.success,
        s.allergenStateIntroduced,
      ),
      AllergenState.reaction => (
        Icons.warning_amber,
        AppColors.warning,
        s.allergenStateReaction,
      ),
    };
    return Semantics(
      button: true,
      label: s.allergenSemantics(allergen.label(s), stateLabel),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.round.circular,
        child: Padding(
          padding: AppSpacing.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: .min,
            spacing: AppSpacing.xxs.value,
            children: [
              Icon(icon, size: AppSize.xs.value, color: context.appColor(color)),
              Text(
                allergen.label(s),
                style: Theme.of(context).coletteTextStyles.small,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

`widgets/retry_card.dart` :

```dart
import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_overview_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Aliments refusés ou jugés « bof » à reproposer ; rien si la liste est vide.
class RetryCard extends ConsumerWidget {
  const RetryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(foodsToRetryProvider);
    if (items.isEmpty) return const SizedBox.shrink();
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    return Padding(
      padding: AppSpacing.md.top,
      child: ColetteCardSurface(
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Text(s.retryTitle, style: styles.heading3),
            Text(s.retryHint, style: styles.small.copyWith(color: secondary)),
            AppSpacing.xs.verticalSpace,
            for (final item in items)
              InkWell(
                onTap: () => context.push(AppRoutes.plateFood(item.food.id)),
                child: Padding(
                  padding: AppSpacing.xs.vertical,
                  child: Row(
                    spacing: AppSpacing.sm.value,
                    children: [
                      Expanded(child: Text(item.food.name, style: styles.body)),
                      Text(
                        s.retryItem(item.lastLiking.label(s), item.tastingCount),
                        style: styles.small.copyWith(color: secondary),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

(La liste « À reproposer » est courte par construction et vit dans une carte : un `Column` suffit, comme les autres cartes de l'accueil.)

- [x] **Step 4 : Vérifier le succès**

Run: `flutter test test/features/diversification/presentation/plate_cards_test.dart`
Expected: PASS.

- [x] **Step 5 : Commit**

```bash
dart format lib test && dart analyze
git add lib/l10n/app_fr.arb lib/app/router/app_router.dart lib/features/diversification/presentation/widgets test/features/diversification/presentation/plate_cards_test.dart
git commit -m "feat: cartes préparation, diversité du jour, allergènes et aliments à reproposer

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 16 : Présentation — catalogue et page Assiette

**Files:**
- Modify: `lib/l10n/app_fr.arb`
- Create: `lib/features/diversification/presentation/widgets/catalog_search_bar.dart`
- Create: `lib/features/diversification/presentation/widgets/catalog_filter_chips.dart`
- Create: `lib/features/diversification/presentation/widgets/food_row.dart`
- Create: `lib/features/diversification/presentation/widgets/food_catalog_sliver.dart`
- Create: `lib/features/diversification/presentation/pages/plate_page.dart`
- Test: `test/features/diversification/presentation/plate_page_test.dart`

- [x] **Step 1 : Clés ARB**

```json
  "catalogTitle": "Aliments · {count, plural, =0{aucun goûté} =1{1 goûté} other{{count} goûtés}}",
  "@catalogTitle": { "placeholders": { "count": { "type": "int" } } },
  "catalogFilterAll": "Tous",
  "catalogFilterNotTasted": "Pas goûtés",
  "catalogFilterAvoid": "À éviter",
  "catalogAllergenFilter": "Contient : {allergen}",
  "@catalogAllergenFilter": { "placeholders": { "allergen": { "type": "String" } } },
  "catalogClearSearch": "Effacer la recherche"
```

Run: `flutter gen-l10n`

- [x] **Step 2 : Tests rouges**

`plate_page_test.dart` :

```dart
import 'package:colette/features/diversification/domain/entities/liking.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/presentation/pages/plate_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../helpers/diversification_overrides.dart';

void main() {
  final tastings = [
    Tasting(id: '1', foodId: 'carotte', at: DateTime(2027, 4, 10, 12), liking: Liking.loved),
    Tasting(id: '2', foodId: 'carotte', at: DateTime(2027, 4, 9)),
    Tasting(id: '3', foodId: 'brocoli', at: DateTime(2027, 4, 8), liking: Liking.refused),
  ];

  Future<void> pump(WidgetTester tester, {DateTime? now}) => pumpApp(
    tester,
    const PlatePage(),
    overrides: diversificationOverrides(now: now, tastings: tastings),
  );

  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);

  testWidgets('phase active : diversité du jour, allergènes, catalogue', (tester) async {
    await pump(tester);
    expect(find.text('Phase 6–8 mois · 2 à 3 repas'), findsOneWidget);
    expect(find.text('1 groupe sur 7'), findsOneWidget);
    expect(find.text('Allergènes'), findsOneWidget);
    await scrollTo(tester, find.text('Aliments · 2 goûtés'));
    await scrollTo(tester, find.text('Goûté ×2'));
    expect(find.text('Goûté ×2'), findsOneWidget);
  });

  testWidgets('avant 6 mois : carte préparation, statuts « dès 6 mois »', (tester) async {
    await pump(tester, now: DateTime(2026, 12, 1));
    expect(find.text('Bientôt la diversification'), findsOneWidget);
    await scrollTo(tester, find.text('Dès 6 mois (OMS)').first);
  });

  testWidgets('recherche', (tester) async {
    await pump(tester);
    await scrollTo(tester, find.widgetWithText(TextField, 'Rechercher un aliment'));
    await tester.enterText(find.widgetWithText(TextField, 'Rechercher un aliment'), 'mie');
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Miel'));
    expect(find.text('Carotte'), findsNothing);
  });

  testWidgets('filtre « À éviter »', (tester) async {
    await pump(tester);
    await scrollTo(tester, find.text('À éviter'));
    await tester.tap(find.text('À éviter'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Miel'));
    expect(find.text('Carotte'), findsNothing);
  });

  testWidgets('tap sur un allergène : filtre le catalogue', (tester) async {
    await pump(tester);
    await tester.ensureVisible(find.text('Œuf'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Œuf'));
    await tester.pumpAndSettle();
    expect(find.text('Contient : Œuf'), findsOneWidget);
    await scrollTo(tester, find.text('Œuf bien cuit'));
    expect(find.text('Carotte'), findsNothing);
  });

  testWidgets('catalogue en erreur : message', (tester) async {
    await pumpApp(
      tester,
      const PlatePage(),
      overrides: diversificationOverrides(catalogError: StateError('KO')),
    );
    expect(find.text('Une erreur est survenue.'), findsOneWidget);
  });
}
```

Run: `flutter test test/features/diversification/presentation/plate_page_test.dart`
Expected: FAIL.

- [x] **Step 3 : Implémentation**

`widgets/catalog_search_bar.dart` :

```dart
import 'package:colette/features/diversification/presentation/providers/catalog_filter.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Champ de recherche du catalogue, relié à [CatalogFilter].
class CatalogSearchBar extends ConsumerStatefulWidget {
  const CatalogSearchBar({super.key});

  @override
  ConsumerState<CatalogSearchBar> createState() => _CatalogSearchBarState();
}

class _CatalogSearchBarState extends ConsumerState<CatalogSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(catalogFilterProvider).query,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) =>
      ref.read(catalogFilterProvider.notifier).setQuery(value);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: s.catalogSearchHint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: ValueListenableBuilder(
          valueListenable: _controller,
          builder: (context, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: s.catalogClearSearch,
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    _onChanged('');
                  },
                ),
        ),
      ),
    );
  }
}
```

`widgets/catalog_filter_chips.dart` :

```dart
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/diversification/domain/entities/food_filter.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/features/diversification/presentation/providers/catalog_filter.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tous / Pas goûtés / À éviter, et filtre allergène actif.
class CatalogFilterChips extends ConsumerWidget {
  const CatalogFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final filter = ref.watch(catalogFilterProvider);
    return Wrap(
      spacing: AppSpacing.sm.value,
      runSpacing: AppSpacing.xs.value,
      children: [
        for (final mode in CatalogMode.values)
          ChoiceChip(
            label: Text(switch (mode) {
              CatalogMode.all => s.catalogFilterAll,
              CatalogMode.notTasted => s.catalogFilterNotTasted,
              CatalogMode.avoid => s.catalogFilterAvoid,
            }),
            selected: filter.mode == mode,
            onSelected: (_) =>
                ref.read(catalogFilterProvider.notifier).setMode(mode),
          ),
        if (filter.allergen case final allergen?)
          InputChip(
            label: Text(s.catalogAllergenFilter(allergen.label(s))),
            onDeleted: () =>
                ref.read(catalogFilterProvider.notifier).setAllergen(null),
          ),
      ],
    );
  }
}
```

`widgets/food_row.dart` :

```dart
import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_status.dart';
import 'package:colette/features/diversification/presentation/widgets/food_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Ligne du catalogue : nom et statut ; ouvre la fiche de l'aliment.
class FoodRow extends StatelessWidget {
  const FoodRow({super.key, required this.food, required this.status});

  final Food food;
  final FoodStatus? status;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    return InkWell(
      onTap: () => context.push(AppRoutes.plateFood(food.id)),
      child: Padding(
        padding: AppSpacing.sm.vertical,
        child: Row(
          spacing: AppSpacing.sm.value,
          children: [
            Expanded(
              child: Text(
                food.name,
                style: Theme.of(context).coletteTextStyles.body,
              ),
            ),
            if (status != null) Flexible(child: FoodStatusBadge(status: status)),
          ],
        ),
      ),
    );
  }
}
```

`widgets/food_catalog_sliver.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_overview_providers.dart';
import 'package:colette/features/diversification/presentation/widgets/food_row.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Catalogue filtré, en-tête par groupe OMS puis aliments.
class FoodCatalogSliver extends ConsumerWidget {
  const FoodCatalogSliver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(filteredCatalogProvider);
    final statuses = ref.watch(foodStatusesProvider);
    if (sections.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyState(
          icon: Icons.search_off,
          message: S.of(context).catalogEmpty,
        ),
      );
    }
    final entries = <Object>[
      for (final section in sections) ...[section.group, ...section.foods],
    ];
    return SliverList.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) => switch (entries[index]) {
        final FoodGroup group => _GroupHeader(group: group),
        final Food food => FoodRow(food: food, status: statuses[food.id]),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final FoodGroup group;

  @override
  Widget build(BuildContext context) => Padding(
    padding: AppSpacing.only(top: AppSpacing.md, bottom: AppSpacing.xs),
    child: Text(
      group.label(S.of(context)),
      style: Theme.of(context).coletteTextStyles.label.copyWith(
        color: context.appColor(AppColors.textSecondary),
      ),
    ),
  );
}
```

`pages/plate_page.dart` :

```dart
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/diversification_phase.dart';
import 'package:colette/features/diversification/presentation/providers/catalog_filter.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_overview_providers.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:colette/features/diversification/presentation/widgets/allergens_card.dart';
import 'package:colette/features/diversification/presentation/widgets/catalog_filter_chips.dart';
import 'package:colette/features/diversification/presentation/widgets/catalog_search_bar.dart';
import 'package:colette/features/diversification/presentation/widgets/custom_food_sheet.dart';
import 'package:colette/features/diversification/presentation/widgets/food_catalog_sliver.dart';
import 'package:colette/features/diversification/presentation/widgets/phase_header.dart';
import 'package:colette/features/diversification/presentation/widgets/preparation_card.dart';
import 'package:colette/features/diversification/presentation/widgets/retry_card.dart';
import 'package:colette/features/diversification/presentation/widgets/today_diversity_card.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onglet Assiette : phase, diversité du jour ou préparation, allergènes,
/// aliments à reproposer et catalogue.
class PlatePage extends ConsumerStatefulWidget {
  const PlatePage({super.key});

  @override
  ConsumerState<PlatePage> createState() => _PlatePageState();
}

class _PlatePageState extends ConsumerState<PlatePage> {
  final _catalogKey = GlobalKey();

  void _filterByAllergen(Allergen allergen) {
    ref.read(catalogFilterProvider.notifier).setAllergen(allergen);
    final target = _catalogKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(target, duration: AppDuration.normal.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final catalog = ref.watch(foodCatalogProvider);
    final timeline = ref.watch(diversificationTimelineProvider);
    final foods = ref.watch(foodsProvider).value ?? const {};
    final tastedCount = ref
        .watch(tastingCountsProvider)
        .keys
        .where(foods.containsKey)
        .length;
    return Scaffold(
      body: SafeArea(
        child: switch (catalog) {
          AsyncData() => CustomScrollView(
            slivers: [
              SliverPadding(
                padding: AppSpacing.md.all,
                sliver: SliverList.list(
                  children: [
                    const PhaseHeader(),
                    AppSpacing.md.verticalSpace,
                    if (timeline != null &&
                        timeline.phase == DiversificationPhase.preparation)
                      PreparationCard(timeline: timeline)
                    else
                      const TodayDiversityCard(),
                    AppSpacing.md.verticalSpace,
                    AllergensCard(onAllergenTap: _filterByAllergen),
                    const RetryCard(),
                    SectionHeader(
                      key: _catalogKey,
                      title: s.catalogTitle(tastedCount),
                      trailing: TextButton.icon(
                        onPressed: () => showCustomFoodSheet(context),
                        icon: const Icon(Icons.add),
                        label: Text(s.actionAdd),
                      ),
                    ),
                    const CatalogSearchBar(),
                    AppSpacing.sm.verticalSpace,
                    const CatalogFilterChips(),
                  ],
                ),
              ),
              SliverPadding(
                padding: AppSpacing.md.horizontal,
                sliver: const FoodCatalogSliver(),
              ),
              SliverToBoxAdapter(child: AppSpacing.xl.verticalSpace),
            ],
          ),
          AsyncError(:final error) => EmptyState(
            icon: Icons.error_outline,
            message: failureMessage(error, s),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}
```

- [x] **Step 4 : Vérifier le succès**

Run: `flutter test test/features/diversification/presentation/plate_page_test.dart`
Expected: PASS. En cas de texte trouvé deux fois (« Œuf » : puce allergène et fiche ; « À éviter » : puce filtre et badges), cibler la puce avec `find.widgetWithText(ChoiceChip, 'À éviter')` ou `find.descendant(of: find.byType(AllergensCard), matching: find.text('Œuf'))`.

- [x] **Step 5 : Commit**

```bash
dart format lib test && dart analyze
git add lib/l10n/app_fr.arb lib/features/diversification/presentation test/features/diversification/presentation/plate_page_test.dart
git commit -m "feat: page Assiette avec catalogue filtrable

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 17 : Fiche aliment, routeur et 4ᵉ onglet

**Files:**
- Modify: `lib/l10n/app_fr.arb`
- Create: `lib/features/diversification/presentation/widgets/tasting_history_sliver.dart`
- Create: `lib/features/diversification/presentation/pages/food_detail_page.dart`
- Modify: `lib/app/router/app_router.dart`
- Modify: `lib/app/main_shell.dart`
- Modify: `test/app/app_router_test.dart`
- Test: `test/features/diversification/presentation/food_detail_page_test.dart`

- [x] **Step 1 : Clés ARB**

```json
  "actionEdit": "Modifier",
  "foodDetailRules": "Repères",
  "foodDetailNoRules": "Aucun repère particulier pour cet aliment.",
  "foodDetailAllergens": "Allergènes",
  "foodDetailNoAllergen": "Aucun allergène majeur.",
  "foodDetailHistory": "Dégustations",
  "foodDetailNoTasting": "Pas encore goûté.",
  "foodDetailCustom": "Aliment ajouté par le foyer.",
  "foodDetailDeleteFood": "Supprimer cet aliment",
  "foodDetailDeleteFoodConfirm": "Supprimer « {name} » ?",
  "@foodDetailDeleteFoodConfirm": { "placeholders": { "name": { "type": "String" } } },
  "tastingDeleteConfirm": "Supprimer cette dégustation ?",
  "tastingReactionShort": "réaction"
```

Run: `flutter gen-l10n`

- [x] **Step 2 : Tests rouges**

`food_detail_page_test.dart` :

```dart
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/liking.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/presentation/pages/food_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';
import '../helpers/diversification_overrides.dart';

void main() {
  late MockTastingsRepository tastingsRepo;
  late MockCustomFoodsRepository foodsRepo;
  const kaki = Food(id: 'c1', name: 'Kaki séché', group: FoodGroup.vitaminAFruitsVeg, isCustom: true);

  setUpAll(registerDiversificationFallbacks);

  setUp(() => (tastingsRepo, foodsRepo) = succeedingRepositories());

  Future<void> pump(WidgetTester tester, String foodId, {List<Tasting> tastings = const []}) =>
      pumpApp(
        tester,
        FoodDetailPage(foodId: foodId),
        overrides: diversificationOverrides(
          tastings: tastings,
          customFoods: const [kaki],
          tastingsRepository: tastingsRepo,
          customFoodsRepository: foodsRepo,
        ),
      );

  testWidgets('aliment à éviter : statut, règle, pas de dégustation', (tester) async {
    await pump(tester, 'miel');
    expect(find.text('Miel'), findsOneWidget);
    expect(find.text('À éviter avant 1 an · OMS, Anses'), findsOneWidget);
    expect(find.text('Risque de botulisme infantile.'), findsOneWidget);
    expect(find.text('Aucun allergène majeur.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Pas encore goûté.'), 200);
  });

  testWidgets('historique et suppression d\'une dégustation', (tester) async {
    await pump(tester, 'carotte', tastings: [
      Tasting(id: 't1', foodId: 'carotte', at: DateTime(2027, 4, 10, 12, 5), liking: Liking.loved, note: 'Adore'),
    ]);
    await tester.scrollUntilVisible(find.text('Aimé · Adore'), 200);
    await tester.drag(find.text('Aimé · Adore'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer cette dégustation ?'), findsOneWidget);
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    verify(() => tastingsRepo.delete('ABCDEFGH', 't1')).called(1);
  });

  testWidgets('aliment perso sans dégustation : modifiable et supprimable', (tester) async {
    await pump(tester, 'c1');
    expect(find.byTooltip('Modifier'), findsOneWidget);
    expect(find.text('Aliment ajouté par le foyer.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Supprimer cet aliment'), 200);
    await tester.tap(find.text('Supprimer cet aliment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    verify(() => foodsRepo.delete('ABCDEFGH', 'c1')).called(1);
  });

  testWidgets('aliment perso goûté : pas de suppression', (tester) async {
    await pump(tester, 'c1', tastings: [Tasting(id: 't1', foodId: 'c1', at: DateTime(2027, 4, 1))]);
    expect(find.text('Supprimer cet aliment'), findsNothing);
  });

  testWidgets('aliment inconnu', (tester) async {
    await pump(tester, 'disparu');
    expect(find.text('Aliment inconnu'), findsOneWidget);
    expect(find.text('Noter une dégustation'), findsNothing);
  });
}
```

Dans `test/app/app_router_test.dart`, remplacer le second test par :

```dart
  testWidgets('avec un code foyer, l\'app démarre sur le shell 4 onglets', (
    tester,
  ) async {
    await pumpColetteApp(tester, code: 'ABCDEFGH');
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.text('Aujourd\'hui'), findsWidgets);
    expect(find.byType(OnboardingPage), findsNothing);
  });

  testWidgets('onglet Assiette puis fiche d\'un aliment du vrai catalogue', (
    tester,
  ) async {
    await pumpColetteApp(tester, code: 'ABCDEFGH');
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Assiette'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PlatePage), findsOneWidget);
    final plateScrollable = find
        .descendant(of: find.byType(PlatePage), matching: find.byType(Scrollable))
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
```

(avec les imports de `plate_page.dart` et `food_detail_page.dart`).

Run: `flutter test test/features/diversification/presentation/food_detail_page_test.dart test/app/app_router_test.dart`
Expected: FAIL.

- [x] **Step 3 : Implémentation**

`widgets/tasting_history_sliver.dart` :

```dart
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_overview_providers.dart';
import 'package:colette/features/diversification/presentation/providers/tasting_form_controller.dart';
import 'package:colette/features/diversification/presentation/widgets/tasting_form_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dégustations d'un aliment : tap pour modifier, balayage pour supprimer.
class TastingHistorySliver extends ConsumerWidget {
  const TastingHistorySliver({super.key, required this.food});

  final Food food;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tastings = ref.watch(tastingsForFoodProvider(food.id));
    if (tastings.isEmpty) {
      return SliverToBoxAdapter(
        child: Text(
          S.of(context).foodDetailNoTasting,
          style: Theme.of(context).coletteTextStyles.body.copyWith(
            color: context.appColor(AppColors.textSecondary),
          ),
        ),
      );
    }
    return SliverList.builder(
      itemCount: tastings.length,
      itemBuilder: (context, index) =>
          _TastingTile(food: food, tasting: tastings[index]),
    );
  }
}

class _TastingTile extends ConsumerWidget {
  const _TastingTile({required this.food, required this.tasting});

  final Food food;
  final Tasting tasting;

  Future<bool> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(s.tastingDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    final ok = await ref
        .read(tastingFormControllerProvider.notifier)
        .delete(tasting.id);
    if (!ok && context.mounted) {
      final error = ref.read(tastingFormControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failureMessage(error ?? s.errorUnknown, s))),
      );
    }
    return ok;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final details = [
      if (tasting.liking case final liking?) liking.label(s),
      if (tasting.hadReaction) s.tastingReactionShort,
      if (tasting.note case final note?) note,
    ].join(' · ');
    return Dismissible(
      key: ValueKey(tasting.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context, ref),
      background: Container(
        alignment: .centerRight,
        padding: AppSpacing.md.horizontal,
        color: context.appColor(AppColors.error),
        child: Icon(
          Icons.delete_outline,
          color: context.appColor(AppColors.onPrimary),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          tasting.hadReaction
              ? Icons.warning_amber
              : tasting.liking?.icon ?? Icons.restaurant_outlined,
          color: context.appColor(
            tasting.hadReaction ? AppColors.warning : AppColors.textSecondary,
          ),
        ),
        title: Text(formatDayAndTime(tasting.at)),
        subtitle: details.isEmpty ? null : Text(details),
        onTap: () => showTastingFormSheet(context, food: food, tasting: tasting),
      ),
    );
  }
}
```

(`failureMessage` prend un `Object` : si `error` est `null`, on passe un objet quelconque qui tombe dans la branche `_ => s.errorUnknown`.)

`pages/food_detail_page.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_status.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/features/diversification/presentation/providers/custom_food_controller.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_overview_providers.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:colette/features/diversification/presentation/providers/tasting_form_controller.dart';
import 'package:colette/features/diversification/presentation/widgets/custom_food_sheet.dart';
import 'package:colette/features/diversification/presentation/widgets/food_status_badge.dart';
import 'package:colette/features/diversification/presentation/widgets/rule_tile.dart';
import 'package:colette/features/diversification/presentation/widgets/tasting_form_sheet.dart';
import 'package:colette/features/diversification/presentation/widgets/tasting_history_sliver.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fiche d'un aliment : statut, repères sourcés, allergènes, dégustations.
class FoodDetailPage extends ConsumerWidget {
  const FoodDetailPage({super.key, required this.foodId});

  final String foodId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Garde les contrôleurs autoDispose vivants pendant les suppressions
    // lancées depuis l'historique ou le bouton de suppression.
    ref
      ..listen(tastingFormControllerProvider, (_, _) {})
      ..listen(customFoodControllerProvider, (_, _) {});
    return switch (ref.watch(foodsProvider)) {
      AsyncData(:final value) => _FoodDetailView(
        food: value[foodId] ?? Food.unknown(foodId),
      ),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.error_outline,
          message: failureMessage(error, S.of(context)),
        ),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class _FoodDetailView extends ConsumerWidget {
  const _FoodDetailView({required this.food});

  final Food food;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    final status = ref.watch(foodStatusesProvider)[food.id];
    final hasTastings = ref.watch(tastingsForFoodProvider(food.id)).isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(foodDisplayName(food, s)),
        actions: [
          if (food.isCustom)
            IconButton(
              tooltip: s.actionEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => showCustomFoodSheet(context, food: food),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: AppSpacing.md.all,
            sliver: SliverList.list(
              children: [
                Row(
                  spacing: AppSpacing.sm.value,
                  children: [
                    Expanded(
                      child: Text(
                        food.group.label(s),
                        style: styles.body.copyWith(color: secondary),
                      ),
                    ),
                    if (status != null)
                      Flexible(child: FoodStatusBadge(status: status)),
                  ],
                ),
                if (status is FoodStatusNotYetRecommended)
                  Text(
                    s.statusNotYetFrance,
                    style: styles.small.copyWith(color: secondary),
                  ),
                if (food.isCustom)
                  Text(
                    s.foodDetailCustom,
                    style: styles.small.copyWith(color: secondary),
                  ),
                if (!food.isUnknown) ...[
                  AppSpacing.md.verticalSpace,
                  FilledButton.icon(
                    onPressed: () => showTastingFormSheet(context, food: food),
                    icon: const Icon(Icons.add),
                    label: Text(s.actionAddTasting),
                  ),
                ],
                SectionHeader(title: s.foodDetailRules),
                if (food.rules.isEmpty)
                  Text(s.foodDetailNoRules, style: styles.body)
                else
                  for (final rule in food.rules) RuleTile(rule: rule),
                SectionHeader(title: s.foodDetailAllergens),
                Text(
                  food.allergens.isEmpty
                      ? s.foodDetailNoAllergen
                      : food.allergens.map((a) => a.label(s)).join(', '),
                  style: styles.body,
                ),
                SectionHeader(title: s.foodDetailHistory),
              ],
            ),
          ),
          SliverPadding(
            padding: AppSpacing.md.horizontal,
            sliver: TastingHistorySliver(food: food),
          ),
          if (food.isCustom && !hasTastings)
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.md.all,
                child: _DeleteFoodButton(food: food),
              ),
            ),
          SliverToBoxAdapter(child: AppSpacing.xl.verticalSpace),
        ],
      ),
    );
  }
}

class _DeleteFoodButton extends ConsumerWidget {
  const _DeleteFoodButton({required this.food});

  final Food food;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(s.foodDetailDeleteFoodConfirm(food.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await ref
        .read(customFoodControllerProvider.notifier)
        .delete(food.id);
    if (!context.mounted) return;
    if (ok) {
      await Navigator.of(context).maybePop();
      return;
    }
    final error = ref.read(customFoodControllerProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failureMessage(error ?? s.errorUnknown, s))),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextButton.icon(
    onPressed: () => _delete(context, ref),
    icon: Icon(Icons.delete_outline, color: context.appColor(AppColors.error)),
    label: Text(
      S.of(context).foodDetailDeleteFood,
      style: Theme.of(context).coletteTextStyles.label.copyWith(
        color: context.appColor(AppColors.error),
      ),
    ),
  );
}
```

`lib/app/router/app_router.dart` : ajouter l'import de `plate_page.dart` et `food_detail_page.dart`, passer le commentaire du routeur à « shell à quatre onglets », et insérer entre la branche Journal et la branche Réglages :

```dart
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.plate,
                builder: (_, _) => const PlatePage(),
                routes: [
                  GoRoute(
                    path: 'food/:foodId',
                    builder: (_, state) => FoodDetailPage(
                      foodId: state.pathParameters['foodId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
```

`lib/app/main_shell.dart` : commentaire « quatre onglets », et insérer entre Journal et Réglages :

```dart
          NavigationDestination(
            icon: const Icon(Icons.rice_bowl_outlined),
            selectedIcon: const Icon(Icons.rice_bowl),
            label: s.tabPlate,
          ),
```

Vérifier par `grep -rn "goBranch(\|currentIndex ==" lib test` qu'aucun code ne suppose l'index 2 pour Réglages (la navigation passe par les chemins `AppRoutes`).

- [x] **Step 4 : Vérifier le succès**

Run: `dart run build_runner build -d && flutter test`
Expected: PASS sur toute la suite.

- [x] **Step 5 : Commit**

```bash
dart format lib test && dart analyze
git add lib/l10n/app_fr.arb lib/features/diversification/presentation lib/app/router lib/app/main_shell.dart test/app/app_router_test.dart test/features/diversification/presentation/food_detail_page_test.dart
git commit -m "feat: fiche aliment et onglet Assiette dans la navigation

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 18 : Vérification finale, rendu clair / sombre, documentation

**Cette tâche est menée par le coordinateur.**

- [x] **Step 1 : Suite complète**

```bash
dart format lib test
dart analyze
flutter test
```

Expected: aucun fichier reformaté, `No issues found!`, tous les tests verts.

- [x] **Step 2 : Rendu clair et sombre**

Écrire un test jetable (non commité) `test/tmp_plate_render_test.dart` qui monte `PlatePage` puis `FoodDetailPage(foodId: 'arachide')` et la feuille Dégustation avec `diversificationOverrides(tastings: …)`, dans `MaterialApp(theme: ThemeService().light())` puis `.dark()`, à la taille iPhone 15 (`viewSize: Size(393, 852)`), et capture chaque écran avec `expectLater(find.byType(MaterialApp), matchesGoldenFile('/tmp/colette-plate-<nom>.png'))`. Lancer `flutter test --update-goldens test/tmp_plate_render_test.dart`, lire les PNG, corriger les défauts de contraste ou de débordement, puis supprimer le test.

- [x] **Step 3 : Aligner la spec**

Mettre à jour `docs/superpowers/specs/2026-09-23-diversification-design.md` avec les précisions listées en tête de ce plan : sous-titre sans âge, icône de précaution sur « Pas encore », `prepare` actif sans profil, tutoiement, `CatalogFilter`. Cocher les tâches du plan. Commit `docs:`.

- [ ] **Step 4 : Relecture du catalogue par Maxence**

Présenter à Maxence un résumé lisible du catalogue (interdits, précautions, âges, sources) et intégrer ses corrections avant de proposer le merge.

- [ ] **Step 5 : Proposer l'intégration**

Lister les branches en cours avec leur divergence et simuler le merge (`git merge-tree --write-tree main feat/diversification`), puis demander la validation à Maxence avant tout `merge --no-ff` sur `main`. Pas de push sans demande explicite.

**Écarts constatés à l'exécution (spec alignée) :** catalogue livré à 123 aliments (boisson au soja séparée, « siki », texte propre à la charcuterie crue, Anses sur les sodas, deux repères du guide) ; pas de règle `prepare` pour le sésame (absent des sources) ; tri des dégustations en mémoire ; règles échues masquées sur la fiche et règles actives seules, encadrées, dans la feuille ; bouton « Ajouter un aliment ».
