# Repères OMS et cible journalière ajustable — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ajouter une feuille « Repères OMS » (table par âge, règle au poids, ligne du jour surlignée) ouverte depuis la carte « Prochain biberon », et permettre d'y forcer une cible journalière fixe en ml qui remplace le calcul OMS.

**Architecture:** `CareSettings.dailyTargetMl: int?` (null = OMS) est lu par `ComputeFeedingPlan` via un paramètre `dailyTargetMlOverride` ; `FeedingPlan` expose en plus `omsTargetMl` et `isTargetOverridden`. La table par âge devient l'enum `FeedingAgeBand`, source unique. Un use case pur `ComputeFeedingReference` fournit ce que la feuille affiche. L'écriture passe par `BabySettingsController.updateCareSettings`, qui resynchronise déjà `feedingPlan` pour les Cloud Functions ; celles-ci ne changent pas.

**Tech Stack:** Flutter (freezed, Riverpod 3 codegen, fpdart, intl, mocktail, fake_cloud_firestore). Spec : `docs/superpowers/specs/2026-09-22-oms-feeding-reference-design.md`.

**Arbre de travail :** `Makefile` et `devtools_options.yaml` sont non suivis et n'appartiennent pas à ce chantier. Ne jamais faire `git add -A` ni `git add .` : stager uniquement les fichiers listés dans chaque tâche.

**Commandes récurrentes :**

- Génération : `dart run build_runner build -d` (après toute modification d'un fichier `@freezed` ou `@riverpod`).
- Localisations : `flutter gen-l10n` (après toute modification de `lib/l10n/app_fr.arb` ; le dossier `lib/l10n/generated` n'est pas suivi par git).
- Vérification : `dart format lib test`, `dart analyze`, `flutter test`.

---

### Tâche 1 : Domaine — enum `FeedingAgeBand`, source unique de la table par âge

**Files:**
- Create: `lib/features/dashboard/domain/entities/feeding_age_band.dart`
- Modify: `lib/features/dashboard/domain/use_cases/compute_feeding_plan.dart:66-72`
- Test: `test/features/dashboard/domain/feeding_age_band_test.dart`

- [x] **Étape 1 : test rouge**

Créer `test/features/dashboard/domain/feeding_age_band_test.dart` :

```dart
import 'package:colette/features/dashboard/domain/entities/feeding_age_band.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('jours 1 à 5 : une tranche par jour', () {
    expect(FeedingAgeBand.forDayOfLife(1), FeedingAgeBand.day1);
    expect(FeedingAgeBand.forDayOfLife(2), FeedingAgeBand.day2);
    expect(FeedingAgeBand.forDayOfLife(3), FeedingAgeBand.day3);
    expect(FeedingAgeBand.forDayOfLife(4), FeedingAgeBand.day4);
    expect(FeedingAgeBand.forDayOfLife(5), FeedingAgeBand.day5);
  });

  test('bornes des tranches suivantes', () {
    expect(FeedingAgeBand.forDayOfLife(6), FeedingAgeBand.day6ToMonth1);
    expect(FeedingAgeBand.forDayOfLife(30), FeedingAgeBand.day6ToMonth1);
    expect(FeedingAgeBand.forDayOfLife(31), FeedingAgeBand.month1To2);
    expect(FeedingAgeBand.forDayOfLife(60), FeedingAgeBand.month1To2);
    expect(FeedingAgeBand.forDayOfLife(61), FeedingAgeBand.month2To4);
    expect(FeedingAgeBand.forDayOfLife(120), FeedingAgeBand.month2To4);
    expect(FeedingAgeBand.forDayOfLife(121), FeedingAgeBand.month4To6);
    expect(FeedingAgeBand.forDayOfLife(180), FeedingAgeBand.month4To6);
    expect(FeedingAgeBand.forDayOfLife(181), FeedingAgeBand.month6Plus);
  });

  test('un jour de vie inférieur à 1 est traité comme le jour 1', () {
    expect(FeedingAgeBand.forDayOfLife(0), FeedingAgeBand.day1);
  });

  test('repères en ml par jour', () {
    expect(FeedingAgeBand.day1.dailyMl, 240);
    expect(FeedingAgeBand.day5.dailyMl, 480);
    expect(FeedingAgeBand.day6ToMonth1.dailyMl, 480);
    expect(FeedingAgeBand.month1To2.dailyMl, 630);
    expect(FeedingAgeBand.month2To4.dailyMl, 720);
    expect(FeedingAgeBand.month4To6.dailyMl, 900);
    expect(FeedingAgeBand.month6Plus.dailyMl, 900);
  });
}
```

- [x] **Étape 2 : vérifier l'échec**

Run: `flutter test test/features/dashboard/domain/feeding_age_band_test.dart`
Expected: échec de compilation, `feeding_age_band.dart` introuvable.

- [x] **Étape 3 : implémentation**

Créer `lib/features/dashboard/domain/entities/feeding_age_band.dart` :

```dart
/// Tranches d'âge des repères OMS : cible journalière indicative sans pesée.
enum FeedingAgeBand {
  day1(240),
  day2(320),
  day3(400),
  day4(440),
  day5(480),
  day6ToMonth1(480),
  month1To2(630),
  month2To4(720),
  month4To6(900),
  month6Plus(900);

  const FeedingAgeBand(this.dailyMl);

  /// Repère journalier en ml.
  final int dailyMl;

  /// Tranche d'un jour de vie (1 = jour de naissance).
  static FeedingAgeBand forDayOfLife(int dayOfLife) => switch (dayOfLife) {
    <= 1 => day1,
    2 => day2,
    3 => day3,
    4 => day4,
    5 => day5,
    <= 30 => day6ToMonth1,
    <= 60 => month1To2,
    <= 120 => month2To4,
    <= 180 => month4To6,
    _ => month6Plus,
  };
}
```

Dans `lib/features/dashboard/domain/use_cases/compute_feeding_plan.dart`, ajouter l'import `package:colette/features/dashboard/domain/entities/feeding_age_band.dart` et remplacer le corps de `dailyTargetFromAge` :

```dart
  /// Cible journalière indicative quand aucune pesée n'est connue.
  static int dailyTargetFromAge(int dayOfLife) =>
      FeedingAgeBand.forDayOfLife(dayOfLife).dailyMl;
```

- [x] **Étape 4 : vérifier le vert**

Run: `flutter test test/features/dashboard/domain/`
Expected: tous verts, y compris `compute_feeding_plan_test.dart` (le test « repères par âge sans pesée » garde les mêmes valeurs).

- [x] **Étape 5 : commit**

```bash
git add lib/features/dashboard/domain/entities/feeding_age_band.dart lib/features/dashboard/domain/use_cases/compute_feeding_plan.dart test/features/dashboard/domain/feeding_age_band_test.dart
git commit -m "feat: enum FeedingAgeBand, source unique des repères OMS par âge

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Tâche 2 : Domaine — cible ajustée dans `CareSettings`, `FeedingPlan` et `ComputeFeedingPlan`

**Files:**
- Modify: `lib/features/baby/domain/entities/care_settings.dart`
- Modify: `lib/features/dashboard/domain/entities/feeding_plan.dart`
- Modify: `lib/features/dashboard/domain/use_cases/compute_feeding_plan.dart`
- Test: `test/features/dashboard/domain/compute_feeding_plan_test.dart`

- [x] **Étape 1 : tests rouges**

Ajouter à la fin de `main()` dans `test/features/dashboard/domain/compute_feeding_plan_test.dart` :

```dart
  group('cible ajustée', () {
    test('remplace la cible OMS et pilote la suggestion', () {
      final bottle = makeEvent(
        id: 'a',
        startAt: DateTime(2026, 9, 10, 9),
        bottleMl: 60,
      );
      final plan = compute(
        birthDate: birth,
        latestWeightGrams: 4200,
        feedsPerDay: 8,
        todayBottles: [bottle],
        lastBottle: bottle,
        now: DateTime(2026, 9, 10, 12),
        dailyTargetMlOverride: 600,
      );
      expect(plan.dailyTargetMl, 600);
      expect(plan.omsTargetMl, 630);
      expect(plan.isTargetOverridden, isTrue);
      expect(plan.isEstimatedFromAge, isFalse);
      expect(plan.remainingMl, 540);
      // 540 / 7 = 77,1 → 80.
      expect(plan.suggestedMl, 80);
    });

    test('sans override, la cible effective est la cible OMS', () {
      final plan = compute(
        birthDate: birth,
        latestWeightGrams: 4200,
        feedsPerDay: 8,
        todayBottles: const [],
        lastBottle: null,
        now: DateTime(2026, 9, 10, 12),
      );
      expect(plan.dailyTargetMl, 630);
      expect(plan.omsTargetMl, 630);
      expect(plan.isTargetOverridden, isFalse);
    });

    test('override sans pesée : estimé par âge mais cible forcée', () {
      final plan = compute(
        birthDate: birth,
        latestWeightGrams: null,
        feedsPerDay: 8,
        todayBottles: const [],
        lastBottle: null,
        now: DateTime(2026, 9, 20, 12),
        dailyTargetMlOverride: 600,
      );
      expect(plan.dailyTargetMl, 600);
      expect(plan.omsTargetMl, 480);
      expect(plan.isEstimatedFromAge, isTrue);
      expect(plan.isTargetOverridden, isTrue);
    });
  });
```

- [x] **Étape 2 : vérifier l'échec**

Run: `flutter test test/features/dashboard/domain/compute_feeding_plan_test.dart`
Expected: échec de compilation, paramètre `dailyTargetMlOverride` inconnu.

- [x] **Étape 3 : `CareSettings`**

Remplacer le contenu de `lib/features/baby/domain/entities/care_settings.dart` :

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'care_settings.freezed.dart';

/// Fréquences des soins attendus chaque jour et cible de lait ajustée.
@freezed
abstract class CareSettings with _$CareSettings {
  const CareSettings._();

  const factory CareSettings({
    @Default(1) int adrigylPerDay,
    @Default(1) int eyeCarePerDay,
    @Default(1) int noseCarePerDay,
    @Default(3) int umbilicalCarePerDay,
    @Default(2) int bathEveryDays,
    @Default(8) int feedsPerDay,

    /// Cible journalière forcée en ml ; `null` = calcul OMS.
    int? dailyTargetMl,
  }) = _CareSettings;

  static const minDailyTargetMl = 100;
  static const maxDailyTargetMl = 1500;
  static const dailyTargetStepMl = 10;
}
```

- [x] **Étape 4 : `FeedingPlan`**

Dans `lib/features/dashboard/domain/entities/feeding_plan.dart`, remplacer la factory :

```dart
  const factory FeedingPlan({
    /// Cible effective : ajustée si renseignée, sinon OMS.
    required int dailyTargetMl,

    /// Cible calculée selon l'OMS, toujours disponible.
    required int omsTargetMl,
    required bool isTargetOverridden,
    required int feedsPerDay,
    required DateTime nextBottleAt,
    required int suggestedMl,
    required int bottlesGiven,
    required int givenMl,
    required bool isEstimatedFromAge,
  }) = _FeedingPlan;
```

- [x] **Étape 5 : `ComputeFeedingPlan`**

Dans `lib/features/dashboard/domain/use_cases/compute_feeding_plan.dart`, remplacer la méthode `call` :

```dart
  FeedingPlan call({
    required DateTime birthDate,
    required int? latestWeightGrams,
    required int feedsPerDay,
    required List<CareEvent> todayBottles,
    required CareEvent? lastBottle,
    required DateTime now,
    int? dailyTargetMlOverride,
  }) {
    final safeFeedsPerDay = max(1, feedsPerDay);
    final day = dayOfLife(birthDate, now);
    final (omsTargetMl, estimated) = switch (latestWeightGrams) {
      null => (dailyTargetFromAge(day), true),
      final grams => (roundTo10(mlPerKg(day) * grams / 1000), false),
    };
    final dailyTargetMl = dailyTargetMlOverride ?? omsTargetMl;
    final interval = Duration(minutes: (24 * 60 / safeFeedsPerDay).round());
    final nextBottleAt = lastBottle == null
        ? now
        : lastBottle.startAt.add(interval);
    final givenMl = todayBottles.fold(0, (sum, e) => sum + (e.bottleMl ?? 0));
    final bottlesGiven = todayBottles.length;
    final bottlesRemaining = max(0, safeFeedsPerDay - bottlesGiven);
    final remainingMl = max(0, dailyTargetMl - givenMl);
    final raw = bottlesRemaining > 0
        ? remainingMl / bottlesRemaining
        : dailyTargetMl / safeFeedsPerDay;
    final suggestedMl = roundTo10(raw).clamp(minSuggestedMl, maxSuggestedMl);
    return FeedingPlan(
      dailyTargetMl: dailyTargetMl,
      omsTargetMl: omsTargetMl,
      isTargetOverridden: dailyTargetMlOverride != null,
      feedsPerDay: safeFeedsPerDay,
      nextBottleAt: nextBottleAt,
      suggestedMl: suggestedMl,
      bottlesGiven: bottlesGiven,
      givenMl: givenMl,
      isEstimatedFromAge: estimated,
    );
  }
```

Et rendre l'arrondi public (il sera réutilisé par `ComputeFeedingReference` en Tâche 3) : remplacer `static int _roundTo10(double value) => (value / 10).round() * 10;` par

```dart
  /// Arrondi au multiple de 10 ml le plus proche.
  static int roundTo10(double value) => (value / 10).round() * 10;
```

Mettre à jour aussi le commentaire de classe :

```dart
/// Plan biberons selon l'OMS : 150 ml/kg/jour (montée progressive la 1re semaine),
/// réparti sur `feedsPerDay` prises ; repères par âge sans pesée.
/// Une cible ajustée (`dailyTargetMlOverride`) remplace la cible OMS.
///
/// `feedsPerDay` est borné à 1 minimum pour ne jamais diviser par zéro.
```

- [x] **Étape 6 : générer et vérifier le vert**

Run: `dart run build_runner build -d && flutter test test/features/dashboard/domain/ test/features/baby/`
Expected: build sans erreur ; tous les tests verts.

- [x] **Étape 7 : commit**

```bash
git add lib/features/baby/domain/entities/care_settings.dart lib/features/baby/domain/entities/care_settings.freezed.dart lib/features/dashboard/domain/entities/feeding_plan.dart lib/features/dashboard/domain/entities/feeding_plan.freezed.dart lib/features/dashboard/domain/use_cases/compute_feeding_plan.dart test/features/dashboard/domain/compute_feeding_plan_test.dart
git commit -m "feat: cible journalière ajustée dans CareSettings et ComputeFeedingPlan

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Tâche 3 : Domaine — `FeedingReference` et `ComputeFeedingReference`

**Files:**
- Create: `lib/features/dashboard/domain/entities/feeding_reference.dart`
- Create: `lib/features/dashboard/domain/use_cases/compute_feeding_reference.dart`
- Test: `test/features/dashboard/domain/compute_feeding_reference_test.dart`

- [x] **Étape 1 : test rouge**

Créer `test/features/dashboard/domain/compute_feeding_reference_test.dart` :

```dart
import 'package:colette/features/dashboard/domain/entities/feeding_age_band.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_feeding_reference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const compute = ComputeFeedingReference();
  final birth = DateTime(2026, 9, 1, 6);

  test('jour 3 sans pesée : 100 ml/kg, pas de calcul au poids', () {
    final reference = compute(
      birthDate: birth,
      latestWeightGrams: null,
      now: DateTime(2026, 9, 3, 12),
    );
    expect(reference.dayOfLife, 3);
    expect(reference.ageBand, FeedingAgeBand.day3);
    expect(reference.mlPerKg, 100);
    expect(reference.weightGrams, isNull);
    expect(reference.weightTargetMl, isNull);
  });

  test('jour 10 avec 4 200 g : 150 ml/kg, cible au poids 630', () {
    final reference = compute(
      birthDate: birth,
      latestWeightGrams: 4200,
      now: DateTime(2026, 9, 10, 12),
    );
    expect(reference.dayOfLife, 10);
    expect(reference.ageBand, FeedingAgeBand.day6ToMonth1);
    expect(reference.mlPerKg, 150);
    expect(reference.weightGrams, 4200);
    expect(reference.weightTargetMl, 630);
  });

  test('la cible au poids est arrondie à 10 ml', () {
    final reference = compute(
      birthDate: birth,
      latestWeightGrams: 3570,
      now: DateTime(2026, 9, 10, 12),
    );
    // 150 × 3,57 = 535,5 → 540.
    expect(reference.weightTargetMl, 540);
  });
}
```

- [x] **Étape 2 : vérifier l'échec**

Run: `flutter test test/features/dashboard/domain/compute_feeding_reference_test.dart`
Expected: échec de compilation, fichiers introuvables.

- [x] **Étape 3 : entité**

Créer `lib/features/dashboard/domain/entities/feeding_reference.dart` :

```dart
import 'package:colette/features/dashboard/domain/entities/feeding_age_band.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'feeding_reference.freezed.dart';

/// Repères OMS du jour : tranche d'âge, ml/kg et calcul au poids si pesée.
@freezed
abstract class FeedingReference with _$FeedingReference {
  const factory FeedingReference({
    required int dayOfLife,
    required FeedingAgeBand ageBand,
    required int mlPerKg,
    int? weightGrams,
    int? weightTargetMl,
  }) = _FeedingReference;
}
```

- [x] **Étape 4 : use case**

Créer `lib/features/dashboard/domain/use_cases/compute_feeding_reference.dart` :

```dart
import 'package:colette/features/dashboard/domain/entities/feeding_age_band.dart';
import 'package:colette/features/dashboard/domain/entities/feeding_reference.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_feeding_plan.dart';

/// Repères OMS du jour pour la feuille d'information.
class ComputeFeedingReference {
  const ComputeFeedingReference();

  FeedingReference call({
    required DateTime birthDate,
    required int? latestWeightGrams,
    required DateTime now,
  }) {
    final day = ComputeFeedingPlan.dayOfLife(birthDate, now);
    final mlPerKg = ComputeFeedingPlan.mlPerKg(day);
    return FeedingReference(
      dayOfLife: day,
      ageBand: FeedingAgeBand.forDayOfLife(day),
      mlPerKg: mlPerKg,
      weightGrams: latestWeightGrams,
      weightTargetMl: switch (latestWeightGrams) {
        null => null,
        final grams => ComputeFeedingPlan.roundTo10(mlPerKg * grams / 1000),
      },
    );
  }
}
```

- [x] **Étape 5 : générer et vérifier le vert**

Run: `dart run build_runner build -d && flutter test test/features/dashboard/domain/`
Expected: tous verts.

- [x] **Étape 6 : commit**

```bash
git add lib/features/dashboard/domain/entities/feeding_reference.dart lib/features/dashboard/domain/entities/feeding_reference.freezed.dart lib/features/dashboard/domain/use_cases/compute_feeding_reference.dart test/features/dashboard/domain/compute_feeding_reference_test.dart
git commit -m "feat: use case ComputeFeedingReference, repères OMS du jour

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Tâche 4 : Données — `dailyTargetMl` dans `CareSettingsDto`

**Files:**
- Modify: `lib/features/baby/data/dtos/baby_profile_dto.dart:5-45`
- Test: `test/features/baby/data/baby_profile_dto_test.dart`

- [x] **Étape 1 : tests rouges**

Ajouter à la fin de `main()` dans `test/features/baby/data/baby_profile_dto_test.dart` :

```dart
  group('dailyTargetMl', () {
    test('aller-retour avec une cible ajustée', () {
      const settings = CareSettings(dailyTargetMl: 600);
      final map = CareSettingsDto.toMap(settings);
      expect(map['dailyTargetMl'], 600);
      expect(CareSettingsDto.fromMap(map), settings);
    });

    test('absent ou invalide → null', () {
      expect(CareSettingsDto.fromMap(const {}).dailyTargetMl, isNull);
      expect(
        CareSettingsDto.fromMap(const {'dailyTargetMl': null}).dailyTargetMl,
        isNull,
      );
      expect(
        CareSettingsDto.fromMap(const {'dailyTargetMl': 'abc'}).dailyTargetMl,
        isNull,
      );
    });

    test('borné entre 100 et 1500', () {
      expect(
        CareSettingsDto.fromMap(const {'dailyTargetMl': 50}).dailyTargetMl,
        100,
      );
      expect(
        CareSettingsDto.fromMap(const {'dailyTargetMl': 9999}).dailyTargetMl,
        1500,
      );
    });

    test('toMap écrit null sans cible ajustée', () {
      final map = CareSettingsDto.toMap(const CareSettings());
      expect(map.containsKey('dailyTargetMl'), isTrue);
      expect(map['dailyTargetMl'], isNull);
    });
  });
```

- [x] **Étape 2 : vérifier l'échec**

Run: `flutter test test/features/baby/data/baby_profile_dto_test.dart`
Expected: les tests `aller-retour` et `borné` échouent (le champ n'est ni écrit ni lu).

- [x] **Étape 3 : implémentation**

Dans `lib/features/baby/data/dtos/baby_profile_dto.dart`, dans `CareSettingsDto.toMap`, ajouter après `'feedsPerDay': settings.feedsPerDay,` :

```dart
    'dailyTargetMl': settings.dailyTargetMl,
```

Ajouter après `_readInt` :

```dart
  /// Entier optionnel borné ; absent ou non numérique → `null`.
  static int? _readOptionalInt(
    Map<String, dynamic> map,
    String key, {
    required int min,
    required int max,
  }) {
    final raw = map[key];
    return raw is num ? raw.toInt().clamp(min, max) : null;
  }
```

Et dans `fromMap`, ajouter après `feedsPerDay: ...,` :

```dart
    dailyTargetMl: _readOptionalInt(
      map,
      'dailyTargetMl',
      min: CareSettings.minDailyTargetMl,
      max: CareSettings.maxDailyTargetMl,
    ),
```

- [x] **Étape 4 : vérifier le vert**

Run: `flutter test test/features/baby/`
Expected: tous verts.

- [x] **Étape 5 : commit**

```bash
git add lib/features/baby/data/dtos/baby_profile_dto.dart test/features/baby/data/baby_profile_dto_test.dart
git commit -m "feat: lecture et écriture bornées de dailyTargetMl dans CareSettingsDto

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Tâche 5 : Présentation — providers et synchronisation du plan

**Files:**
- Modify: `lib/features/dashboard/presentation/providers/dashboard_providers.dart`
- Modify: `lib/features/dashboard/presentation/providers/feeding_plan_sync.dart:55-62`
- Test: `test/features/dashboard/presentation/feeding_plan_sync_test.dart`

- [x] **Étape 1 : test rouge**

Ajouter avant le test `'sync n\'échoue pas sans profil'` dans `test/features/dashboard/presentation/feeding_plan_sync_test.dart` :

```dart
  test('sync utilise la cible ajustée du profil pour la suggestion', () async {
    final db = FakeFirebaseFirestore();
    final now = DateTime(2026, 9, 10, 12);
    final container = ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(FixedClock(now)),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(babyRepositoryProvider)
        .saveProfile(
          'ABCDEFGH',
          BabyProfile(
            name: 'Colette',
            birthDate: DateTime(2026, 9, 1),
            careSettings: const CareSettings(dailyTargetMl: 600),
          ),
        );
    final bottle = makeEvent(
      id: 'b',
      startAt: DateTime(2026, 9, 10, 9),
      bottleMl: 60,
    );
    await container.read(eventsRepositoryProvider).save('ABCDEFGH', bottle);

    await container.read(feedingPlanSyncProvider).sync();

    final data = (await db.collection('households').doc('ABCDEFGH').get())
        .data()!;
    final plan = data['feedingPlan'] as Map<String, dynamic>;
    // Sans pesée la cible OMS serait 480 (suggestion 60) ; avec 600 : (600 − 60) / 7 → 80.
    expect(plan['suggestedMl'], 80);
  });
```

Ajouter l'import `package:colette/features/baby/domain/entities/care_settings.dart` en tête du fichier.

- [x] **Étape 2 : vérifier l'échec**

Run: `flutter test test/features/dashboard/presentation/feeding_plan_sync_test.dart`
Expected: le nouveau test échoue, `suggestedMl` vaut 60.

- [x] **Étape 3 : `feeding_plan_sync.dart`**

Dans `FirestoreFeedingPlanSync.sync`, ajouter l'argument dans l'appel à `ComputeFeedingPlan` :

```dart
      final plan = const ComputeFeedingPlan()(
        birthDate: profile.birthDate,
        latestWeightGrams: weights.isEmpty ? null : weights.first.grams,
        feedsPerDay: profile.careSettings.feedsPerDay,
        todayBottles: today.where((e) => e.hasBottle).toList(),
        lastBottle: lastBottle,
        now: now,
        dailyTargetMlOverride: profile.careSettings.dailyTargetMl,
      );
```

- [x] **Étape 4 : `dashboard_providers.dart`**

Ajouter les imports :

```dart
import 'package:colette/features/dashboard/domain/entities/feeding_reference.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_feeding_reference.dart';
```

Dans `feedingPlan`, ajouter `dailyTargetMlOverride: profile.careSettings.dailyTargetMl,` après `now: ref.watch(currentMinuteProvider),`.

Ajouter après `feedingPlan` :

```dart
/// Repères OMS du jour ; `null` sans profil.
@riverpod
FeedingReference? feedingReference(Ref ref) {
  final profile = ref.watch(babyProfileProvider).value;
  if (profile == null) return null;
  return const ComputeFeedingReference()(
    birthDate: profile.birthDate,
    latestWeightGrams: ref.watch(latestWeightProvider)?.grams,
    now: ref.watch(currentMinuteProvider),
  );
}
```

- [x] **Étape 5 : générer et vérifier le vert**

Run: `dart run build_runner build -d && flutter test test/features/dashboard/`
Expected: tous verts.

- [x] **Étape 6 : commit**

```bash
git add lib/features/dashboard/presentation/providers/dashboard_providers.dart lib/features/dashboard/presentation/providers/dashboard_providers.g.dart lib/features/dashboard/presentation/providers/feeding_plan_sync.dart test/features/dashboard/presentation/feeding_plan_sync_test.dart
git commit -m "feat: cible ajustée transmise au plan et provider feedingReference

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Tâche 6 : Présentation — feuille « Repères OMS » avec cible ajustable

**Files:**
- Modify: `lib/l10n/app_fr.arb:59-60`
- Create: `lib/features/dashboard/presentation/widgets/feeding_reference_sheet.dart`
- Create: `lib/features/dashboard/presentation/widgets/feeding_target_section.dart`
- Test: `test/features/dashboard/presentation/feeding_reference_sheet_test.dart`

- [x] **Étape 1 : clés l10n**

Dans `lib/l10n/app_fr.arb`, insérer après la ligne `"feedingPlanUnavailable": ...,` :

```json
  "feedingPlanAdjusted": "Cible ajustée à {ml} ml · OMS : {oms} ml",
  "@feedingPlanAdjusted": { "placeholders": { "ml": { "type": "int" }, "oms": { "type": "int" } } },
  "feedingReferenceTooltip": "Voir les repères OMS",
  "feedingReferenceTitle": "Repères OMS",
  "feedingReferenceSource": "D'après l'OMS : 150 ml par kg et par jour dès le 6e jour, montée progressive avant. Repères indicatifs, la pédiatre a le dernier mot.",
  "feedingReferenceAgeTitle": "Repères par âge",
  "feedingReferenceWeightTitle": "Règle au poids",
  "feedingDayOfLife": "Jour {day}",
  "@feedingDayOfLife": { "placeholders": { "day": { "type": "int" } } },
  "feedingAgeBandDay6ToMonth1": "Jour 6 à 1 mois",
  "feedingAgeBandMonth1To2": "1 à 2 mois",
  "feedingAgeBandMonth2To4": "2 à 4 mois",
  "feedingAgeBandMonth4To6": "4 à 6 mois",
  "feedingAgeBandMonth6Plus": "6 mois et plus",
  "feedingWeightRuleDay6Plus": "Jour 6 et plus",
  "feedingMlPerDay": "{ml} ml / jour",
  "@feedingMlPerDay": { "placeholders": { "ml": { "type": "int" } } },
  "feedingMlPerKg": "{ml} ml / kg",
  "@feedingMlPerKg": { "placeholders": { "ml": { "type": "int" } } },
  "feedingWeightCalc": "{mlPerKg} ml/kg × {kg} kg = {ml} ml",
  "@feedingWeightCalc": { "placeholders": { "mlPerKg": { "type": "int" }, "kg": { "type": "String" }, "ml": { "type": "int" } } },
  "feedingTargetTitle": "Cible journalière",
  "feedingTargetOms": "Calcul OMS : {ml} ml",
  "@feedingTargetOms": { "placeholders": { "ml": { "type": "int" } } },
  "feedingTargetAdjust": "Ajuster",
  "feedingTargetAdjusted": "Cible ajustée",
  "feedingTargetReset": "Revenir au calcul OMS",
```

Run: `flutter gen-l10n`
Expected: aucune erreur ; `S.of(context).feedingReferenceTitle` disponible.

- [x] **Étape 2 : test rouge**

Créer `test/features/dashboard/presentation/feeding_reference_sheet_test.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/dashboard/presentation/widgets/feeding_reference_sheet.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

class MockBabyRepository extends Mock implements BabyRepository {}

void main() {
  final now = DateTime(2026, 9, 10, 12);
  final profile = BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1));

  setUpAll(() => registerFallbackValue(profile));

  List<Override> overridesFor(
    MockBabyRepository repo, {
    BabyProfile? baby,
    int? weightGrams = 4200,
  }) => [
    clockProvider.overrideWithValue(FixedClock(now)),
    minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
    householdLocalStoreProvider.overrideWithValue(
      InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
    ),
    babyRepositoryProvider.overrideWithValue(repo),
    babyProfileProvider.overrideWith((ref) => Stream.value(baby ?? profile)),
    weightsProvider.overrideWith(
      (ref) => Stream.value([
        if (weightGrams != null)
          WeightEntry(
            id: 'w',
            measuredAt: DateTime(2026, 9, 9),
            grams: weightGrams,
          ),
      ]),
    ),
    todayEventsProvider.overrideWith((ref) => Stream.value(const [])),
    latestBottleProvider.overrideWith((ref) => Stream.value(null)),
    feedingPlanSyncProvider.overrideWithValue(const NoopFeedingPlanSync()),
  ];

  bool isHighlighted(WidgetTester tester, String label) {
    final container = find
        .ancestor(of: find.text(label), matching: find.byType(Container))
        .first;
    final decoration =
        tester.widget<Container>(container).decoration as BoxDecoration?;
    return decoration?.color != null;
  }

  testWidgets('surligne la ligne du jour et montre le calcul au poids', (
    tester,
  ) async {
    final repo = MockBabyRepository();
    await pumpApp(
      tester,
      const Scaffold(body: FeedingReferenceSheet()),
      overrides: overridesFor(repo),
    );
    expect(find.text('Repères OMS'), findsOneWidget);
    expect(find.text('Jour 6 à 1 mois'), findsOneWidget);
    expect(isHighlighted(tester, 'Jour 6 à 1 mois'), isTrue);
    expect(isHighlighted(tester, '1 à 2 mois'), isFalse);
    expect(isHighlighted(tester, 'Jour 6 et plus'), isTrue);
    expect(isHighlighted(tester, 'Jour 1'), isFalse);
    expect(find.text('150 ml/kg × 4,2 kg = 630 ml'), findsOneWidget);
    expect(find.text('Calcul OMS : 630 ml'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Ajuster'), findsOneWidget);
  });

  testWidgets('sans pesée, invite à ajouter une pesée', (tester) async {
    final repo = MockBabyRepository();
    await pumpApp(
      tester,
      const Scaffold(body: FeedingReferenceSheet()),
      overrides: overridesFor(repo, weightGrams: null),
    );
    expect(
      find.text('Repères par âge : ajoute une pesée pour un calcul au poids.'),
      findsOneWidget,
    );
    expect(find.textContaining('× '), findsNothing);
  });

  testWidgets('Ajuster pose la cible OMS, + ajoute 10, Revenir remet null', (
    tester,
  ) async {
    final repo = MockBabyRepository();
    when(() => repo.saveProfile(any(), any()))
        .thenAnswer((_) async => right(null));
    await pumpApp(
      tester,
      const Scaffold(body: FeedingReferenceSheet()),
      overrides: overridesFor(repo),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Ajuster'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Revenir au calcul OMS'));
    await tester.pumpAndSettle();

    final saved = verify(() => repo.saveProfile('ABCDEFGH', captureAny()))
        .captured
        .cast<BabyProfile>();
    expect(
      saved.map((p) => p.careSettings.dailyTargetMl).toList(),
      [630, 640, null],
    );
    expect(find.widgetWithText(FilledButton, 'Ajuster'), findsOneWidget);
  });

  testWidgets('une cible déjà ajustée affiche le stepper', (tester) async {
    final repo = MockBabyRepository();
    await pumpApp(
      tester,
      const Scaffold(body: FeedingReferenceSheet()),
      overrides: overridesFor(
        repo,
        baby: profile.copyWith(
          careSettings: const CareSettings(dailyTargetMl: 600),
        ),
      ),
    );
    expect(find.text('Cible ajustée'), findsOneWidget);
    expect(find.text('600 ml'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Ajuster'), findsNothing);
  });

  testWidgets('une erreur d\'écriture affiche un SnackBar', (tester) async {
    final repo = MockBabyRepository();
    when(() => repo.saveProfile(any(), any()))
        .thenAnswer((_) async => left(const NetworkFailure()));
    await pumpApp(
      tester,
      const Scaffold(body: FeedingReferenceSheet()),
      overrides: overridesFor(repo),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Ajuster'));
    await tester.pumpAndSettle();
    expect(
      find.text('Pas de connexion. Réessaie dans un instant.'),
      findsOneWidget,
    );
  });
}
```

- [x] **Étape 3 : vérifier l'échec**

Run: `flutter test test/features/dashboard/presentation/feeding_reference_sheet_test.dart`
Expected: échec de compilation, `feeding_reference_sheet.dart` introuvable.

- [x] **Étape 4 : section cible ajustable**

Créer `lib/features/dashboard/presentation/widgets/feeding_target_section.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/int_stepper_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cible journalière : calcul OMS, ou stepper quand elle est ajustée.
/// Tient une copie locale optimiste, comme `CareSettingsSection`.
class FeedingTargetSection extends ConsumerStatefulWidget {
  const FeedingTargetSection({
    super.key,
    required this.profile,
    required this.omsTargetMl,
  });

  final BabyProfile profile;
  final int omsTargetMl;

  @override
  ConsumerState<FeedingTargetSection> createState() =>
      _FeedingTargetSectionState();
}

class _FeedingTargetSectionState extends ConsumerState<FeedingTargetSection> {
  late int? _target = widget.profile.careSettings.dailyTargetMl;

  @override
  void didUpdateWidget(covariant FeedingTargetSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.profile.careSettings.dailyTargetMl;
    final writing = ref.read(babySettingsControllerProvider).isLoading;
    if (incoming != oldWidget.profile.careSettings.dailyTargetMl && !writing) {
      _target = incoming;
    }
  }

  void _write(int? target) {
    setState(() => _target = target);
    ref
        .read(babySettingsControllerProvider.notifier)
        .updateCareSettings(
          widget.profile,
          widget.profile.careSettings.copyWith(dailyTargetMl: target),
        );
  }

  @override
  Widget build(BuildContext context) {
    // Garde le contrôleur autoDispose vivant pendant l'await de updateCareSettings.
    ref.watch(babySettingsControllerProvider);
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final target = _target;
    return Column(
      crossAxisAlignment: .start,
      spacing: AppSpacing.sm.value,
      children: [
        Text(
          s.feedingTargetTitle,
          style: styles.heading3.copyWith(
            color: context.appColor(AppColors.textSecondary),
          ),
        ),
        Text(s.feedingTargetOms(widget.omsTargetMl), style: styles.body),
        if (target == null)
          FilledButton(
            onPressed: () => _write(widget.omsTargetMl),
            child: Text(s.feedingTargetAdjust),
          )
        else ...[
          IntStepperRow(
            label: s.feedingTargetAdjusted,
            value: target,
            min: CareSettings.minDailyTargetMl,
            max: CareSettings.maxDailyTargetMl,
            step: CareSettings.dailyTargetStepMl,
            suffix: s.unitMl,
            onChanged: _write,
          ),
          TextButton(
            onPressed: () => _write(null),
            child: Text(s.feedingTargetReset),
          ),
        ],
      ],
    );
  }
}
```

- [x] **Étape 5 : feuille**

Créer `lib/features/dashboard/presentation/widgets/feeding_reference_sheet.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/features/dashboard/domain/entities/feeding_age_band.dart';
import 'package:colette/features/dashboard/domain/entities/feeding_reference.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_feeding_plan.dart';
import 'package:colette/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:colette/features/dashboard/presentation/widgets/feeding_target_section.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Ouvre la feuille « Repères OMS ».
Future<void> showFeedingReferenceSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const FeedingReferenceSheet(),
    );

/// Repères OMS par âge et au poids, ligne du jour surlignée, cible ajustable.
class FeedingReferenceSheet extends ConsumerWidget {
  const FeedingReferenceSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    ref.listen(babySettingsControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failureMessage(error, s))));
      }
    });
    final profile = ref.watch(babyProfileProvider).value;
    final reference = ref.watch(feedingReferenceProvider);
    final plan = ref.watch(feedingPlanProvider);
    if (profile == null || reference == null || plan == null) {
      return const SizedBox.shrink();
    }
    final styles = Theme.of(context).coletteTextStyles;
    return ListView(
      shrinkWrap: true,
      padding: AppSpacing.lg.all,
      children: [
        Text(s.feedingReferenceTitle, style: styles.heading2),
        AppSpacing.xs.verticalSpace,
        Text(
          s.feedingReferenceSource,
          style: styles.small.copyWith(
            color: context.appColor(AppColors.textSecondary),
          ),
        ),
        AppSpacing.lg.verticalSpace,
        _AgeTableSection(current: reference.ageBand),
        AppSpacing.lg.verticalSpace,
        _WeightRuleSection(reference: reference),
        AppSpacing.lg.verticalSpace,
        FeedingTargetSection(profile: profile, omsTargetMl: plan.omsTargetMl),
      ],
    );
  }
}

class _AgeTableSection extends StatelessWidget {
  const _AgeTableSection({required this.current});

  final FeedingAgeBand current;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: .start,
      spacing: AppSpacing.xs.value,
      children: [
        _SectionTitle(s.feedingReferenceAgeTitle),
        for (final band in FeedingAgeBand.values)
          _ReferenceRow(
            label: _bandLabel(s, band),
            value: s.feedingMlPerDay(band.dailyMl),
            highlighted: band == current,
          ),
      ],
    );
  }

  static String _bandLabel(S s, FeedingAgeBand band) => switch (band) {
    FeedingAgeBand.day1 => s.feedingDayOfLife(1),
    FeedingAgeBand.day2 => s.feedingDayOfLife(2),
    FeedingAgeBand.day3 => s.feedingDayOfLife(3),
    FeedingAgeBand.day4 => s.feedingDayOfLife(4),
    FeedingAgeBand.day5 => s.feedingDayOfLife(5),
    FeedingAgeBand.day6ToMonth1 => s.feedingAgeBandDay6ToMonth1,
    FeedingAgeBand.month1To2 => s.feedingAgeBandMonth1To2,
    FeedingAgeBand.month2To4 => s.feedingAgeBandMonth2To4,
    FeedingAgeBand.month4To6 => s.feedingAgeBandMonth4To6,
    FeedingAgeBand.month6Plus => s.feedingAgeBandMonth6Plus,
  };
}

class _WeightRuleSection extends StatelessWidget {
  const _WeightRuleSection({required this.reference});

  /// Jour de vie à partir duquel le plafond de 150 ml/kg s'applique.
  static const plateauDay = 6;

  final FeedingReference reference;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final grams = reference.weightGrams;
    final weightTargetMl = reference.weightTargetMl;
    return Column(
      crossAxisAlignment: .start,
      spacing: AppSpacing.xs.value,
      children: [
        _SectionTitle(s.feedingReferenceWeightTitle),
        for (var day = 1; day < plateauDay; day++)
          _ReferenceRow(
            label: s.feedingDayOfLife(day),
            value: s.feedingMlPerKg(ComputeFeedingPlan.mlPerKg(day)),
            highlighted: reference.dayOfLife == day,
          ),
        _ReferenceRow(
          label: s.feedingWeightRuleDay6Plus,
          value: s.feedingMlPerKg(ComputeFeedingPlan.mlPerKg(plateauDay)),
          highlighted: reference.dayOfLife >= plateauDay,
        ),
        Text(
          grams == null || weightTargetMl == null
              ? s.feedingPlanEstimated
              : s.feedingWeightCalc(
                  reference.mlPerKg,
                  NumberFormat('0.0', 'fr').format(grams / 1000),
                  weightTargetMl,
                ),
          style: styles.bodyMedium.copyWith(
            color: context.appColor(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(context).coletteTextStyles.heading3.copyWith(
      color: context.appColor(AppColors.textSecondary),
    ),
  );
}

/// Ligne « libellé … valeur », surlignée quand c'est celle du jour.
class _ReferenceRow extends StatelessWidget {
  const _ReferenceRow({
    required this.label,
    required this.value,
    required this.highlighted,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).coletteTextStyles;
    return Container(
      padding: AppSpacing.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? context.appColor(AppColors.primaryContainer)
            : null,
        borderRadius: AppRadius.sm.circular,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: highlighted ? styles.bodyMedium : styles.body,
            ),
          ),
          Text(
            value,
            style: styles.numberMedium.copyWith(
              color: context.appColor(
                highlighted ? AppColors.primary : AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [x] **Étape 6 : vérifier le vert**

Run: `flutter test test/features/dashboard/presentation/feeding_reference_sheet_test.dart`
Expected: 5 tests verts. Si le test du SnackBar échoue parce que le message n'apparaît pas, vérifier que `pumpApp` monte bien un `MaterialApp` (il fournit le `ScaffoldMessenger`) et que `pumpAndSettle` est appelé après le tap.

- [x] **Étape 7 : format, analyse, commit**

Run: `dart format lib test && dart analyze`
Expected: aucune erreur ni avertissement.

```bash
git add lib/l10n/app_fr.arb lib/features/dashboard/presentation/widgets/feeding_reference_sheet.dart lib/features/dashboard/presentation/widgets/feeding_target_section.dart test/features/dashboard/presentation/feeding_reference_sheet_test.dart
git commit -m "feat: feuille Repères OMS avec cible journalière ajustable

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Tâche 7 : Présentation — icône info et mention « Cible ajustée » sur la carte

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/next_bottle_card.dart`
- Test: `test/features/dashboard/presentation/dashboard_page_test.dart`

- [x] **Étape 1 : tests rouges**

Dans `test/features/dashboard/presentation/dashboard_page_test.dart`, ajouter l'import `package:colette/features/baby/domain/entities/care_settings.dart`, puis donner à `overridesFor` un paramètre `baby` :

```dart
  List<Override> overridesFor(
    MockEventsRepository repo, {
    List<CareEvent>? recent,
    BabyProfile? baby,
  }) => [
    clockProvider.overrideWithValue(FixedClock(now)),
    minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
    householdLocalStoreProvider.overrideWithValue(
      InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
    ),
    babyProfileProvider.overrideWith((ref) => Stream.value(baby ?? profile)),
    weightsProvider.overrideWith(
      (ref) => Stream.value([
        WeightEntry(id: 'w', measuredAt: DateTime(2026, 9, 9), grams: 3600),
      ]),
    ),
    todayEventsProvider.overrideWith((ref) => Stream.value([adrigyl, bottle])),
    recentEventsProvider.overrideWith(
      (ref) => Stream.value(recent ?? [adrigyl, bottle, lateBottle]),
    ),
    latestBottleProvider.overrideWith((ref) => Stream.value(bottle)),
    latestBathProvider.overrideWith((ref) => Stream.value(null)),
    eventsRepositoryProvider.overrideWithValue(repo),
    idGeneratorProvider.overrideWithValue(const FixedIdGenerator('e-new')),
    feedingPlanSyncProvider.overrideWithValue(const NoopFeedingPlanSync()),
  ];
```

Ajouter à la fin de `main()` :

```dart
  testWidgets('avec une cible ajustée, la carte l\'indique et la suggestion suit', (
    tester,
  ) async {
    final repo = MockEventsRepository();
    await pumpApp(
      tester,
      const DashboardPage(),
      overrides: overridesFor(
        repo,
        baby: profile.copyWith(
          careSettings: const CareSettings(dailyTargetMl: 600),
        ),
      ),
    );
    // (600 − 60) / 7 = 77,1 → 80 ; cible OMS : 150 × 3,6 = 540.
    expect(find.text('80 ml'), findsOneWidget);
    expect(find.text('Cible ajustée à 600 ml · OMS : 540 ml'), findsOneWidget);
  });

  testWidgets('sans cible ajustée, aucune mention d\'ajustement', (
    tester,
  ) async {
    final repo = MockEventsRepository();
    await pumpApp(
      tester,
      const DashboardPage(),
      overrides: overridesFor(repo),
    );
    expect(find.textContaining('Cible ajustée'), findsNothing);
  });

  testWidgets('l\'icône info ouvre la feuille Repères OMS', (tester) async {
    final repo = MockEventsRepository();
    await pumpApp(
      tester,
      const DashboardPage(),
      overrides: overridesFor(repo),
    );
    await tester.tap(find.byTooltip('Voir les repères OMS'));
    await tester.pumpAndSettle();
    expect(find.text('Repères OMS'), findsOneWidget);
    expect(find.text('Repères par âge'), findsOneWidget);
  });
```

- [x] **Étape 2 : vérifier l'échec**

Run: `flutter test test/features/dashboard/presentation/dashboard_page_test.dart`
Expected: les trois nouveaux tests échouent (« 80 ml » existe déjà grâce à la Tâche 5, mais la mention et l'icône manquent).

- [x] **Étape 3 : carte**

Dans `lib/features/dashboard/presentation/widgets/next_bottle_card.dart`, ajouter l'import :

```dart
import 'package:colette/features/dashboard/presentation/widgets/feeding_reference_sheet.dart';
```

Remplacer le premier `Text(s.nextBottleTitle, ...)` de la colonne par une ligne titre + icône :

```dart
          Row(
            children: [
              Expanded(
                child: Text(
                  s.nextBottleTitle,
                  style: styles.overline.copyWith(
                    color: context.appColor(AppColors.primary),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => showFeedingReferenceSheet(context),
                icon: const Icon(Icons.info_outline),
                color: context.appColor(AppColors.textSecondary),
                tooltip: s.feedingReferenceTooltip,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
```

Remplacer le bloc final `if (plan.isEstimatedFromAge) Text(...)` par :

```dart
          if (plan.isTargetOverridden)
            Text(
              s.feedingPlanAdjusted(plan.dailyTargetMl, plan.omsTargetMl),
              style: styles.small.copyWith(
                color: context.appColor(AppColors.textSecondary),
              ),
            )
          else if (plan.isEstimatedFromAge)
            Text(
              s.feedingPlanEstimated,
              style: styles.small.copyWith(
                color: context.appColor(AppColors.textSecondary),
              ),
            ),
```

- [x] **Étape 4 : vérifier le vert**

Run: `flutter test test/features/dashboard/`
Expected: tous verts, y compris le test existant « affiche l'âge, le prochain biberon… » (le titre « Prochain biberon » reste trouvé une fois).

- [x] **Étape 5 : format, analyse, commit**

Run: `dart format lib test && dart analyze`
Expected: aucune erreur.

```bash
git add lib/features/dashboard/presentation/widgets/next_bottle_card.dart test/features/dashboard/presentation/dashboard_page_test.dart
git commit -m "feat: icône Repères OMS et mention de cible ajustée sur la carte Prochain biberon

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Tâche 8 : Documentation et vérification finale

**Files:**
- Modify: `docs/superpowers/specs/2026-09-21-colette-v1-design.md:270-299`
- Modify: `docs/superpowers/specs/2026-09-22-oms-feeding-reference-design.md:85`

- [x] **Étape 1 : spec v1**

Dans `docs/superpowers/specs/2026-09-21-colette-v1-design.md`, après le paragraphe qui commence par « La carte affiche en complément le nombre de biberons… » (§6.3), ajouter :

```markdown
La table par âge est portée par l'enum `FeedingAgeBand`, source unique. Une cible journalière ajustée (`careSettings.dailyTargetMl`, `null` = OMS) remplace la cible OMS dans le calcul ; la carte affiche alors « Cible ajustée à X ml · OMS : Y ml ». Une feuille « Repères OMS », ouverte par une icône info sur la carte, montre la table par âge, la règle ml/kg, la ligne du jour et permet d'ajuster la cible. Le snapshot `feedingPlan` garde la même forme ; voir `2026-09-22-oms-feeding-reference-design.md`.
```

- [x] **Étape 2 : spec de la fonctionnalité**

Dans `docs/superpowers/specs/2026-09-22-oms-feeding-reference-design.md`, dans la liste « Fichiers touchés », remplacer la ligne `lib/l10n/app_fr.arb` par :

```markdown
- `lib/l10n/app_fr.arb` : `feedingPlanAdjusted(ml, oms)`, `feedingReferenceTooltip`, `feedingReferenceTitle`, `feedingReferenceSource`, `feedingReferenceAgeTitle`, `feedingReferenceWeightTitle`, `feedingDayOfLife(day)` (jours 1 à 5, dans les deux tables), `feedingAgeBandDay6ToMonth1`, `feedingAgeBandMonth1To2`, `feedingAgeBandMonth2To4`, `feedingAgeBandMonth4To6`, `feedingAgeBandMonth6Plus`, `feedingWeightRuleDay6Plus`, `feedingMlPerDay(ml)`, `feedingMlPerKg(ml)`, `feedingWeightCalc(mlPerKg, kg, ml)`, `feedingTargetTitle`, `feedingTargetOms(ml)`, `feedingTargetAdjust`, `feedingTargetAdjusted`, `feedingTargetReset`.
```

Et dans la même liste, remplacer la ligne `feeding_reference_sheet.dart (nouveau)` par :

```markdown
- `lib/features/dashboard/presentation/widgets/feeding_reference_sheet.dart` (nouveau) : feuille, table par âge, règle au poids.
- `lib/features/dashboard/presentation/widgets/feeding_target_section.dart` (nouveau) : `FeedingTargetSection`, cible ajustable avec état local optimiste.
```

- [x] **Étape 3 : vérification complète**

Run: `dart run build_runner build -d && flutter gen-l10n && dart format lib test && dart analyze && flutter test`
Expected: build sans erreur, `dart format` ne modifie aucun fichier, `dart analyze` sans problème, tous les tests verts.

- [ ] **Étape 4 : vérification sur simulateur**

Lancer l'app sur un simulateur iPhone (`flutter run` ou le tool simulateur), avec un foyer existant :

1. Sur l'onglet Aujourd'hui, la carte « Prochain biberon » montre une icône info à droite du titre ; taper la carte ouvre toujours le formulaire biberon.
2. Taper l'icône ouvre la feuille : deux tables, ligne du jour surlignée, calcul au poids si une pesée existe.
3. « Ajuster » fait apparaître le stepper à la valeur OMS ; « + » et « − » avancent par 10 ; la carte derrière reflète la nouvelle cible et la mention « Cible ajustée à … ».
4. « Revenir au calcul OMS » remet la carte dans son état initial.
5. Passer en thème sombre (Réglages › Apparence) : la ligne surlignée reste lisible.

- [x] **Étape 5 : commit**

```bash
git add docs/superpowers/specs/2026-09-21-colette-v1-design.md docs/superpowers/specs/2026-09-22-oms-feeding-reference-design.md
git commit -m "docs: spec v1 et spec OMS alignées sur l'implémentation des repères et de la cible ajustée

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```
