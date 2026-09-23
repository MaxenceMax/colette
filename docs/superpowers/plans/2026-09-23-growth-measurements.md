# Mesures de croissance : plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Saisir taille et périmètre crânien avec le poids dans une même « mesure », et afficher chaque grandeur sur une page « Croissance » à onglets avec ses repères OMS.

**Architecture:** Les documents `households/{code}/weights/{id}` gagnent `lengthMm?` et `headCircumferenceMm?` (`grams` devient facultatif), sans migration. Le domaine remplace `WeightEntry` par `GrowthMeasurement` et paramètre tendance, références OMS et courbe par un enum `GrowthMetric`. La migration se fait par étapes : les nouveaux types sont ajoutés à côté des anciens, les consommateurs basculent un par un, puis l'ancien code est supprimé (tâche 10).

**Tech Stack:** Flutter (iOS), Riverpod 3 codegen, freezed, fpdart, cloud_firestore + fake_cloud_firestore, fl_chart, mocktail.

**Spec:** `docs/superpowers/specs/2026-09-23-growth-measurements-design.md`.

---

## Conventions pour chaque tâche

- Travailler dans le worktree `/Users/maxencemontet/Documents/colette/.claude/worktrees/growth-measurements` (branche `feat/growth-measurements`). Ne jamais toucher au checkout principal. Jamais de `git stash` nu.
- Après toute modification d'un fichier annoté (`@freezed`, `@riverpod`) : `dart run build_runner build -d`. Les `.g.dart` et `.freezed.dart` sont versionnés : les ajouter au commit.
- Après toute modification de `lib/l10n/app_fr.arb` : `flutter gen-l10n` (le dossier `lib/l10n/generated` n'est pas versionné).
- Avant chaque commit : `dart format lib test`, `dart analyze` (0 problème), puis les tests de la tâche ; `flutter test` complet en fin de tâche.
- Commits : `git add` de fichiers ciblés, message en français, terminé par la ligne `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Règles du projet : `CLAUDE.md` (tokens de design, `S.of(context)`, `switch` sur `AsyncValue`, `///` sur chaque classe publique, fichiers < 300 lignes).

## Carte des fichiers

Créés :

| Fichier | Rôle |
| --- | --- |
| `lib/features/baby/domain/reference/who_lms.dart` | Typedef `WhoLms` commun aux tables OMS. |
| `lib/features/baby/domain/reference/who_length_for_age.dart` | Table LMS OMS taille couchée pour l'âge (généré). |
| `lib/features/baby/domain/reference/who_head_circumference_for_age.dart` | Table LMS OMS périmètre crânien pour l'âge (généré). |
| `lib/features/baby/domain/entities/growth_measurement.dart` | Entité `GrowthMeasurement`. |
| `lib/features/baby/domain/entities/growth_metric.dart` | Enum `GrowthMetric`, typedef `GrowthPoint`. |
| `lib/features/baby/domain/entities/growth_trend.dart` | Entité `GrowthTrend`. |
| `lib/features/baby/domain/entities/who_percentiles.dart` | Entité `WhoPercentiles`. |
| `lib/features/baby/domain/use_cases/validate_growth_measurement.dart` | Bornes et mesure vide. |
| `lib/features/baby/domain/use_cases/compute_growth_trend.dart` | Tendance d'une grandeur. |
| `lib/features/baby/domain/use_cases/compute_who_reference.dart` | P3 / P50 / P97 OMS d'une grandeur. |
| `lib/features/baby/data/dtos/growth_measurement_dto.dart` | Mapper Firestore. |
| `lib/features/baby/presentation/providers/selected_growth_metric.dart` | Onglet choisi sur la page Croissance. |
| `lib/features/baby/presentation/widgets/growth_format.dart` | Textes des valeurs (« 54,5 cm »). |
| `lib/features/baby/presentation/widgets/growth_input.dart` | Conversion des saisies. |
| `lib/features/baby/presentation/widgets/growth_chart_scale.dart` | Remplace `weight_chart_scale.dart`. |
| `lib/features/baby/presentation/widgets/growth_chart.dart` | Remplace `weight_chart.dart`. |
| `lib/features/baby/presentation/widgets/growth_trend_summary.dart` | Remplace `weight_trend_summary.dart`. |
| `lib/features/baby/presentation/widgets/growth_measurement_sheet.dart` | Remplace `add_weight_sheet.dart`. |
| `lib/features/baby/presentation/widgets/measurements_section.dart` | Remplace `weights_section.dart`. |
| `lib/features/baby/presentation/pages/growth_page.dart` | Remplace `weight_curve_page.dart`. |

Supprimés à la fin : `weight_entry.dart`, `weight_trend.dart`, `who_weight_percentiles.dart` (et leurs `.freezed.dart`), `compute_weight_trend.dart`, `compute_who_weight_reference.dart`, `weight_entry_dto.dart`, ainsi que les widgets et la page remplacés.

---

### Task 1 : tables OMS taille et périmètre crânien

**Files:**
- Create: `lib/features/baby/domain/reference/who_lms.dart`
- Create (généré): `lib/features/baby/domain/reference/who_length_for_age.dart`, `lib/features/baby/domain/reference/who_head_circumference_for_age.dart`
- Modify: `lib/features/baby/domain/reference/who_weight_for_age.dart:1-6`, `lib/features/baby/domain/use_cases/compute_who_weight_reference.dart:1-6`
- Test: `test/features/baby/domain/who_reference_tables_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/baby/domain/who_reference_tables_test.dart
import 'package:colette/features/baby/domain/reference/who_head_circumference_for_age.dart';
import 'package:colette/features/baby/domain/reference/who_length_for_age.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('731 jours par sexe pour la taille et le périmètre', () {
    for (final table in [
      whoLengthForAgeGirls,
      whoLengthForAgeBoys,
      whoHeadCircumferenceForAgeGirls,
      whoHeadCircumferenceForAgeBoys,
    ]) {
      expect(table, hasLength(731));
    }
  });

  test('premier et dernier jour conformes aux fichiers OMS', () {
    expect(whoLengthForAgeBoys.first, (1.0, 49.8842, 0.03795));
    expect(whoLengthForAgeGirls.first, (1.0, 49.1477, 0.0379));
    expect(whoLengthForAgeBoys.last, (1.0, 87.8018, 0.03479));
    expect(whoLengthForAgeGirls.last, (1.0, 86.4008, 0.03733));
    expect(whoHeadCircumferenceForAgeBoys.first, (1.0, 34.4618, 0.03686));
    expect(whoHeadCircumferenceForAgeGirls.first, (1.0, 33.8787, 0.03496));
    expect(whoHeadCircumferenceForAgeBoys.last, (1.0, 48.2494, 0.02821));
    expect(whoHeadCircumferenceForAgeGirls.last, (1.0, 47.1799, 0.02958));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/baby/domain/who_reference_tables_test.dart`
Expected: FAIL, fichiers `who_length_for_age.dart` / `who_head_circumference_for_age.dart` introuvables.

- [ ] **Step 3: Extraire le typedef commun**

Créer `lib/features/baby/domain/reference/who_lms.dart` :

```dart
/// Paramètres LMS OMS : `(L, M, S)`, M dans l'unité de la table (kg ou cm),
/// indexés par jour de vie.
typedef WhoLms = (double, double, double);
```

Dans `who_weight_for_age.dart`, remplacer les lignes 1 à 9 (en-tête, doc + `typedef WhoLms = …`, doc des filles et ouverture de la liste) par ce qui suit ; les valeurs ne changent pas :

```dart
// Généré depuis `data-raw/growthstandards/weianthro.txt` du dépôt
// WorldHealthOrganization/anthro (standards de croissance OMS 2006),
// jours 0 à 730. Ne pas modifier à la main.

import 'package:colette/features/baby/domain/reference/who_lms.dart';

/// Filles, jours 0 à 730 : `(L, M en kg, S)` du poids pour l'âge.
const whoWeightForAgeGirls = <WhoLms>[
```

Et remplacer `/// Garçons, jours 0 à 730.` par `/// Garçons, jours 0 à 730 : \`(L, M en kg, S)\` du poids pour l'âge.`

Dans `compute_who_weight_reference.dart`, ajouter l'import `import 'package:colette/features/baby/domain/reference/who_lms.dart';` (le type `WhoLms` y est utilisé par `_grams`).

- [ ] **Step 4: Générer les deux tables**

Depuis la racine du worktree :

```bash
mkdir -p /tmp/who
for f in lenanthro hcanthro; do
  curl -sfL -o /tmp/who/$f.txt "https://raw.githubusercontent.com/WorldHealthOrganization/anthro/master/data-raw/growthstandards/$f.txt"
done
gen() {
  # $1 fichier OMS, $2 fichier Dart, $3 préfixe des constantes, $4 grandeur
  local src=/tmp/who/$1.txt out=lib/features/baby/domain/reference/$2.dart
  {
    printf '%s\n' "// Généré depuis \`data-raw/growthstandards/$1.txt\` du dépôt" \
      '// WorldHealthOrganization/anthro (standards de croissance OMS 2006),' \
      '// jours 0 à 730. Ne pas modifier à la main.' '' \
      "import 'package:colette/features/baby/domain/reference/who_lms.dart';" ''
    for sex in 2 1; do
      if [ "$sex" = 2 ]; then label=Filles; name=${3}Girls; else label=Garçons; name=${3}Boys; fi
      printf '%s\n' "/// $label, jours 0 à 730 : \`(L, M en cm, S)\` $4 pour l'âge." "const $name = <WhoLms>["
      tr -d '\r' < "$src" | awk -v sex="$sex" \
        'function d(x) { return index(x, ".") ? x : x ".0" }
         NR > 1 && $1 == sex && $2 <= 730 { printf "  (%s, %s, %s),\n", d($3), d($4), d($5) }'
      printf '%s\n' '];' ''
    done
  } > "$out"
}
gen lenanthro who_length_for_age whoLengthForAge 'de la taille couchée'
gen hcanthro who_head_circumference_for_age whoHeadCircumferenceForAge 'du périmètre crânien'
dart format lib/features/baby/domain/reference
```

Les fichiers OMS sont en CRLF (d'où `tr -d '\r'`) ; `sex` vaut 1 pour les garçons, 2 pour les filles ; L vaut 1 sur toute la plage 0-730 (écrit `1.0` par `d()` pour rester un littéral `double`).

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/features/baby/domain/who_reference_tables_test.dart test/features/baby/domain/compute_who_weight_reference_test.dart`
Expected: PASS.

- [ ] **Step 6: Analyze and commit**

```bash
dart analyze
git add lib/features/baby/domain/reference test/features/baby/domain/who_reference_tables_test.dart lib/features/baby/domain/use_cases/compute_who_weight_reference.dart
git commit -m "feat: tables OMS de la taille et du périmètre crânien pour l'âge

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2 : entité `GrowthMeasurement`, enum `GrowthMetric` et validation

**Files:**
- Create: `lib/features/baby/domain/entities/growth_measurement.dart`, `lib/features/baby/domain/entities/growth_metric.dart`, `lib/features/baby/domain/use_cases/validate_growth_measurement.dart`
- Modify: `lib/core/result/failure.dart:2-12`, `lib/core/ui/failure_message.dart:9-19`, `lib/l10n/app_fr.arb` (après `errorInvalidWeight`)
- Test: `test/features/baby/domain/growth_metric_test.dart`, `test/features/baby/domain/validate_growth_measurement_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/baby/domain/growth_metric_test.dart
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final full = GrowthMeasurement(
    id: 'a',
    measuredAt: DateTime(2026, 9, 2),
    grams: 3200,
    lengthMm: 520,
    headCircumferenceMm: 350,
  );
  final weightOnly = GrowthMeasurement(
    id: 'b',
    measuredAt: DateTime(2026, 9, 10),
    grams: 3470,
  );
  final lengthOnly = GrowthMeasurement(
    id: 'c',
    measuredAt: DateTime(2026, 9, 14),
    lengthMm: 540,
  );

  test('valueOf lit la grandeur demandée', () {
    expect(GrowthMetric.weight.valueOf(full), 3200);
    expect(GrowthMetric.length.valueOf(full), 520);
    expect(GrowthMetric.headCircumference.valueOf(full), 350);
    expect(GrowthMetric.length.valueOf(weightOnly), isNull);
  });

  test('seriesOf garde les mesures de la grandeur, de la plus ancienne à la plus récente', () {
    final series = GrowthMetric.length.seriesOf([lengthOnly, weightOnly, full]);
    expect(series, [
      (at: DateTime(2026, 9, 2), value: 520),
      (at: DateTime(2026, 9, 14), value: 540),
    ]);
  });

  test('latestOf ignore les mesures sans la grandeur', () {
    final measurements = [lengthOnly, weightOnly, full];
    expect(GrowthMetric.weight.latestOf(measurements), weightOnly);
    expect(GrowthMetric.length.latestOf(measurements), lengthOnly);
    expect(GrowthMetric.headCircumference.latestOf([weightOnly]), isNull);
  });
}
```

```dart
// test/features/baby/domain/validate_growth_measurement_test.dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/either_extensions.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/domain/use_cases/validate_growth_measurement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validate = ValidateGrowthMeasurement();

  GrowthMeasurement measurement({int? grams, int? lengthMm, int? headMm}) =>
      GrowthMeasurement(
        id: 'm',
        measuredAt: DateTime(2026, 9, 10),
        grams: grams,
        lengthMm: lengthMm,
        headCircumferenceMm: headMm,
      );

  ValidationReason? reasonOf(GrowthMeasurement m) =>
      validate(m).leftOrNull?.reason;

  test('refuse une mesure sans aucune valeur', () {
    expect(reasonOf(measurement()), ValidationReason.emptyMeasurement);
  });

  test('accepte une mesure partielle', () {
    final onlyLength = measurement(lengthMm: 545);
    expect(validate(onlyLength).getRight().toNullable(), onlyLength);
  });

  test('bornes du poids : 1 000 à 20 000 g', () {
    expect(reasonOf(measurement(grams: 999)), ValidationReason.invalidWeight);
    expect(reasonOf(measurement(grams: 1000)), isNull);
    expect(reasonOf(measurement(grams: 20000)), isNull);
    expect(reasonOf(measurement(grams: 20001)), ValidationReason.invalidWeight);
  });

  test('bornes de la taille : 30 à 120 cm', () {
    expect(reasonOf(measurement(lengthMm: 299)), ValidationReason.invalidLength);
    expect(reasonOf(measurement(lengthMm: 300)), isNull);
    expect(reasonOf(measurement(lengthMm: 1200)), isNull);
    expect(
      reasonOf(measurement(lengthMm: 1201)),
      ValidationReason.invalidLength,
    );
  });

  test('bornes du périmètre crânien : 25 à 60 cm', () {
    expect(
      reasonOf(measurement(headMm: 249)),
      ValidationReason.invalidHeadCircumference,
    );
    expect(reasonOf(measurement(headMm: 250)), isNull);
    expect(reasonOf(measurement(headMm: 600)), isNull);
    expect(
      reasonOf(measurement(headMm: 601)),
      ValidationReason.invalidHeadCircumference,
    );
  });

  test('une saisie illisible (-1) est refusée pour son champ', () {
    expect(
      reasonOf(measurement(grams: 3600, lengthMm: -1)),
      ValidationReason.invalidLength,
    );
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/baby/domain/growth_metric_test.dart test/features/baby/domain/validate_growth_measurement_test.dart`
Expected: FAIL (fichiers introuvables).

- [ ] **Step 3: Écrire l'entité et l'enum**

```dart
// lib/features/baby/domain/entities/growth_measurement.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'growth_measurement.freezed.dart';

/// Une mesure de croissance : poids, taille et/ou périmètre crânien relevés
/// le même jour. Au moins une valeur est renseignée.
@freezed
abstract class GrowthMeasurement with _$GrowthMeasurement {
  const factory GrowthMeasurement({
    required String id,
    required DateTime measuredAt,
    int? grams,
    int? lengthMm,
    int? headCircumferenceMm,
  }) = _GrowthMeasurement;
}
```

```dart
// lib/features/baby/domain/entities/growth_metric.dart
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';

/// Point d'une série de croissance : date et valeur (grammes ou millimètres).
typedef GrowthPoint = ({DateTime at, int value});

/// Grandeur suivie : poids en grammes, taille et périmètre crânien en millimètres.
enum GrowthMetric {
  weight,
  length,
  headCircumference;

  /// Valeur de [measurement] pour cette grandeur, `null` si elle n'a pas été mesurée.
  int? valueOf(GrowthMeasurement measurement) => switch (this) {
    GrowthMetric.weight => measurement.grams,
    GrowthMetric.length => measurement.lengthMm,
    GrowthMetric.headCircumference => measurement.headCircumferenceMm,
  };

  /// Points des mesures qui contiennent cette grandeur, du plus ancien au plus récent.
  List<GrowthPoint> seriesOf(Iterable<GrowthMeasurement> measurements) => [
    for (final m in measurements)
      if (valueOf(m) case final value?) (at: m.measuredAt, value: value),
  ]..sort((a, b) => a.at.compareTo(b.at));

  /// Mesure la plus récente qui contient cette grandeur, ou `null`.
  GrowthMeasurement? latestOf(Iterable<GrowthMeasurement> measurements) {
    GrowthMeasurement? latest;
    for (final m in measurements) {
      if (valueOf(m) == null) continue;
      if (latest == null || m.measuredAt.isAfter(latest.measuredAt)) {
        latest = m;
      }
    }
    return latest;
  }
}
```

- [ ] **Step 4: Ajouter les raisons de validation, messages et use case**

Dans `lib/core/result/failure.dart`, compléter l'enum :

```dart
enum ValidationReason {
  emptyEvent,
  endBeforeStart,
  startInFuture,
  bottleOutOfRange,
  invalidWeight,
  emptyName,
  unknownHouseholdCode,
  notificationsDenied,
  invalidDiaperCount,
  emptyMeasurement,
  invalidLength,
  invalidHeadCircumference,
}
```

Dans `lib/l10n/app_fr.arb`, juste après la ligne `"errorInvalidWeight": …,` :

```json
  "errorEmptyMeasurement": "Renseigne au moins une valeur.",
  "errorInvalidLength": "La taille doit être entre 30 et 120 cm.",
  "errorInvalidHeadCircumference": "Le périmètre crânien doit être entre 25 et 60 cm.",
```

Dans `lib/core/ui/failure_message.dart`, après `ValidationReason.invalidDiaperCount => s.errorInvalidDiaperCount,` :

```dart
    ValidationReason.emptyMeasurement => s.errorEmptyMeasurement,
    ValidationReason.invalidLength => s.errorInvalidLength,
    ValidationReason.invalidHeadCircumference =>
      s.errorInvalidHeadCircumference,
```

```dart
// lib/features/baby/domain/use_cases/validate_growth_measurement.dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:fpdart/fpdart.dart';

/// Règles de validité d'une mesure de croissance avant enregistrement.
class ValidateGrowthMeasurement {
  const ValidateGrowthMeasurement();

  static const minWeightGrams = 1000;
  static const maxWeightGrams = 20000;
  static const minLengthMm = 300;
  static const maxLengthMm = 1200;
  static const minHeadCircumferenceMm = 250;
  static const maxHeadCircumferenceMm = 600;

  Either<ValidationFailure, GrowthMeasurement> call(GrowthMeasurement m) {
    if (m.grams == null && m.lengthMm == null && m.headCircumferenceMm == null) {
      return left(const ValidationFailure(ValidationReason.emptyMeasurement));
    }
    if (_outside(m.grams, minWeightGrams, maxWeightGrams)) {
      return left(const ValidationFailure(ValidationReason.invalidWeight));
    }
    if (_outside(m.lengthMm, minLengthMm, maxLengthMm)) {
      return left(const ValidationFailure(ValidationReason.invalidLength));
    }
    if (_outside(
      m.headCircumferenceMm,
      minHeadCircumferenceMm,
      maxHeadCircumferenceMm,
    )) {
      return left(
        const ValidationFailure(ValidationReason.invalidHeadCircumference),
      );
    }
    return right(m);
  }

  static bool _outside(int? value, int min, int max) =>
      value != null && (value < min || value > max);
}
```

- [ ] **Step 5: Generate and run tests**

```bash
dart run build_runner build -d
flutter gen-l10n
flutter test test/features/baby/domain/growth_metric_test.dart test/features/baby/domain/validate_growth_measurement_test.dart
```
Expected: PASS.

- [ ] **Step 6: Analyze, full tests, commit**

```bash
dart format lib test && dart analyze && flutter test
git add lib/features/baby/domain/entities/growth_measurement.dart lib/features/baby/domain/entities/growth_measurement.freezed.dart lib/features/baby/domain/entities/growth_metric.dart lib/features/baby/domain/use_cases/validate_growth_measurement.dart lib/core/result/failure.dart lib/core/ui/failure_message.dart lib/l10n/app_fr.arb test/features/baby/domain/growth_metric_test.dart test/features/baby/domain/validate_growth_measurement_test.dart
git commit -m "feat: mesure de croissance, grandeurs suivies et validation des bornes

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3 : tendance d'une grandeur (`ComputeGrowthTrend`)

**Files:**
- Create: `lib/features/baby/domain/entities/growth_trend.dart`, `lib/features/baby/domain/use_cases/compute_growth_trend.dart`
- Test: `test/features/baby/domain/compute_growth_trend_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/baby/domain/compute_growth_trend_test.dart
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:colette/features/baby/domain/use_cases/compute_growth_trend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const compute = ComputeGrowthTrend();

  GrowthMeasurement weight(String id, DateTime at, int grams) =>
      GrowthMeasurement(id: id, measuredAt: at, grams: grams);

  test('aucune mesure : pas de tendance', () {
    expect(compute(GrowthMetric.weight, const []), isNull);
  });

  test('une seule pesée : dernière valeur sans précédente', () {
    final trend = compute(GrowthMetric.weight, [
      weight('a', DateTime(2026, 9, 10), 3400),
    ])!;
    expect(trend.metric, GrowthMetric.weight);
    expect(trend.latestValue, 3400);
    expect(trend.latestAt, DateTime(2026, 9, 10));
    expect(trend.previousValue, isNull);
    expect(trend.delta, isNull);
    expect(trend.days, isNull);
    expect(trend.perDay, isNull);
  });

  test('compare les deux pesées les plus récentes, quel que soit l\'ordre', () {
    final trend = compute(GrowthMetric.weight, [
      weight('old', DateTime(2026, 9, 2), 3200),
      weight('last', DateTime(2026, 9, 14), 3650),
      weight('prev', DateTime(2026, 9, 10), 3470),
    ])!;
    expect(trend.latestValue, 3650);
    expect(trend.previousValue, 3470);
    expect(trend.delta, 180);
    expect(trend.days, 4);
    expect(trend.perDay, 45);
  });

  test('une perte donne un écart négatif', () {
    final trend = compute(GrowthMetric.weight, [
      weight('a', DateTime(2026, 9, 1), 3500),
      weight('b', DateTime(2026, 9, 4), 3290),
    ])!;
    expect(trend.delta, -210);
    expect(trend.perDay, -70);
  });

  test('ignore une autre mesure du même jour que la dernière', () {
    final trend = compute(GrowthMetric.weight, [
      weight('a', DateTime(2026, 9, 1), 3500),
      weight('b', DateTime(2026, 9, 5), 3600),
      weight('c', DateTime(2026, 9, 5, 18), 3620),
    ])!;
    expect(trend.latestValue, 3620);
    expect(trend.previousValue, 3500);
    expect(trend.days, 4);
    expect(trend.perDay, 30);
  });

  test('toutes les mesures le même jour : pas de précédente', () {
    final trend = compute(GrowthMetric.weight, [
      weight('a', DateTime(2026, 9, 5, 8), 3500),
      weight('b', DateTime(2026, 9, 5, 18), 3520),
    ])!;
    expect(trend.latestValue, 3520);
    expect(trend.previousValue, isNull);
  });

  test('arrondit le gain journalier', () {
    final trend = compute(GrowthMetric.weight, [
      weight('a', DateTime(2026, 9, 1), 3500),
      weight('b', DateTime(2026, 9, 4), 3600),
    ])!;
    expect(trend.perDay, 33);
  });

  test('compte les jours civils malgré le changement d\'heure', () {
    final trend = compute(GrowthMetric.weight, [
      weight('a', DateTime(2026, 10, 24), 3500),
      weight('b', DateTime(2026, 10, 26), 3560),
    ])!;
    expect(trend.days, 2);
  });

  test('taille : ignore les mesures sans taille', () {
    final measurements = [
      GrowthMeasurement(
        id: 'a',
        measuredAt: DateTime(2026, 9, 2),
        grams: 3200,
        lengthMm: 520,
      ),
      weight('b', DateTime(2026, 9, 10), 3470),
      GrowthMeasurement(
        id: 'c',
        measuredAt: DateTime(2026, 9, 20),
        lengthMm: 545,
      ),
    ];
    final trend = compute(GrowthMetric.length, measurements)!;
    expect(trend.metric, GrowthMetric.length);
    expect(trend.latestValue, 545);
    expect(trend.previousValue, 520);
    expect(trend.previousAt, DateTime(2026, 9, 2));
    expect(trend.delta, 25);
    expect(trend.days, 18);
  });

  test('périmètre absent de toutes les mesures : pas de tendance', () {
    expect(
      compute(GrowthMetric.headCircumference, [
        weight('a', DateTime(2026, 9, 2), 3200),
      ]),
      isNull,
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/baby/domain/compute_growth_trend_test.dart`
Expected: FAIL (fichiers introuvables).

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/baby/domain/entities/growth_trend.dart
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'growth_trend.freezed.dart';

/// Dernière valeur d'une grandeur et évolution depuis la valeur d'un jour précédent.
@freezed
abstract class GrowthTrend with _$GrowthTrend {
  const factory GrowthTrend({
    required GrowthMetric metric,
    required int latestValue,
    required DateTime latestAt,
    int? previousValue,
    DateTime? previousAt,
  }) = _GrowthTrend;

  const GrowthTrend._();

  /// Écart depuis la valeur précédente, négatif en cas de baisse.
  int? get delta => switch (previousValue) {
    final previous? => latestValue - previous,
    null => null,
  };

  /// Jours civils écoulés depuis la valeur précédente, au moins 1.
  int? get days => switch (previousAt) {
    final previous? => calendarDaysBetween(previous, latestAt),
    null => null,
  };

  /// Écart moyen par jour, arrondi ; affiché pour le poids seulement.
  int? get perDay => switch ((delta, days)) {
    (final delta?, final days?) => (delta / days).round(),
    _ => null,
  };
}
```

```dart
// lib/features/baby/domain/use_cases/compute_growth_trend.dart
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:colette/features/baby/domain/entities/growth_trend.dart';

/// Dernière valeur d'une grandeur comparée à la plus récente d'un jour civil antérieur.
class ComputeGrowthTrend {
  const ComputeGrowthTrend();

  GrowthTrend? call(GrowthMetric metric, List<GrowthMeasurement> measurements) {
    final series = metric.seriesOf(measurements);
    if (series.isEmpty) return null;
    final latest = series.last;
    final latestDay = latest.at.dateOnly;
    final previous = series.where((p) => p.at.isBefore(latestDay)).lastOrNull;
    return GrowthTrend(
      metric: metric,
      latestValue: latest.value,
      latestAt: latest.at,
      previousValue: previous?.value,
      previousAt: previous?.at,
    );
  }
}
```

- [ ] **Step 4: Generate and run test**

```bash
dart run build_runner build -d
flutter test test/features/baby/domain/compute_growth_trend_test.dart
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
dart format lib test && dart analyze
git add lib/features/baby/domain/entities/growth_trend.dart lib/features/baby/domain/entities/growth_trend.freezed.dart lib/features/baby/domain/use_cases/compute_growth_trend.dart test/features/baby/domain/compute_growth_trend_test.dart
git commit -m "feat: tendance d'une grandeur de croissance

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4 : références OMS par grandeur (`ComputeWhoReference`)

**Files:**
- Create: `lib/features/baby/domain/entities/who_percentiles.dart`, `lib/features/baby/domain/use_cases/compute_who_reference.dart`
- Test: `test/features/baby/domain/compute_who_reference_test.dart`

- [ ] **Step 1: Write the failing test**

Valeurs attendues calculées depuis les fichiers OMS (`M × (1 ± S × 1,880794)` quand L = 1), arrondies au millimètre.

```dart
// test/features/baby/domain/compute_who_reference_test.dart
import 'package:colette/features/baby/domain/entities/baby_sex.dart';
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:colette/features/baby/domain/entities/who_percentiles.dart';
import 'package:colette/features/baby/domain/use_cases/compute_who_reference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const compute = ComputeWhoReference();
  final birth = DateTime(2026, 9, 1);

  WhoPercentiles at(GrowthMetric metric, BabySex sex, DateTime day) => compute(
    metric: metric,
    sex: sex,
    birthDate: birth,
    from: day,
    to: day,
  ).single;

  (int, int, int) values(WhoPercentiles p) => (p.p3, p.p50, p.p97);

  test('poids, garçon à la naissance : grammes des tables OMS', () {
    final p = at(GrowthMetric.weight, BabySex.male, birth);
    expect(p.ageDays, 0);
    expect(p.date, birth);
    expect(values(p), (2507, 3346, 4350));
  });

  test('poids, fille à 30 jours', () {
    final p = at(GrowthMetric.weight, BabySex.female, DateTime(2026, 10, 1));
    expect(p.ageDays, 30);
    expect(values(p), (3203, 4172, 5371));
  });

  test('taille en millimètres : garçon à la naissance, fille à 30 jours', () {
    expect(values(at(GrowthMetric.length, BabySex.male, birth)), (463, 499, 534));
    expect(
      values(at(GrowthMetric.length, BabySex.female, DateTime(2026, 10, 1))),
      (500, 536, 573),
    );
  });

  test('périmètre crânien en millimètres : garçon à la naissance, fille à 730 jours', () {
    expect(
      values(at(GrowthMetric.headCircumference, BabySex.male, birth)),
      (321, 345, 369),
    );
    final last = compute(
      metric: GrowthMetric.headCircumference,
      sex: BabySex.female,
      birthDate: birth,
      from: DateTime(2028, 8, 1),
      to: DateTime(2028, 12, 1),
    ).last;
    expect(last.ageDays, ComputeWhoReference.maxAgeDays);
    expect(values(last), (446, 472, 498));
  });

  test('un point par jour civil entre from et to inclus', () {
    final points = compute(
      metric: GrowthMetric.length,
      sex: BabySex.male,
      birthDate: birth,
      from: DateTime(2026, 9, 10, 18),
      to: DateTime(2026, 9, 14, 8),
    );
    expect(points.map((p) => p.ageDays), [9, 10, 11, 12, 13]);
    expect(points.first.date, DateTime(2026, 9, 10));
    expect(points.last.date, DateTime(2026, 9, 14));
  });

  test('borne à la naissance et à 730 jours', () {
    final points = compute(
      metric: GrowthMetric.weight,
      sex: BabySex.female,
      birthDate: birth,
      from: DateTime(2026, 8, 25),
      to: DateTime(2028, 12, 1),
    );
    expect(points.first.ageDays, 0);
    expect(points.last.ageDays, ComputeWhoReference.maxAgeDays);
    expect(points.last.p50, 11474);
  });

  test('période entièrement hors table : aucun point', () {
    expect(
      compute(
        metric: GrowthMetric.headCircumference,
        sex: BabySex.male,
        birthDate: birth,
        from: DateTime(2029),
        to: DateTime(2029, 2),
      ),
      isEmpty,
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/baby/domain/compute_who_reference_test.dart`
Expected: FAIL (fichiers introuvables).

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/baby/domain/entities/who_percentiles.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'who_percentiles.freezed.dart';

/// Valeurs de référence OMS d'un jour de vie : 3e, 50e et 97e percentiles,
/// en grammes (poids) ou en millimètres (taille, périmètre crânien).
@freezed
abstract class WhoPercentiles with _$WhoPercentiles {
  const factory WhoPercentiles({
    required int ageDays,
    required DateTime date,
    required int p3,
    required int p50,
    required int p97,
  }) = _WhoPercentiles;
}
```

```dart
// lib/features/baby/domain/use_cases/compute_who_reference.dart
import 'dart:math' as math;

import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/baby/domain/entities/baby_sex.dart';
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:colette/features/baby/domain/entities/who_percentiles.dart';
import 'package:colette/features/baby/domain/reference/who_head_circumference_for_age.dart';
import 'package:colette/features/baby/domain/reference/who_length_for_age.dart';
import 'package:colette/features/baby/domain/reference/who_lms.dart';
import 'package:colette/features/baby/domain/reference/who_weight_for_age.dart';

/// Percentiles OMS d'une grandeur pour l'âge, jour par jour sur une période.
class ComputeWhoReference {
  const ComputeWhoReference();

  /// Dernier jour de vie couvert par les tables embarquées.
  static const maxAgeDays = 730;

  /// Score z du 97e percentile (et, au signe près, du 3e).
  static const _z97 = 1.880794;

  /// Un point par jour civil de [from] à [to] inclus, bornés à `[0, maxAgeDays]`.
  List<WhoPercentiles> call({
    required GrowthMetric metric,
    required BabySex sex,
    required DateTime birthDate,
    required DateTime from,
    required DateTime to,
  }) {
    final table = _table(metric, sex);
    // Tables en kg (poids) ou en cm (taille, périmètre) ; résultats en g ou mm.
    final unit = switch (metric) {
      GrowthMetric.weight => 1000,
      GrowthMetric.length || GrowthMetric.headCircumference => 10,
    };
    final first = math.max(0, calendarDaysBetween(birthDate, from));
    final last = math.min(maxAgeDays, calendarDaysBetween(birthDate, to));
    return [
      for (var day = first; day <= last; day++)
        WhoPercentiles(
          ageDays: day,
          date: DateTime(birthDate.year, birthDate.month, birthDate.day + day),
          p3: _value(table[day], -_z97, unit),
          p50: _value(table[day], 0, unit),
          p97: _value(table[day], _z97, unit),
        ),
    ];
  }

  static List<WhoLms> _table(GrowthMetric metric, BabySex sex) =>
      switch ((metric, sex)) {
        (GrowthMetric.weight, BabySex.female) => whoWeightForAgeGirls,
        (GrowthMetric.weight, BabySex.male) => whoWeightForAgeBoys,
        (GrowthMetric.length, BabySex.female) => whoLengthForAgeGirls,
        (GrowthMetric.length, BabySex.male) => whoLengthForAgeBoys,
        (GrowthMetric.headCircumference, BabySex.female) =>
          whoHeadCircumferenceForAgeGirls,
        (GrowthMetric.headCircumference, BabySex.male) =>
          whoHeadCircumferenceForAgeBoys,
      };

  /// Méthode LMS : `M × (1 + L·S·z)^(1/L)`, ou `M × e^(S·z)` si `L = 0`,
  /// convertie dans l'unité entière de la grandeur.
  static int _value(WhoLms lms, double z, int unit) {
    final (l, m, s) = lms;
    final value = l == 0
        ? m * math.exp(s * z)
        : m * math.pow(1 + l * s * z, 1 / l);
    return (value * unit).round();
  }
}
```

- [ ] **Step 4: Generate and run test**

```bash
dart run build_runner build -d
flutter test test/features/baby/domain/compute_who_reference_test.dart
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
dart format lib test && dart analyze
git add lib/features/baby/domain/entities/who_percentiles.dart lib/features/baby/domain/entities/who_percentiles.freezed.dart lib/features/baby/domain/use_cases/compute_who_reference.dart test/features/baby/domain/compute_who_reference_test.dart
git commit -m "feat: percentiles OMS du poids, de la taille et du périmètre crânien

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5 : DTO et méthodes du repository pour les mesures

Les anciennes méthodes (`watchWeights`, `addWeight`, `deleteWeight`) restent jusqu'à la tâche 10.

**Files:**
- Create: `lib/features/baby/data/dtos/growth_measurement_dto.dart`
- Modify: `lib/features/baby/domain/repositories/baby_repository.dart`, `lib/features/baby/data/repositories/firestore_baby_repository.dart`, `lib/core/firebase/firestore_paths.dart`
- Test: `test/features/baby/data/firestore_baby_repository_test.dart` (ajouts)

- [ ] **Step 1: Write the failing tests**

Ajouter l'import `import 'package:colette/features/baby/domain/entities/growth_measurement.dart';` en tête de `firestore_baby_repository_test.dart`, puis ce groupe à la fin de `main()` :

```dart
  group('mesures de croissance', () {
    CollectionReference<Map<String, dynamic>> weights(FakeFirebaseFirestore db) =>
        db.collection('households').doc(code).collection('weights');

    test('relit une ancienne pesée sans taille ni périmètre', () async {
      final db = FakeFirebaseFirestore();
      await weights(db).doc('old').set({
        'measuredAt': Timestamp.fromDate(DateTime(2026, 9, 2)),
        'grams': 3200,
      });
      final repo = FirestoreBabyRepository(db);
      expect(await repo.watchMeasurements(code).first, [
        GrowthMeasurement(
          id: 'old',
          measuredAt: DateTime(2026, 9, 2),
          grams: 3200,
        ),
      ]);
    });

    test('aller-retour d\'une mesure complète et d\'une mesure sans poids', () async {
      final repo = FirestoreBabyRepository(FakeFirebaseFirestore());
      final full = GrowthMeasurement(
        id: 'm1',
        measuredAt: DateTime(2026, 9, 2),
        grams: 3200,
        lengthMm: 520,
        headCircumferenceMm: 350,
      );
      final lengthOnly = GrowthMeasurement(
        id: 'm2',
        measuredAt: DateTime(2026, 9, 10),
        lengthMm: 530,
      );
      await repo.saveMeasurement(code, full);
      await repo.saveMeasurement(code, lengthOnly);
      expect(await repo.watchMeasurements(code).first, [lengthOnly, full]);
    });

    test('n\'écrit pas de clé nulle', () async {
      final db = FakeFirebaseFirestore();
      await FirestoreBabyRepository(db).saveMeasurement(
        code,
        GrowthMeasurement(
          id: 'm',
          measuredAt: DateTime(2026, 9, 2),
          lengthMm: 520,
        ),
      );
      final data = (await weights(db).doc('m').get()).data()!;
      expect(data.keys, unorderedEquals(['measuredAt', 'lengthMm']));
    });

    test('une modification qui retire le périmètre le retire du document', () async {
      final db = FakeFirebaseFirestore();
      final repo = FirestoreBabyRepository(db);
      final measurement = GrowthMeasurement(
        id: 'm',
        measuredAt: DateTime(2026, 9, 2),
        grams: 3200,
        headCircumferenceMm: 350,
      );
      await repo.saveMeasurement(code, measurement);
      await repo.saveMeasurement(
        code,
        measurement.copyWith(headCircumferenceMm: null),
      );
      final data = (await weights(db).doc('m').get()).data()!;
      expect(data.containsKey('headCircumferenceMm'), isFalse);
      expect(data['grams'], 3200);
    });

    test('deleteMeasurement retire la mesure', () async {
      final repo = FirestoreBabyRepository(FakeFirebaseFirestore());
      await repo.saveMeasurement(
        code,
        GrowthMeasurement(id: 'm', measuredAt: DateTime(2026, 9, 2), grams: 3200),
      );
      await repo.deleteMeasurement(code, 'm');
      expect(await repo.watchMeasurements(code).first, isEmpty);
    });
  });
```

Ajouter aussi l'import `import 'package:cloud_firestore/cloud_firestore.dart';` (pour `Timestamp` et `CollectionReference`).

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/baby/data/firestore_baby_repository_test.dart`
Expected: FAIL à la compilation (`watchMeasurements` non défini).

- [ ] **Step 3: DTO, interface et implémentation**

```dart
// lib/features/baby/data/dtos/growth_measurement_dto.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';

/// Conversion `GrowthMeasurement` ↔ document `weights/{id}` ; les valeurs
/// absentes ne sont pas écrites.
abstract final class GrowthMeasurementDto {
  static Map<String, dynamic> toMap(GrowthMeasurement m) => {
    'measuredAt': Timestamp.fromDate(m.measuredAt),
    if (m.grams case final grams?) 'grams': grams,
    if (m.lengthMm case final lengthMm?) 'lengthMm': lengthMm,
    if (m.headCircumferenceMm case final headMm?) 'headCircumferenceMm': headMm,
  };

  static GrowthMeasurement fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return GrowthMeasurement(
      id: doc.id,
      measuredAt: (data['measuredAt'] as Timestamp).toDate(),
      grams: (data['grams'] as num?)?.toInt(),
      lengthMm: (data['lengthMm'] as num?)?.toInt(),
      headCircumferenceMm: (data['headCircumferenceMm'] as num?)?.toInt(),
    );
  }
}
```

Dans `baby_repository.dart`, ajouter l'import de `growth_measurement.dart` et, après `deleteWeight` :

```dart
  /// Mesures de croissance triées de la plus récente à la plus ancienne.
  Stream<List<GrowthMeasurement>> watchMeasurements(String householdCode);

  /// Ajoute ou remplace entièrement la mesure [measurement].
  Future<Either<Failure, void>> saveMeasurement(
    String householdCode,
    GrowthMeasurement measurement,
  );

  Future<Either<Failure, void>> deleteMeasurement(
    String householdCode,
    String measurementId,
  );
```

Dans `firestore_baby_repository.dart`, ajouter les imports de `growth_measurement_dto.dart` et `growth_measurement.dart`, remplacer la doc de classe par `/// Profil dans \`households/{code}.baby\`, mesures de croissance dans \`households/{code}/weights\`.`, puis après `deleteWeight` :

```dart
  @override
  Stream<List<GrowthMeasurement>> watchMeasurements(String householdCode) =>
      _weights(householdCode)
          .orderBy('measuredAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map(GrowthMeasurementDto.fromDoc).toList());

  @override
  Future<Either<Failure, void>> saveMeasurement(
    String householdCode,
    GrowthMeasurement measurement,
  ) => guard(
    // `set` sans merge : une valeur effacée disparaît du document.
    () => _weights(householdCode)
        .doc(measurement.id)
        .set(GrowthMeasurementDto.toMap(measurement)),
  );

  @override
  Future<Either<Failure, void>> deleteMeasurement(
    String householdCode,
    String measurementId,
  ) => guard(() => _weights(householdCode).doc(measurementId).delete());
```

Dans `firestore_paths.dart` :

```dart
  /// Mesures de croissance (poids, taille, périmètre crânien) ; nom historique.
  static const weights = 'weights';
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/baby/data/firestore_baby_repository_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
dart format lib test && dart analyze && flutter test
git add lib/features/baby/data lib/features/baby/domain/repositories/baby_repository.dart lib/core/firebase/firestore_paths.dart test/features/baby/data/firestore_baby_repository_test.dart
git commit -m "feat: lecture et écriture des mesures de croissance dans Firestore

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6 : providers, contrôleur et plan biberons sur les mesures

`latestWeightProvider` et `FeedingPlanSync` prennent la dernière mesure **avec poids**. Les anciens providers (`weights`, `weightTrend`, `whoWeightReference`) et `addWeight` / `deleteWeight` restent jusqu'à la tâche 10.

**Files:**
- Modify: `lib/features/baby/presentation/providers/baby_providers.dart`, `lib/features/baby/presentation/providers/baby_settings_controller.dart`, `lib/features/dashboard/presentation/providers/feeding_plan_sync.dart`
- Test: `test/features/dashboard/presentation/dashboard_providers_test.dart`, `test/features/dashboard/presentation/feeding_plan_sync_test.dart`, `test/features/baby/presentation/baby_settings_controller_test.dart`, `test/features/dashboard/presentation/feeding_reference_sheet_test.dart`, `test/features/dashboard/presentation/dashboard_page_test.dart`

- [ ] **Step 1: Write the failing tests**

Dans `dashboard_providers_test.dart` : ajouter l'import `growth_measurement.dart`, remplacer le paramètre `List<WeightEntry> weights` de `baseOverrides` par `List<GrowthMeasurement> measurements = const []` et l'override `weightsProvider…` par `measurementsProvider.overrideWith((ref) => Stream.value(measurements)),`. Dans les tests existants, remplacer `weights: [WeightEntry(id: 'w', measuredAt: …, grams: N)]` par `measurements: [GrowthMeasurement(id: 'w', measuredAt: …, grams: N)]` et `weightsProvider` par `measurementsProvider` dans les `listen` / `read(...future)`. Retirer l'import devenu inutile de `weight_entry.dart`. Ajouter :

```dart
  test('latestWeight ignore une mesure plus récente sans poids', () async {
    final container = ProviderContainer(
      overrides: baseOverrides(
        profile: BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1)),
        measurements: [
          GrowthMeasurement(
            id: 'l',
            measuredAt: DateTime(2026, 9, 10),
            lengthMm: 530,
          ),
          GrowthMeasurement(
            id: 'w',
            measuredAt: DateTime(2026, 9, 9),
            grams: 4200,
          ),
        ],
      ),
    );
    addTearDown(container.dispose);
    container.listen(measurementsProvider, (_, _) {});
    await container.read(measurementsProvider.future);

    expect(container.read(latestWeightProvider)?.id, 'w');
    expect(container.read(feedingReferenceProvider)!.weightGrams, 4200);
  });
```

Dans `feeding_plan_sync_test.dart`, ajouter l'import `growth_measurement.dart` et :

```dart
  test('sync utilise la dernière pesée, pas une mesure de taille plus récente', () async {
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
    final repo = container.read(babyRepositoryProvider);
    await repo.saveProfile(
      'ABCDEFGH',
      BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1)),
    );
    await repo.saveMeasurement(
      'ABCDEFGH',
      GrowthMeasurement(id: 'w', measuredAt: DateTime(2026, 9, 9), grams: 4200),
    );
    await repo.saveMeasurement(
      'ABCDEFGH',
      GrowthMeasurement(id: 'l', measuredAt: DateTime(2026, 9, 10), lengthMm: 530),
    );

    await container.read(feedingPlanSyncProvider).sync();

    final data = (await db.collection('households').doc('ABCDEFGH').get())
        .data()!;
    final plan = data['feedingPlan'] as Map<String, dynamic>;
    // Jour de vie 10 : 150 ml/kg × 4,2 kg = 630 ml, 8 biberons → 80 ml.
    // Sans pesée, la table par âge donnerait 480 / 8 = 60 ml.
    expect(plan['suggestedMl'], 80);
  });
```

Dans `baby_settings_controller_test.dart`, ajouter l'import `growth_measurement.dart`, un `registerFallbackValue(GrowthMeasurement(id: 'x', measuredAt: DateTime(2026)))` dans `setUpAll`, et :

```dart
  test('saveMeasurement refuse une mesure vide', () async {
    final ok = await controller().saveMeasurement(
      measuredAt: DateTime(2026, 9, 10),
    );
    expect(ok, isFalse);
    final error = container.read(babySettingsControllerProvider).error;
    expect(
      (error! as ValidationFailure).reason,
      ValidationReason.emptyMeasurement,
    );
    verifyNever(() => repo.saveMeasurement(any(), any()));
  });

  test('saveMeasurement crée une mesure puis synchronise le plan', () async {
    when(() => repo.saveMeasurement(any(), any()))
        .thenAnswer((_) async => right(null));
    final ok = await controller().saveMeasurement(
      measuredAt: DateTime(2026, 9, 10),
      lengthMm: 545,
      headCircumferenceMm: 370,
    );
    expect(ok, isTrue);
    final saved =
        verify(() => repo.saveMeasurement('ABCDEFGH', captureAny()))
                .captured
                .single
            as GrowthMeasurement;
    expect(
      saved,
      GrowthMeasurement(
        id: 'w-new',
        measuredAt: DateTime(2026, 9, 10),
        lengthMm: 545,
        headCircumferenceMm: 370,
      ),
    );
    verify(() => sync.sync()).called(1);
  });

  test('saveMeasurement avec un id modifie la mesure existante', () async {
    when(() => repo.saveMeasurement(any(), any()))
        .thenAnswer((_) async => right(null));
    await controller().saveMeasurement(
      id: 'm1',
      measuredAt: DateTime(2026, 9, 10),
      grams: 3600,
    );
    final saved =
        verify(() => repo.saveMeasurement('ABCDEFGH', captureAny()))
                .captured
                .single
            as GrowthMeasurement;
    expect(saved.id, 'm1');
  });

  test('deleteMeasurement supprime puis synchronise le plan', () async {
    when(() => repo.deleteMeasurement(any(), any()))
        .thenAnswer((_) async => right(null));
    expect(await controller().deleteMeasurement('m1'), isTrue);
    verify(() => repo.deleteMeasurement('ABCDEFGH', 'm1')).called(1);
    verify(() => sync.sync()).called(1);
  });
```

Dans `feeding_reference_sheet_test.dart` (deux endroits) et `dashboard_page_test.dart` : ajouter l'import `growth_measurement.dart` et un override `measurementsProvider` à côté de chaque override `weightsProvider`, avec les mêmes données converties, par exemple :

```dart
    measurementsProvider.overrideWith(
      (ref) => Stream.value([
        if (weightGrams != null)
          GrowthMeasurement(
            id: 'w',
            measuredAt: DateTime(2026, 9, 9),
            grams: weightGrams,
          ),
      ]),
    ),
```

Dans `feeding_reference_sheet_test.dart`, remplacer les deux overrides `weightsProvider` par `measurementsProvider` (même forme que l'exemple ci-dessus, `GrowthMeasurement` à la place de `WeightEntry`) : seul le plan lit la pesée.

Dans `dashboard_page_test.dart`, remplacer le paramètre `List<WeightEntry>? weights` de `overridesFor` par `List<GrowthMeasurement>? measurements` (l'appel ligne 236 devient `measurements: const []`), et remplacer l'override `weightsProvider` par ces deux overrides (la carte poids lit encore `weightsProvider` jusqu'à la tâche 7) :

```dart
    measurementsProvider.overrideWith(
      (ref) => Stream.value(measurements ?? defaultMeasurements),
    ),
    weightsProvider.overrideWith(
      (ref) => Stream.value([
        for (final m in measurements ?? defaultMeasurements)
          WeightEntry(id: m.id, measuredAt: m.measuredAt, grams: m.grams!),
      ]),
    ),
```

avec, en tête de `main()` :

```dart
  final defaultMeasurements = [
    GrowthMeasurement(id: 'w', measuredAt: DateTime(2026, 9, 9), grams: 3600),
  ];
```

À la tâche 7, l'override `weightsProvider` et l'import `weight_entry.dart` de ce fichier sont retirés.

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/dashboard test/features/baby/presentation/baby_settings_controller_test.dart`
Expected: FAIL à la compilation (`measurementsProvider`, `saveMeasurement`, `deleteMeasurement` non définis).

- [ ] **Step 3: Providers**

Dans `baby_providers.dart`, ajouter les imports `growth_measurement.dart`, `growth_metric.dart`, `growth_trend.dart`, `who_percentiles.dart`, `compute_growth_trend.dart`, `compute_who_reference.dart`. Remplacer `latestWeight` et ajouter les nouveaux providers :

```dart
/// Mesures de croissance du foyer courant, de la plus récente à la plus ancienne.
@Riverpod(retry: noRetry)
Stream<List<GrowthMeasurement>> measurements(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(const []);
  return ref.watch(babyRepositoryProvider).watchMeasurements(code);
}

/// Mesure avec poids la plus récente, ou `null`.
@riverpod
GrowthMeasurement? latestWeight(Ref ref) => GrowthMetric.weight.latestOf(
  ref.watch(measurementsProvider).value ?? const [],
);

/// Dernière valeur de [metric] et évolution depuis la précédente, ou `null`.
@riverpod
GrowthTrend? growthTrend(Ref ref, GrowthMetric metric) =>
    const ComputeGrowthTrend()(
      metric,
      ref.watch(measurementsProvider).value ?? const [],
    );

/// Percentiles OMS de [metric] sur la période de ses mesures, une journée de
/// marge de chaque côté ; vide sans mesure, sans profil ou sans sexe renseigné.
@riverpod
List<WhoPercentiles> whoReference(Ref ref, GrowthMetric metric) {
  final profile = ref.watch(babyProfileProvider).value;
  final sex = profile?.sex;
  final series = metric.seriesOf(
    ref.watch(measurementsProvider).value ?? const [],
  );
  if (profile == null || sex == null || series.isEmpty) return const [];
  return const ComputeWhoReference()(
    metric: metric,
    sex: sex,
    birthDate: profile.birthDate,
    from: series.first.at.startOfPreviousDay,
    to: series.last.at.startOfNextDay,
  );
}
```

- [ ] **Step 4: Contrôleur**

Dans `baby_settings_controller.dart`, ajouter les imports `growth_measurement.dart` et `validate_growth_measurement.dart`, remplacer la doc de classe par `/// Actions de l'onglet Réglages sur le profil, les mesures de croissance et les soins attendus.`, puis après `deleteWeight` :

```dart
  /// Crée ([id] nul) ou remplace une mesure après validation, puis resynchronise le plan.
  Future<bool> saveMeasurement({
    String? id,
    required DateTime measuredAt,
    int? grams,
    int? lengthMm,
    int? headCircumferenceMm,
  }) => _run((code) {
    final measurement = GrowthMeasurement(
      id: id ?? ref.read(idGeneratorProvider).newId(),
      measuredAt: measuredAt,
      grams: grams,
      lengthMm: lengthMm,
      headCircumferenceMm: headCircumferenceMm,
    );
    return const ValidateGrowthMeasurement()(measurement)
        .fold<Future<Either<Failure, void>>>(
          (failure) async => left(failure),
          (valid) =>
              ref.read(babyRepositoryProvider).saveMeasurement(code, valid),
        );
  });

  Future<bool> deleteMeasurement(String measurementId) => _run(
    (code) => ref
        .read(babyRepositoryProvider)
        .deleteMeasurement(code, measurementId),
  );
```

- [ ] **Step 5: Plan biberons**

Dans `feeding_plan_sync.dart`, ajouter l'import `package:colette/features/baby/domain/entities/growth_metric.dart` et remplacer :

```dart
      final weights = await babyRepository.watchWeights(code).first;
```

par :

```dart
      final measurements = await babyRepository.watchMeasurements(code).first;
```

et `latestWeightGrams: weights.isEmpty ? null : weights.first.grams,` par :

```dart
        latestWeightGrams: GrowthMetric.weight.latestOf(measurements)?.grams,
```

- [ ] **Step 6: Generate and run tests**

```bash
dart run build_runner build -d
flutter test test/features/dashboard test/features/baby
```
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
dart format lib test && dart analyze && flutter test
git add lib/features/baby/presentation/providers lib/features/dashboard/presentation/providers/feeding_plan_sync.dart test/features/dashboard test/features/baby/presentation/baby_settings_controller_test.dart
git commit -m "feat: providers des mesures, plan biberons sur la dernière mesure avec poids

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7 : courbe, échelle et résumé génériques ; carte poids

`WeightChart`, `WeightChartScale` et `WeightTrendSummary` sont remplacés par leurs équivalents `Growth…`. La carte d'accueil et la page de courbe (encore `WeightCurvePage`) passent aux nouveaux providers, sur la grandeur poids.

**Files:**
- Create: `lib/features/baby/presentation/widgets/growth_format.dart`, `growth_chart_scale.dart`, `growth_chart.dart`, `growth_trend_summary.dart`
- Modify: `lib/features/baby/presentation/widgets/who_reference_bars.dart`, `lib/features/dashboard/presentation/widgets/weight_card.dart`, `lib/features/baby/presentation/pages/weight_curve_page.dart`, `lib/l10n/app_fr.arb`
- Delete: `lib/features/baby/presentation/widgets/weight_chart.dart`, `weight_chart_scale.dart`, `weight_trend_summary.dart`, `test/features/baby/presentation/weight_chart_scale_test.dart`
- Test: `test/features/baby/presentation/growth_chart_scale_test.dart`, `test/features/baby/presentation/growth_format_test.dart`, `test/features/dashboard/presentation/weight_card_test.dart`, `test/features/baby/presentation/weight_curve_page_test.dart`, `test/features/dashboard/presentation/dashboard_page_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/baby/presentation/growth_chart_scale_test.dart
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:colette/features/baby/presentation/widgets/growth_chart_scale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  GrowthPoint point(DateTime at, int value) => (at: at, value: value);

  GrowthChartScale weight(List<GrowthPoint> points, {List<int> extra = const []}) =>
      GrowthChartScale.fromPoints(
        points,
        metric: GrowthMetric.weight,
        extraValues: extra,
      );

  test('poids : arrondit les bornes au pas et garde au plus 4 intervalles', () {
    final scale = weight([
      point(DateTime(2026, 9, 1), 3280),
      point(DateTime(2026, 9, 20), 4110),
    ]);
    expect(scale.step, 250);
    expect(scale.minValue, 3250);
    expect(scale.maxValue, 4250);
    expect(scale.ticks, [3250, 3500, 3750, 4000, 4250]);
  });

  test('poids : petite variation, au moins deux intervalles de 100 g', () {
    final scale = weight([
      point(DateTime(2026, 9, 1), 3410),
      point(DateTime(2026, 9, 2), 3430),
    ]);
    expect(scale.step, 100);
    expect(scale.ticks.length, greaterThanOrEqualTo(3));
    expect(scale.minValue, lessThanOrEqualTo(3410));
    expect(scale.maxValue, greaterThanOrEqualTo(3430));
  });

  test('une seule mesure : centrée dans le temps et entourée de marge', () {
    final at = DateTime(2026, 9, 10);
    final scale = weight([point(at, 3500)]);
    expect(scale.xOf(at), 0);
    expect(scale.minX, -1);
    expect(scale.maxX, 1);
    expect(scale.dateInterval, 1);
    expect(3500 - scale.minValue, scale.maxValue - 3500);
  });

  test('abscisses en jours depuis la première mesure', () {
    final first = DateTime(2026, 9, 1);
    final last = DateTime(2026, 9, 11);
    final scale = weight([
      point(first, 3000),
      point(DateTime(2026, 9, 6), 3200),
      point(last, 3500),
    ]);
    expect(scale.origin, first);
    expect(scale.minX, 0);
    expect(scale.maxX, 10);
    expect(scale.xOf(DateTime(2026, 9, 6, 12)), 5.5);
    expect(scale.xOf(last), 10);
    expect(scale.dateInterval, 10);
  });

  test('poids : grand écart, pas élargi', () {
    final scale = weight([
      point(DateTime(2026, 1, 1), 3000),
      point(DateTime(2026, 9, 1), 8200),
    ]);
    expect(scale.step, 2000);
    expect(scale.ticks, [2000, 4000, 6000, 8000, 10000]);
  });

  test('extraValues élargit l\'axe vertical', () {
    final scale = weight(
      [point(DateTime(2026, 9, 1), 3500)],
      extra: const [2600, 4400],
    );
    expect(scale.minValue, lessThanOrEqualTo(2600));
    expect(scale.maxValue, greaterThanOrEqualTo(4400));
  });

  test('taille : pas en millimètres', () {
    final scale = GrowthChartScale.fromPoints([
      point(DateTime(2026, 9, 1), 500),
      point(DateTime(2026, 9, 20), 545),
    ], metric: GrowthMetric.length);
    expect(scale.step, 20);
    expect(scale.ticks, [500, 520, 540, 560]);
  });

  test('périmètre : petite variation, pas de 5 mm', () {
    final scale = GrowthChartScale.fromPoints([
      point(DateTime(2026, 9, 1), 345),
      point(DateTime(2026, 9, 8), 350),
    ], metric: GrowthMetric.headCircumference);
    expect(scale.step, 5);
    expect(scale.ticks, [340, 345, 350]);
  });
}
```

```dart
// test/features/baby/presentation/growth_format_test.dart
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:colette/features/baby/presentation/widgets/growth_format.dart';
import 'package:colette/l10n/generated/app_localizations_fr.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final s = SFr();

  test('centimètres à une décimale, virgule française', () {
    expect(GrowthFormat.centimetres(545), '54,5');
    expect(GrowthFormat.centimetres(370), '37,0');
  });

  test('valeur avec unité selon la grandeur', () {
    expect(GrowthFormat.value(s, GrowthMetric.weight, 3650), '3650 g');
    expect(GrowthFormat.value(s, GrowthMetric.length, 545), '54,5 cm');
  });

  test('écart signé', () {
    expect(GrowthFormat.signedDelta(GrowthMetric.weight, 180), '+180');
    expect(GrowthFormat.signedDelta(GrowthMetric.weight, -40), '−40');
    expect(GrowthFormat.signedDelta(GrowthMetric.length, 20), '+2,0');
    expect(GrowthFormat.signedDelta(GrowthMetric.length, -5), '−0,5');
    expect(GrowthFormat.signedDelta(GrowthMetric.length, 0), '0');
  });

  test('ligne d\'une mesure : valeurs présentes séparées par un point médian', () {
    expect(
      GrowthFormat.measurementLine(
        s,
        GrowthMeasurement(
          id: 'm',
          measuredAt: DateTime(2026, 9, 2),
          grams: 3650,
          lengthMm: 545,
          headCircumferenceMm: 370,
        ),
      ),
      '3650 g · 54,5 cm · PC 37,0 cm',
    );
    expect(
      GrowthFormat.measurementLine(
        s,
        GrowthMeasurement(id: 'm', measuredAt: DateTime(2026, 9, 2), lengthMm: 520),
      ),
      '52,0 cm',
    );
  });
}
```

Dans `weight_card_test.dart` : importer `growth_measurement.dart` à la place de `weight_entry.dart`, remplacer `List<WeightEntry> weights` par `List<GrowthMeasurement> measurements`, l'override par `measurementsProvider.overrideWith((ref) => Stream.value(measurements))` et les données par `GrowthMeasurement(id: 'a', measuredAt: DateTime(2026, 9, 10), grams: 3470)` / `GrowthMeasurement(id: 'b', measuredAt: DateTime(2026, 9, 14), grams: 3650)`. Ajouter :

```dart
  testWidgets('une mesure de taille seule ne remplace pas le poids', (tester) async {
    await pumpCard(tester, [
      ...weights,
      GrowthMeasurement(id: 'l', measuredAt: DateTime(2026, 9, 15), lengthMm: 530),
    ]);
    expect(find.text('3650 g'), findsOneWidget);
    expect(find.text('Pesée du 14 sept. 2026'), findsOneWidget);
  });
```

Dans `weight_curve_page_test.dart` : remplacer la liste `weights` par des `GrowthMeasurement` (mêmes id, dates, grammes), et dans `overrides(...)` remplacer `weightsProvider.overrideWith(...)` par les deux overrides suivants (la liste des pesées lit encore `weightsProvider` jusqu'à la tâche 8) :

```dart
    measurementsProvider.overrideWith((ref) => Stream.value(list)),
    weightsProvider.overrideWith(
      (ref) => Stream.value([
        for (final m in list)
          WeightEntry(id: m.id, measuredAt: m.measuredAt, grams: m.grams!),
      ]),
    ),
```

avec `List<Override> overrides(List<GrowthMeasurement> list, {BabySex? sex})`.

Dans `dashboard_page_test.dart`, retirer l'override `weightsProvider` ajouté en tâche 6 (la carte poids lit désormais `measurementsProvider`) et l'import de `weight_entry.dart` s'il n'est plus utilisé.

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/baby/presentation/growth_chart_scale_test.dart test/features/baby/presentation/growth_format_test.dart test/features/dashboard/presentation/weight_card_test.dart`
Expected: FAIL (fichiers `growth_*` introuvables ; la carte lit encore `weightsProvider`).

- [ ] **Step 3: Chaînes**

Dans `app_fr.arb`, après `"weightTrendFirst": …,` :

```json
  "measurementCm": "{value} cm",
  "@measurementCm": { "placeholders": { "value": { "type": "String" } } },
  "measurementHeadCircumferenceShort": "PC {value} cm",
  "@measurementHeadCircumferenceShort": { "placeholders": { "value": { "type": "String" } } },
  "measurementMeasuredOn": "Mesure du {date}",
  "@measurementMeasuredOn": { "placeholders": { "date": { "type": "String" } } },
  "measurementTrendSinceCm": "{delta} cm en {days, plural, =1{1 jour} other{{days} jours}}",
  "@measurementTrendSinceCm": { "placeholders": { "delta": { "type": "String" }, "days": { "type": "int" } } },
  "measurementTrendFirst": "Première mesure",
```

Puis `flutter gen-l10n`.

- [ ] **Step 4: `GrowthFormat`**

```dart
// lib/features/baby/presentation/widgets/growth_format.dart
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

/// Textes des valeurs de croissance : « 3650 g », « 54,5 cm ».
abstract final class GrowthFormat {
  static final _centimetres = NumberFormat('0.0', 'fr');

  /// Millimètres en centimètres à une décimale : 545 → « 54,5 ».
  static String centimetres(int mm) => _centimetres.format(mm / 10);

  /// Valeur de [metric] avec son unité.
  static String value(S s, GrowthMetric metric, int value) => switch (metric) {
    GrowthMetric.weight => s.weightGrams(value),
    GrowthMetric.length ||
    GrowthMetric.headCircumference => s.measurementCm(centimetres(value)),
  };

  /// Écart avec signe explicite, sans unité : « +180 », « −0,5 », « 0 ».
  static String signedDelta(GrowthMetric metric, int delta) {
    if (delta == 0) return '0';
    final magnitude = switch (metric) {
      GrowthMetric.weight => '${delta.abs()}',
      GrowthMetric.length ||
      GrowthMetric.headCircumference => centimetres(delta.abs()),
    };
    return delta > 0 ? '+$magnitude' : '−$magnitude';
  }

  /// Valeurs présentes d'une mesure : « 3650 g · 54,5 cm · PC 37,0 cm ».
  static String measurementLine(S s, GrowthMeasurement m) => [
    if (m.grams case final grams?) s.weightGrams(grams),
    if (m.lengthMm case final lengthMm?) s.measurementCm(centimetres(lengthMm)),
    if (m.headCircumferenceMm case final headMm?)
      s.measurementHeadCircumferenceShort(centimetres(headMm)),
  ].join(' · ');
}
```

- [ ] **Step 5: `GrowthChartScale`**

```dart
// lib/features/baby/presentation/widgets/growth_chart_scale.dart
import 'package:colette/features/baby/domain/entities/growth_metric.dart';

/// Échelle d'une courbe de croissance : période couverte et graduations, en
/// grammes (poids) ou en millimètres (taille, périmètre crânien).
class GrowthChartScale {
  const GrowthChartScale._({
    required this.origin,
    required this.minX,
    required this.maxX,
    required this.minValue,
    required this.maxValue,
    required this.step,
  });

  /// Construit l'échelle de [points], qui ne doit pas être vide ;
  /// [extraValues] élargit l'axe vertical (courbes de référence).
  factory GrowthChartScale.fromPoints(
    List<GrowthPoint> points, {
    required GrowthMetric metric,
    Iterable<int> extraValues = const [],
  }) {
    assert(points.isNotEmpty, 'Aucune mesure à tracer');
    final dates = points.map((p) => p.at).toList()..sort();
    final values = [...points.map((p) => p.value), ...extraValues];
    final low = values.reduce((a, b) => a < b ? a : b);
    final high = values.reduce((a, b) => a > b ? a : b);
    final steps = stepsFor(metric);
    final step = steps.firstWhere(
      (step) => _span(low, high, step).intervals <= maxIntervals,
      orElse: () => steps.last,
    );
    final span = _span(low, high, step);
    final lastX = _daysBetween(dates.first, dates.last);
    return GrowthChartScale._(
      origin: dates.first,
      minX: lastX == 0 ? -_singlePaddingDays : 0,
      maxX: lastX == 0 ? _singlePaddingDays : lastX,
      minValue: span.min,
      maxValue: span.max,
      step: step,
    );
  }

  /// Nombre maximal d'intervalles entre graduations.
  static const maxIntervals = 4;

  static const _minIntervals = 2;

  /// Marge de part et d'autre d'une mesure unique, en jours.
  static const _singlePaddingDays = 1.0;

  /// Pas de graduation possibles, du plus fin au plus large.
  static List<int> stepsFor(GrowthMetric metric) => switch (metric) {
    GrowthMetric.weight => const [100, 250, 500, 1000, 2000],
    GrowthMetric.length ||
    GrowthMetric.headCircumference => const [5, 10, 20, 50],
  };

  /// Date de la première mesure, abscisse 0.
  final DateTime origin;

  /// Bornes de l'axe horizontal, en jours depuis [origin].
  final double minX;
  final double maxX;

  /// Bornes et pas de l'axe vertical, dans l'unité de la grandeur.
  final int minValue;
  final int maxValue;
  final int step;

  /// Graduations, de la plus basse à la plus haute.
  List<int> get ticks => [for (var v = minValue; v <= maxValue; v += step) v];

  /// Pas des dates en abscisse : tombe sur la première et la dernière mesure,
  /// ou sur la mesure unique entre ses marges.
  double get dateInterval => minX < 0 ? -minX : maxX;

  /// Abscisse de [at], en jours (fractionnaires) depuis [origin].
  double xOf(DateTime at) => _daysBetween(origin, at);

  static double _daysBetween(DateTime from, DateTime to) =>
      to.difference(from).inMinutes / Duration.minutesPerDay;

  /// Bornes arrondies à [step], élargies alternativement vers le bas et le haut
  /// jusqu'à [_minIntervals] intervalles.
  static ({int min, int max, int intervals}) _span(
    int low,
    int high,
    int step,
  ) {
    var min = (low ~/ step) * step;
    var max = ((high + step - 1) ~/ step) * step;
    var extendDown = true;
    while ((max - min) ~/ step < _minIntervals) {
      if (extendDown && min - step > 0) {
        min -= step;
      } else {
        max += step;
      }
      extendDown = !extendDown;
    }
    return (min: min, max: max, intervals: (max - min) ~/ step);
  }
}
```

- [ ] **Step 6: `WhoReferenceBars` générique**

Réécrire `who_reference_bars.dart` (mêmes traits, types généralisés) :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/baby/domain/entities/who_percentiles.dart';
import 'package:colette/features/baby/presentation/widgets/growth_chart_scale.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Traits OMS (P97, médiane, P3) et zone teintée entre P3 et P97, placés en
/// tête de `lineBarsData` : indices 0 à 2.
abstract final class WhoReferenceBars {
  /// Nombre de traits ajoutés avant la courbe des mesures.
  static const count = 3;

  static const _p97Index = 0;
  static const _p3Index = 2;

  /// Points de [points] compris dans l'axe horizontal de [scale].
  static List<WhoPercentiles> visible(
    List<WhoPercentiles> points,
    GrowthChartScale scale,
  ) => [
    for (final p in points)
      if (scale.xOf(p.date) >= scale.minX && scale.xOf(p.date) <= scale.maxX) p,
  ];

  static List<LineChartBarData> bars(
    BuildContext context,
    List<WhoPercentiles> points,
    GrowthChartScale scale,
  ) {
    final color = context.appColor(AppColors.growthReference);
    LineChartBarData bar(
      int Function(WhoPercentiles) value, {
      bool dashed = false,
    }) => LineChartBarData(
      spots: [
        for (final p in points) FlSpot(scale.xOf(p.date), value(p).toDouble()),
      ],
      color: dashed ? color : AppOpacity.medium.applyTo(color),
      barWidth: dashed ? AppStroke.regular.value : AppStroke.hairline.value,
      dashArray: dashed
          ? [AppSpacing.xs.value.toInt(), AppSpacing.xs.value.toInt()]
          : null,
      // Sans points : sert aussi à les distinguer de la courbe des mesures au toucher.
      dotData: const FlDotData(show: false),
    );
    return [
      bar((p) => p.p97),
      bar((p) => p.p50, dashed: true),
      bar((p) => p.p3),
    ];
  }

  /// Zone teintée entre P3 et P97.
  static BetweenBarsData band(BuildContext context) => BetweenBarsData(
    fromIndex: _p97Index,
    toIndex: _p3Index,
    color: AppOpacity.veryLight.applyTo(
      context.appColor(AppColors.growthReference),
    ),
  );
}
```

- [ ] **Step 7: `GrowthChart`**

```dart
// lib/features/baby/presentation/widgets/growth_chart.dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:colette/features/baby/domain/entities/who_percentiles.dart';
import 'package:colette/features/baby/presentation/widgets/growth_chart_scale.dart';
import 'package:colette/features/baby/presentation/widgets/growth_format.dart';
import 'package:colette/features/baby/presentation/widgets/who_reference_bars.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Courbe d'une grandeur de croissance, avec référence OMS optionnelle ;
/// `compact` masque axes, grille et infobulle.
class GrowthChart extends StatelessWidget {
  const GrowthChart({
    super.key,
    required this.metric,
    required this.points,
    this.reference = const [],
    this.compact = false,
  });

  /// Proportions de la courbe pleine taille.
  static const aspectRatio = 1.6;

  /// Tolérance, en jours, pour reconnaître l'abscisse d'une mesure.
  static const _xTolerance = 1e-6;

  final GrowthMetric metric;

  /// Points à tracer, au moins un, dans n'importe quel ordre.
  final List<GrowthPoint> points;

  /// Percentiles OMS à tracer derrière la courbe ; vide pour les masquer.
  final List<WhoPercentiles> reference;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final sorted = [...points]..sort((a, b) => a.at.compareTo(b.at));
    final firstScale = GrowthChartScale.fromPoints(sorted, metric: metric);
    final shown = WhoReferenceBars.visible(reference, firstScale);
    final scale = shown.isEmpty
        ? firstScale
        : GrowthChartScale.fromPoints(
            sorted,
            metric: metric,
            extraValues: [
              for (final p in shown) ...[p.p3, p.p97],
            ],
          );
    final valueBarIndex = shown.isEmpty ? 0 : WhoReferenceBars.count;
    final primary = context.appColor(AppColors.primary);
    final surface = context.appColor(AppColors.surface);
    return LineChart(
      duration: AppDuration.normal.value,
      LineChartData(
        minX: scale.minX,
        maxX: scale.maxX,
        minY: scale.minValue.toDouble(),
        maxY: scale.maxValue.toDouble(),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: !compact,
          drawVerticalLine: false,
          horizontalInterval: scale.step.toDouble(),
          getDrawingHorizontalLine: (_) => FlLine(
            color: context.appColor(AppColors.border),
            strokeWidth: AppStroke.hairline.value,
          ),
        ),
        titlesData: compact
            ? const FlTitlesData(show: false)
            : _titles(context, sorted, scale),
        lineTouchData: compact
            ? const LineTouchData(enabled: false)
            : _touch(context, sorted, valueBarIndex),
        betweenBarsData: [if (shown.isNotEmpty) WhoReferenceBars.band(context)],
        lineBarsData: [
          if (shown.isNotEmpty) ...WhoReferenceBars.bars(context, shown, scale),
          LineChartBarData(
            spots: [
              for (final p in sorted)
                FlSpot(scale.xOf(p.at), p.value.toDouble()),
            ],
            color: primary,
            barWidth: compact ? AppStroke.regular.value : AppStroke.thick.value,
            isStrokeCapRound: true,
            isStrokeJoinRound: true,
            belowBarData: BarAreaData(
              // La zone OMS remplace le remplissage sous la courbe.
              show: shown.isEmpty,
              color: AppOpacity.veryLight.applyTo(primary),
            ),
            dotData: FlDotData(
              checkToShowDot: (spot, bar) => !compact || spot == bar.spots.last,
              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                radius: AppSpacing.xs.value,
                color: primary,
                strokeColor: surface,
                strokeWidth: AppStroke.regular.value,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Graduation verticale : kilogrammes pour le poids, centimètres sinon.
  String _axisLabel(S s, String locale, double value) => switch (metric) {
    GrowthMetric.weight => s.weightKg(
      NumberFormat('0.0#', locale).format(value / 1000),
    ),
    GrowthMetric.length || GrowthMetric.headCircumference => s.measurementCm(
      NumberFormat('0.#', locale).format(value / 10),
    ),
  };

  FlTitlesData _titles(
    BuildContext context,
    List<GrowthPoint> sorted,
    GrowthChartScale scale,
  ) {
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.MMMd(locale);
    final style = Theme.of(context).coletteTextStyles.small
        .copyWith(color: context.appColor(AppColors.textSecondary));
    final first = sorted.first.at;
    final last = sorted.last.at;
    // Dates affichées : première et dernière mesure, une seule si même jour.
    final labelled = {
      scale.xOf(first): first,
      if (!DateUtils.isSameDay(first, last)) scale.xOf(last): last,
    };
    const hidden = AxisTitles();
    return FlTitlesData(
      topTitles: hidden,
      rightTitles: hidden,
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: scale.step.toDouble(),
          reservedSize: AppSize.xxl.value,
          getTitlesWidget: (value, meta) => SideTitleWidget(
            meta: meta,
            child: Text(_axisLabel(s, locale, value), style: style),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: scale.dateInterval,
          reservedSize: AppSize.md.value,
          getTitlesWidget: (value, meta) {
            final date = labelled.entries
                .where((e) => (e.key - value).abs() < _xTolerance)
                .firstOrNull
                ?.value;
            if (date == null) return const SizedBox.shrink();
            return SideTitleWidget(
              meta: meta,
              fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
              child: Text(dateFormat.format(date), style: style),
            );
          },
        ),
      ),
    );
  }

  LineTouchData _touch(
    BuildContext context,
    List<GrowthPoint> sorted,
    int valueBarIndex,
  ) {
    final s = S.of(context);
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    );
    final styles = Theme.of(context).coletteTextStyles;
    final onPrimary = context.appColor(AppColors.onPrimary);
    final border = context.appColor(AppColors.border);
    return LineTouchData(
      getTouchedSpotIndicator: (bar, indexes) => [
        for (final _ in indexes)
          // Traits OMS (sans points) : pas d'indicateur.
          if (!bar.dotData.show)
            null
          else
            TouchedSpotIndicatorData(
              FlLine(color: border, strokeWidth: AppStroke.regular.value),
              FlDotData(
                getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                  radius: AppSpacing.sm.value - AppSpacing.xxs.value,
                  color: context.appColor(AppColors.primary),
                  strokeColor: context.appColor(AppColors.surface),
                  strokeWidth: AppStroke.thick.value,
                ),
              ),
            ),
      ],
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => context.appColor(AppColors.primary),
        tooltipBorderRadius: AppRadius.sm.circular,
        tooltipPadding: AppSpacing.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        fitInsideHorizontally: true,
        fitInsideVertically: true,
        getTooltipItems: (spots) => [
          for (final spot in spots)
            if (spot.barIndex != valueBarIndex)
              null
            else
              LineTooltipItem(
                GrowthFormat.value(s, metric, sorted[spot.spotIndex].value),
                styles.bodyMedium.copyWith(color: onPrimary),
                children: [
                  TextSpan(
                    text: '\n${dateFormat.format(sorted[spot.spotIndex].at)}',
                    style: styles.small.copyWith(color: onPrimary),
                  ),
                ],
              ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 8: `GrowthTrendSummary`**

```dart
// lib/features/baby/presentation/widgets/growth_trend_summary.dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:colette/features/baby/domain/entities/growth_trend.dart';
import 'package:colette/features/baby/presentation/widgets/growth_format.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Dernière valeur d'une grandeur, date de la mesure et évolution depuis la précédente.
class GrowthTrendSummary extends StatelessWidget {
  const GrowthTrendSummary({super.key, required this.trend});

  final GrowthTrend trend;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = styles.small.copyWith(
      color: context.appColor(AppColors.textSecondary),
    );
    final isWeight = trend.metric == GrowthMetric.weight;
    final date = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).format(trend.latestAt);
    return Column(
      crossAxisAlignment: .start,
      spacing: AppSpacing.xxs.value,
      children: [
        Text(
          GrowthFormat.value(s, trend.metric, trend.latestValue),
          style: styles.numberMedium.copyWith(
            color: context.appColor(AppColors.primary),
          ),
        ),
        Text(
          isWeight ? s.weightMeasuredOn(date) : s.measurementMeasuredOn(date),
          style: secondary,
        ),
        Text(_evolution(s, isWeight: isWeight), style: secondary),
      ],
    );
  }

  String _evolution(S s, {required bool isWeight}) {
    String signed(int value) => GrowthFormat.signedDelta(trend.metric, value);
    return switch ((trend.delta, trend.days, trend.perDay)) {
      (final delta?, final days?, final perDay?) when isWeight =>
        s.weightTrendSince(signed(delta), days, signed(perDay)),
      (final delta?, final days?, _) => s.measurementTrendSinceCm(
        signed(delta),
        days,
      ),
      _ => isWeight ? s.weightTrendFirst : s.measurementTrendFirst,
    };
  }
}
```

- [ ] **Step 9: Brancher la carte et la page de courbe**

`weight_card.dart` : remplacer les imports `weight_entry.dart`, `weight_chart.dart`, `weight_trend_summary.dart` par `growth_metric.dart`, `growth_chart.dart`, `growth_trend_summary.dart`. Dans `build` :

```dart
    final points = GrowthMetric.weight.seriesOf(
      ref.watch(measurementsProvider).value ?? const [],
    );
    final trend = ref.watch(growthTrendProvider(GrowthMetric.weight));
```

et dans le `switch (trend)` :

```dart
            final trend => Row(
              crossAxisAlignment: .end,
              spacing: AppSpacing.md.value,
              children: [
                Expanded(flex: 3, child: GrowthTrendSummary(trend: trend)),
                if (points.length > 1)
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: AppSize.xxxl.value,
                      child: GrowthChart(
                        metric: GrowthMetric.weight,
                        points: points,
                        compact: true,
                      ),
                    ),
                  ),
              ],
            ),
```

Mettre à jour la doc de classe : `/// Carte « Poids » : dernière pesée, évolution et mini-courbe ; ouvre la page de croissance.`

`weight_curve_page.dart` : remplacer les imports `weight_entry.dart`, `weight_trend.dart`, `who_weight_percentiles.dart`, `weight_chart.dart`, `weight_trend_summary.dart` par `growth_metric.dart`, `growth_trend.dart`, `who_percentiles.dart`, `growth_chart.dart`, `growth_trend_summary.dart`. Dans `WeightCurvePage.build` :

```dart
    final points = GrowthMetric.weight.seriesOf(
      ref.watch(measurementsProvider).value ?? const [],
    );
    final trend = ref.watch(growthTrendProvider(GrowthMetric.weight));
```

et `_ChartSection(points: points, trend: trend)`. `_ChartSection` devient :

```dart
class _ChartSection extends ConsumerWidget {
  const _ChartSection({required this.points, required this.trend});

  final List<GrowthPoint> points;
  final GrowthTrend trend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final hasSex = ref.watch(babyProfileProvider).value?.sex != null;
    final showWho = hasSex && ref.watch(whoCurvesVisibilityProvider);
    final reference = showWho
        ? ref.watch(whoReferenceProvider(GrowthMetric.weight))
        : const <WhoPercentiles>[];
    final small = Theme.of(context).coletteTextStyles.small
        .copyWith(color: context.appColor(AppColors.textSecondary));
    return ColetteCardSurface(
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.md.value,
        children: [
          GrowthTrendSummary(trend: trend),
          AspectRatio(
            aspectRatio: GrowthChart.aspectRatio,
            child: GrowthChart(
              metric: GrowthMetric.weight,
              points: points,
              reference: reference,
            ),
          ),
          Text(s.weightCurveHint, style: small),
          _WhoToggle(hasSex: hasSex, visible: showWho),
          if (showWho)
            Text(
              reference.isEmpty ? s.whoCurvesOutOfRange : s.whoCurvesLegend,
              style: small,
            ),
        ],
      ),
    );
  }
}
```

Supprimer les anciens fichiers :

```bash
git rm lib/features/baby/presentation/widgets/weight_chart.dart lib/features/baby/presentation/widgets/weight_chart_scale.dart lib/features/baby/presentation/widgets/weight_trend_summary.dart test/features/baby/presentation/weight_chart_scale_test.dart
```

- [ ] **Step 10: Run tests to verify they pass**

```bash
flutter gen-l10n
flutter test test/features/baby test/features/dashboard
```
Expected: PASS.

- [ ] **Step 11: Commit**

```bash
dart format lib test && dart analyze && flutter test
git add lib/features/baby/presentation lib/features/dashboard/presentation/widgets/weight_card.dart lib/l10n/app_fr.arb test/features/baby/presentation test/features/dashboard/presentation
git commit -m "feat: courbe, échelle et résumé génériques pour les grandeurs de croissance

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8 : feuille de mesure et section « Mesures »

**Files:**
- Create: `lib/features/baby/presentation/widgets/growth_input.dart`, `growth_measurement_sheet.dart`, `measurements_section.dart`
- Modify: `lib/features/baby/presentation/pages/weight_curve_page.dart`, `lib/features/baby/presentation/pages/settings_page.dart`, `lib/l10n/app_fr.arb`
- Delete: `lib/features/baby/presentation/widgets/add_weight_sheet.dart`, `weights_section.dart`, `test/features/baby/presentation/add_weight_sheet_test.dart`
- Test: `test/features/baby/presentation/growth_input_test.dart`, `growth_measurement_sheet_test.dart`, `measurements_section_test.dart`, `settings_page_test.dart`, `weight_curve_page_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/baby/presentation/growth_input_test.dart
import 'package:colette/features/baby/presentation/widgets/growth_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('grammes : vide → null, espaces ignorés, illisible → -1', () {
    expect(GrowthInput.grams(''), isNull);
    expect(GrowthInput.grams('  '), isNull);
    expect(GrowthInput.grams('3650'), 3650);
    expect(GrowthInput.grams('3 650'), 3650);
    expect(GrowthInput.grams('3,6'), GrowthInput.unreadable);
  });

  test('centimètres en millimètres : virgule ou point', () {
    expect(GrowthInput.millimetres(''), isNull);
    expect(GrowthInput.millimetres('54,5'), 545);
    expect(GrowthInput.millimetres('54.5'), 545);
    expect(GrowthInput.millimetres('37'), 370);
    expect(GrowthInput.millimetres('5a'), GrowthInput.unreadable);
  });
}
```

```dart
// test/features/baby/presentation/growth_measurement_sheet_test.dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/widgets/growth_measurement_sheet.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

class MockBabyRepository extends Mock implements BabyRepository {}

void main() {
  late MockBabyRepository repo;

  setUpAll(() {
    registerFallbackValue(GrowthMeasurement(id: 'x', measuredAt: DateTime(2026)));
  });

  setUp(() {
    repo = MockBabyRepository();
    when(() => repo.saveMeasurement(any(), any()))
        .thenAnswer((_) async => right(null));
  });

  List<Override> overrides() => [
    clockProvider.overrideWithValue(FixedClock(DateTime(2026, 9, 21, 12))),
    babyProfileProvider.overrideWith(
      (ref) => Stream.value(
        BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1)),
      ),
    ),
    babyRepositoryProvider.overrideWithValue(repo),
    feedingPlanSyncProvider.overrideWithValue(const NoopFeedingPlanSync()),
    idGeneratorProvider.overrideWithValue(const FixedIdGenerator('m-new')),
    householdLocalStoreProvider.overrideWithValue(
      InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
    ),
  ];

  VoidCallback? saveButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed;

  testWidgets('la date va de la naissance à aujourd\'hui', (tester) async {
    await pumpApp(
      tester,
      const Scaffold(body: GrowthMeasurementSheet()),
      overrides: overrides(),
    );
    await tester.tap(find.text('21 septembre 2026'));
    await tester.pumpAndSettle();
    final picker = tester.widget<CupertinoDatePicker>(
      find.byType(CupertinoDatePicker),
    );
    expect(picker.minimumDate, DateTime(2026, 9, 1));
    expect(picker.maximumDate, DateTime(2026, 9, 21, 12));
  });

  testWidgets('Enregistrer inactif tant que les trois champs sont vides', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const Scaffold(body: GrowthMeasurementSheet()),
      overrides: overrides(),
    );
    expect(find.text('Ajouter une mesure'), findsOneWidget);
    expect(saveButton(tester), isNull);
    await tester.enterText(
      find.widgetWithText(TextField, 'Taille (cm)'),
      '54,5',
    );
    await tester.pump();
    expect(saveButton(tester), isNotNull);
  });

  testWidgets('enregistre taille et périmètre sans poids', (tester) async {
    await pumpApp(
      tester,
      const Scaffold(body: GrowthMeasurementSheet()),
      overrides: overrides(),
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Taille (cm)'),
      '54,5',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Périmètre crânien (cm)'),
      '37',
    );
    await tester.pump();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final saved =
        verify(() => repo.saveMeasurement('ABCDEFGH', captureAny()))
                .captured
                .single
            as GrowthMeasurement;
    expect(
      saved,
      GrowthMeasurement(
        id: 'm-new',
        measuredAt: DateTime(2026, 9, 21),
        lengthMm: 545,
        headCircumferenceMm: 370,
      ),
    );
  });

  testWidgets('modification : champs préremplis et même identifiant', (
    tester,
  ) async {
    final initial = GrowthMeasurement(
      id: 'm1',
      measuredAt: DateTime(2026, 9, 14),
      grams: 3650,
      lengthMm: 545,
      headCircumferenceMm: 370,
    );
    await pumpApp(
      tester,
      Scaffold(body: GrowthMeasurementSheet(initial: initial)),
      overrides: overrides(),
    );
    expect(find.text('Modifier la mesure'), findsOneWidget);
    expect(find.text('14 septembre 2026'), findsOneWidget);
    expect(find.text('3650'), findsOneWidget);
    expect(find.text('54,5'), findsOneWidget);
    expect(find.text('37,0'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Périmètre crânien (cm)'),
      '',
    );
    await tester.pump();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final saved =
        verify(() => repo.saveMeasurement('ABCDEFGH', captureAny()))
                .captured
                .single
            as GrowthMeasurement;
    expect(saved, initial.copyWith(headCircumferenceMm: null));
  });
}
```

```dart
// test/features/baby/presentation/measurements_section_test.dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/widgets/growth_measurement_sheet.dart';
import 'package:colette/features/baby/presentation/widgets/measurements_section.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

class MockBabyRepository extends Mock implements BabyRepository {}

void main() {
  final measurements = [
    GrowthMeasurement(
      id: 'm2',
      measuredAt: DateTime(2026, 9, 14),
      grams: 3650,
      lengthMm: 545,
      headCircumferenceMm: 370,
    ),
    GrowthMeasurement(id: 'm1', measuredAt: DateTime(2026, 9, 2), grams: 3200),
  ];

  Future<MockBabyRepository> pump(
    WidgetTester tester,
    List<GrowthMeasurement> list,
  ) async {
    final repo = MockBabyRepository();
    when(() => repo.deleteMeasurement(any(), any()))
        .thenAnswer((_) async => right(null));
    await pumpApp(
      tester,
      const Scaffold(body: SingleChildScrollView(child: MeasurementsSection())),
      overrides: [
        clockProvider.overrideWithValue(FixedClock(DateTime(2026, 9, 21, 12))),
        babyProfileProvider.overrideWith(
          (ref) => Stream.value(
            BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1)),
          ),
        ),
        measurementsProvider.overrideWith((ref) => Stream.value(list)),
        babyRepositoryProvider.overrideWithValue(repo),
        feedingPlanSyncProvider.overrideWithValue(const NoopFeedingPlanSync()),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    return repo;
  }

  testWidgets('sans mesure : message et bouton d\'ajout', (tester) async {
    await pump(tester, const []);
    expect(
      find.text('Aucune mesure. Ajoute un poids pour un calcul au poids.'),
      findsOneWidget,
    );
    expect(find.text('Ajouter une mesure'), findsOneWidget);
  });

  testWidgets('une ligne par mesure avec ses valeurs et sa date', (
    tester,
  ) async {
    await pump(tester, measurements);
    expect(find.text('3650 g · 54,5 cm · PC 37,0 cm'), findsOneWidget);
    expect(find.text('14 sept. 2026'), findsOneWidget);
    expect(find.text('3200 g'), findsOneWidget);
  });

  testWidgets('toucher une ligne ouvre la feuille en modification', (
    tester,
  ) async {
    await pump(tester, measurements);
    await tester.tap(find.text('3650 g · 54,5 cm · PC 37,0 cm'));
    await tester.pumpAndSettle();
    expect(find.byType(GrowthMeasurementSheet), findsOneWidget);
    expect(find.text('Modifier la mesure'), findsOneWidget);
  });

  testWidgets('la poubelle supprime la mesure', (tester) async {
    final repo = await pump(tester, measurements);
    await tester.tap(find.byIcon(Icons.delete_outline).last);
    await tester.pumpAndSettle();
    verify(() => repo.deleteMeasurement('ABCDEFGH', 'm1')).called(1);
  });
}
```

Dans `settings_page_test.dart` : remplacer l'import `weight_entry.dart` par `growth_measurement.dart`, l'override `weightsProvider` par `measurementsProvider.overrideWith((ref) => Stream.value([GrowthMeasurement(id: 'w', measuredAt: DateTime(2026, 9, 9), grams: 3600)]))`, le titre du test par `'affiche le profil, les mesures et le code foyer'`, et ajouter `expect(find.text('Mesures'), findsOneWidget);` après `expect(find.text('3600 g'), findsOneWidget);`.

Dans `weight_curve_page_test.dart` : retirer l'override `weightsProvider` et l'import `weight_entry.dart` ; remplacer `import '…/add_weight_sheet.dart'` par `growth_measurement_sheet.dart` ; dans le test « sans pesée », remplacer le tap et l'attente par :

```dart
    await tester.tap(find.widgetWithText(FilledButton, 'Ajouter une mesure'));
    await tester.pumpAndSettle();
    expect(find.byType(GrowthMeasurementSheet), findsOneWidget);
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/baby/presentation`
Expected: FAIL (fichiers `growth_input.dart`, `growth_measurement_sheet.dart`, `measurements_section.dart` introuvables).

- [ ] **Step 3: Chaînes**

Dans `app_fr.arb`, après `"settingsAddWeight": …,` :

```json
  "settingsMeasurementsSection": "Mesures",
  "settingsMeasurementsEmpty": "Aucune mesure. Ajoute un poids pour un calcul au poids.",
  "actionAddMeasurement": "Ajouter une mesure",
  "editMeasurementTitle": "Modifier la mesure",
  "fieldLengthCm": "Taille (cm)",
  "fieldHeadCircumferenceCm": "Périmètre crânien (cm)",
```

Puis `flutter gen-l10n`.

- [ ] **Step 4: `GrowthInput`**

```dart
// lib/features/baby/presentation/widgets/growth_input.dart
/// Conversion des saisies de la feuille de mesure en valeurs entières.
abstract final class GrowthInput {
  /// Saisie illisible : hors de toutes les bornes, la validation la refuse
  /// avec la raison du champ concerné.
  static const unreadable = -1;

  static final _spaces = RegExp(r'\s');

  /// Grammes saisis (espaces ignorés) ; `null` si le champ est vide.
  static int? grams(String text) {
    final cleaned = text.replaceAll(_spaces, '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned) ?? unreadable;
  }

  /// Centimètres saisis (virgule ou point) en millimètres ; `null` si vide.
  static int? millimetres(String text) {
    final cleaned = text.replaceAll(_spaces, '').replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    final cm = double.tryParse(cleaned);
    return cm == null ? unreadable : (cm * 10).round();
  }
}
```

- [ ] **Step 5: `GrowthMeasurementSheet`**

```dart
// lib/features/baby/presentation/widgets/growth_measurement_sheet.dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/features/baby/presentation/widgets/growth_format.dart';
import 'package:colette/features/baby/presentation/widgets/growth_input.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/date_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Ouvre la saisie d'une mesure ; [initial] ouvre la modification de cette mesure.
Future<void> showGrowthMeasurementSheet(
  BuildContext context, {
  GrowthMeasurement? initial,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => GrowthMeasurementSheet(initial: initial),
);

/// Date (de la naissance à aujourd'hui), poids, taille et périmètre crânien,
/// chacun facultatif mais au moins un renseigné.
class GrowthMeasurementSheet extends ConsumerStatefulWidget {
  const GrowthMeasurementSheet({super.key, this.initial});

  /// Mesure modifiée, ou `null` pour une nouvelle mesure.
  final GrowthMeasurement? initial;

  @override
  ConsumerState<GrowthMeasurementSheet> createState() =>
      _GrowthMeasurementSheetState();
}

class _GrowthMeasurementSheetState
    extends ConsumerState<GrowthMeasurementSheet> {
  late final _gramsController = TextEditingController(
    text: widget.initial?.grams?.toString() ?? '',
  );
  late final _lengthController = TextEditingController(
    text: _centimetres(widget.initial?.lengthMm),
  );
  late final _headController = TextEditingController(
    text: _centimetres(widget.initial?.headCircumferenceMm),
  );
  late final _fields = Listenable.merge([
    _gramsController,
    _lengthController,
    _headController,
  ]);
  late DateTime _measuredAt =
      widget.initial?.measuredAt ?? ref.read(clockProvider).now().dateOnly;

  static String _centimetres(int? mm) =>
      mm == null ? '' : GrowthFormat.centimetres(mm);

  bool get _allEmpty => [
    _gramsController,
    _lengthController,
    _headController,
  ].every((c) => c.text.trim().isEmpty);

  @override
  void dispose() {
    _gramsController.dispose();
    _lengthController.dispose();
    _headController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: _measuredAt,
      mode: CupertinoDatePickerMode.date,
      maximum: ref.read(clockProvider).now(),
      minimum: ref.read(babyProfileProvider).value?.birthDate,
    );
    if (picked != null) setState(() => _measuredAt = picked.dateOnly);
  }

  Future<void> _save() async {
    final ok = await ref
        .read(babySettingsControllerProvider.notifier)
        .saveMeasurement(
          id: widget.initial?.id,
          measuredAt: _measuredAt,
          grams: GrowthInput.grams(_gramsController.text),
          lengthMm: GrowthInput.millimetres(_lengthController.text),
          headCircumferenceMm: GrowthInput.millimetres(_headController.text),
        );
    if (ok && mounted) await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    // Gardé à l'écoute : `_pickDate` y lit la date de naissance, borne basse.
    ref.watch(babyProfileProvider);
    const decimal = TextInputType.numberWithOptions(decimal: true);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        shrinkWrap: true,
        padding: AppSpacing.lg.all,
        children: [
          Text(
            widget.initial == null
                ? s.actionAddMeasurement
                : s.editMeasurementTitle,
            style: Theme.of(context).coletteTextStyles.heading2,
          ),
          AppSpacing.md.verticalSpace,
          DateField(
            label: s.fieldMeasuredAt,
            value: DateFormat.yMMMMd('fr').format(_measuredAt),
            onTap: _pickDate,
          ),
          AppSpacing.md.verticalSpace,
          TextField(
            controller: _gramsController,
            decoration: InputDecoration(labelText: s.fieldWeightGrams),
            keyboardType: TextInputType.number,
            autofocus: widget.initial == null,
          ),
          AppSpacing.md.verticalSpace,
          TextField(
            controller: _lengthController,
            decoration: InputDecoration(labelText: s.fieldLengthCm),
            keyboardType: decimal,
          ),
          AppSpacing.md.verticalSpace,
          TextField(
            controller: _headController,
            decoration: InputDecoration(labelText: s.fieldHeadCircumferenceCm),
            keyboardType: decimal,
          ),
          AppSpacing.lg.verticalSpace,
          ListenableBuilder(
            listenable: _fields,
            builder: (context, _) => FilledButton(
              onPressed: _allEmpty ? null : _save,
              child: Text(s.actionSave),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: `MeasurementsSection`**

```dart
// lib/features/baby/presentation/widgets/measurements_section.dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/features/baby/presentation/widgets/growth_format.dart';
import 'package:colette/features/baby/presentation/widgets/growth_measurement_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Liste des mesures de croissance : ajout, modification et suppression.
class MeasurementsSection extends ConsumerWidget {
  const MeasurementsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final measurements =
        ref.watch(measurementsProvider).value ?? const <GrowthMeasurement>[];
    return ColetteCardSurface(
      padding: AppSpacing.sm.all,
      child: Column(
        children: [
          if (measurements.isEmpty)
            Padding(
              padding: AppSpacing.sm.all,
              child: Text(
                s.settingsMeasurementsEmpty,
                style: styles.body.copyWith(
                  color: context.appColor(AppColors.textSecondary),
                ),
              ),
            ),
          for (final measurement in measurements)
            ListTile(
              dense: true,
              title: Text(
                GrowthFormat.measurementLine(s, measurement),
                style: styles.bodyMedium,
              ),
              subtitle: Text(
                DateFormat.yMMMd('fr').format(measurement.measuredAt),
                style: styles.small,
              ),
              onTap: () =>
                  showGrowthMeasurementSheet(context, initial: measurement),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: s.actionDelete,
                onPressed: () => ref
                    .read(babySettingsControllerProvider.notifier)
                    .deleteMeasurement(measurement.id),
              ),
            ),
          TextButton.icon(
            onPressed: () => showGrowthMeasurementSheet(context),
            icon: const Icon(Icons.add),
            label: Text(s.actionAddMeasurement),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 7: Brancher les pages et supprimer l'ancien code**

`settings_page.dart` : remplacer l'import `weights_section.dart` par `measurements_section.dart`, `SectionHeader(title: s.settingsWeightsSection), const WeightsSection(),` par `SectionHeader(title: s.settingsMeasurementsSection), const MeasurementsSection(),`, et la doc de classe par `/// Onglet Réglages : bébé, mesures, soins attendus, notifications, apparence, foyer.`

`weight_curve_page.dart` : remplacer les imports `add_weight_sheet.dart` et `weights_section.dart` par `growth_measurement_sheet.dart` et `measurements_section.dart` ; dans `build`, `SectionHeader(title: s.settingsMeasurementsSection), const MeasurementsSection(),` ; dans `_EmptySection`, le bouton devient :

```dart
        FilledButton.icon(
          onPressed: () => showGrowthMeasurementSheet(context),
          icon: const Icon(Icons.add),
          label: Text(s.actionAddMeasurement),
        ),
```

Le commentaire du `ref.listen` devient « … pendant les suppressions lancées depuis `MeasurementsSection`. »

```bash
git rm lib/features/baby/presentation/widgets/add_weight_sheet.dart lib/features/baby/presentation/widgets/weights_section.dart test/features/baby/presentation/add_weight_sheet_test.dart
```

- [ ] **Step 8: Run tests to verify they pass**

Run: `flutter test test/features/baby`
Expected: PASS.

- [ ] **Step 9: Commit**

```bash
dart format lib test && dart analyze && flutter test
git add lib/features/baby/presentation lib/l10n/app_fr.arb test/features/baby/presentation
git commit -m "feat: feuille de mesure (poids, taille, périmètre) et section Mesures

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9 : page « Croissance » à onglets

**Files:**
- Create: `lib/features/baby/presentation/providers/selected_growth_metric.dart`, `lib/features/baby/presentation/pages/growth_page.dart`
- Modify: `lib/features/baby/presentation/widgets/growth_format.dart` (ajout `label`), `lib/app/router/app_router.dart`, `lib/features/dashboard/presentation/widgets/weight_card.dart`, `lib/l10n/app_fr.arb`
- Delete: `lib/features/baby/presentation/pages/weight_curve_page.dart`, `test/features/baby/presentation/weight_curve_page_test.dart`
- Test: `test/features/baby/presentation/growth_page_test.dart`, `test/features/dashboard/presentation/weight_card_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/baby/presentation/growth_page_test.dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/baby_sex.dart';
import 'package:colette/features/baby/domain/entities/growth_measurement.dart';
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:colette/features/baby/presentation/pages/growth_page.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/providers/who_curves_visibility.dart';
import 'package:colette/features/baby/presentation/widgets/growth_measurement_sheet.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final measurements = [
    GrowthMeasurement(
      id: 'a',
      measuredAt: DateTime(2026, 9, 2),
      grams: 3200,
      lengthMm: 520,
      headCircumferenceMm: 350,
    ),
    GrowthMeasurement(
      id: 'c',
      measuredAt: DateTime(2026, 9, 14),
      grams: 3650,
      lengthMm: 540,
    ),
    GrowthMeasurement(id: 'b', measuredAt: DateTime(2026, 9, 10), grams: 3470),
  ];

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  List<Override> overrides(List<GrowthMeasurement> list, {BabySex? sex}) => [
    sharedPreferencesProvider.overrideWithValue(prefs),
    babyProfileProvider.overrideWith(
      (ref) => Stream.value(
        BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1), sex: sex),
      ),
    ),
    clockProvider.overrideWithValue(FixedClock(DateTime(2026, 9, 15, 12))),
    householdLocalStoreProvider.overrideWithValue(
      InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
    ),
    measurementsProvider.overrideWith((ref) => Stream.value(list)),
    feedingPlanSyncProvider.overrideWithValue(const NoopFeedingPlanSync()),
  ];

  Future<void> selectTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  int barCount(WidgetTester tester) =>
      tester.widget<LineChart>(find.byType(LineChart)).data.lineBarsData.length;

  testWidgets('s\'ouvre sur le poids : dernière pesée, évolution, courbe', (
    tester,
  ) async {
    await pumpApp(tester, const GrowthPage(), overrides: overrides(measurements));
    expect(find.text('Croissance'), findsOneWidget);
    final selector = tester.widget<SegmentedButton<GrowthMetric>>(
      find.byType(SegmentedButton<GrowthMetric>),
    );
    expect(selector.selected, {GrowthMetric.weight});
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('3650 g'), findsOneWidget);
    expect(find.text('Pesée du 14 sept. 2026'), findsOneWidget);
    expect(
      find.text('+180 g en 4 jours · +45 g/jour'),
      findsOneWidget,
    );
    expect(find.text('2 sept.'), findsOneWidget);
    expect(find.text('14 sept.'), findsOneWidget);
  });

  testWidgets('onglet Taille : valeur en cm et évolution', (tester) async {
    await pumpApp(tester, const GrowthPage(), overrides: overrides(measurements));
    await selectTab(tester, 'Taille');
    expect(find.text('54,0 cm'), findsOneWidget);
    expect(find.text('Mesure du 14 sept. 2026'), findsOneWidget);
    expect(find.text('+2,0 cm en 12 jours'), findsOneWidget);
  });

  testWidgets('onglet Périmètre : une seule valeur, « Première mesure »', (
    tester,
  ) async {
    await pumpApp(tester, const GrowthPage(), overrides: overrides(measurements));
    await selectTab(tester, 'Périmètre');
    expect(find.text('35,0 cm'), findsOneWidget);
    expect(find.text('Première mesure'), findsOneWidget);
  });

  testWidgets('grandeur jamais mesurée : état vide et ajout', (tester) async {
    await pumpApp(
      tester,
      const GrowthPage(),
      overrides: overrides([measurements.last]),
    );
    await selectTab(tester, 'Périmètre');
    expect(find.text('Aucun périmètre crânien enregistré'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Ajouter une mesure'));
    await tester.pumpAndSettle();
    expect(find.byType(GrowthMeasurementSheet), findsOneWidget);
  });

  testWidgets('sans aucune mesure : état vide du poids', (tester) async {
    await pumpApp(tester, const GrowthPage(), overrides: overrides(const []));
    expect(find.text('Aucun poids enregistré'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('courbes OMS cachées par défaut, le bouton les affiche', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const GrowthPage(),
      overrides: overrides(measurements, sex: BabySex.female),
    );
    expect(barCount(tester), 1);
    await tester.ensureVisible(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(barCount(tester), 4);
    expect(prefs.getBool(WhoCurvesVisibility.prefsKey), isTrue);
  });

  testWidgets('le choix OMS vaut pour toutes les grandeurs', (tester) async {
    await prefs.setBool(WhoCurvesVisibility.prefsKey, true);
    await pumpApp(
      tester,
      const GrowthPage(),
      overrides: overrides(measurements, sex: BabySex.male),
    );
    expect(barCount(tester), 4);
    await selectTab(tester, 'Taille');
    expect(barCount(tester), 4);
  });

  testWidgets('sans sexe renseigné : bouton inactif et invitation', (
    tester,
  ) async {
    await prefs.setBool(WhoCurvesVisibility.prefsKey, true);
    await pumpApp(tester, const GrowthPage(), overrides: overrides(measurements));
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    expect(
      find.text('Renseigne le sexe du bébé dans les Réglages pour les afficher.'),
      findsOneWidget,
    );
    expect(barCount(tester), 1);
  });

  testWidgets('la liste des mesures est sous la courbe', (tester) async {
    await pumpApp(tester, const GrowthPage(), overrides: overrides(measurements));
    await tester.scrollUntilVisible(
      find.text('3200 g · 52,0 cm · PC 35,0 cm'),
      200,
    );
    expect(find.text('Mesures'), findsOneWidget);
  });
}
```

Dans `weight_card_test.dart`, remplacer `path: 'weights'` par `path: 'growth'` et `Text('page courbe')` par `Text('page croissance')` (et l'`expect` correspondant), titre du test : `'taper la carte ouvre la page de croissance'`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/baby/presentation/growth_page_test.dart test/features/dashboard/presentation/weight_card_test.dart`
Expected: FAIL (`growth_page.dart` introuvable ; la carte pousse encore `/today/weights`).

- [ ] **Step 3: Chaînes et libellés**

Dans `app_fr.arb`, après `"weightCurveHint": …,` :

```json
  "growthTitle": "Croissance",
  "growthMetricWeight": "Poids",
  "growthMetricLength": "Taille",
  "growthMetricHeadCircumference": "Périmètre",
  "growthEmptyWeight": "Aucun poids enregistré",
  "growthEmptyLength": "Aucune taille enregistrée",
  "growthEmptyHeadCircumference": "Aucun périmètre crânien enregistré",
  "growthCurveHint": "Touche la courbe pour afficher une mesure.",
```

Puis `flutter gen-l10n`. Dans `GrowthFormat`, ajouter :

```dart
  /// Nom court de [metric], pour le sélecteur.
  static String label(S s, GrowthMetric metric) => switch (metric) {
    GrowthMetric.weight => s.growthMetricWeight,
    GrowthMetric.length => s.growthMetricLength,
    GrowthMetric.headCircumference => s.growthMetricHeadCircumference,
  };

  /// Message quand [metric] n'a jamais été mesurée.
  static String empty(S s, GrowthMetric metric) => switch (metric) {
    GrowthMetric.weight => s.growthEmptyWeight,
    GrowthMetric.length => s.growthEmptyLength,
    GrowthMetric.headCircumference => s.growthEmptyHeadCircumference,
  };
```

- [ ] **Step 4: Provider de l'onglet**

```dart
// lib/features/baby/presentation/providers/selected_growth_metric.dart
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_growth_metric.g.dart';

/// Grandeur affichée sur la page Croissance ; revient au poids à chaque ouverture.
@riverpod
class SelectedGrowthMetric extends _$SelectedGrowthMetric {
  @override
  GrowthMetric build() => GrowthMetric.weight;

  void set(GrowthMetric metric) => state = metric;
}
```

- [ ] **Step 5: `GrowthPage`**

```dart
// lib/features/baby/presentation/pages/growth_page.dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/baby/domain/entities/growth_metric.dart';
import 'package:colette/features/baby/domain/entities/growth_trend.dart';
import 'package:colette/features/baby/domain/entities/who_percentiles.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/features/baby/presentation/providers/selected_growth_metric.dart';
import 'package:colette/features/baby/presentation/providers/who_curves_visibility.dart';
import 'package:colette/features/baby/presentation/widgets/growth_chart.dart';
import 'package:colette/features/baby/presentation/widgets/growth_format.dart';
import 'package:colette/features/baby/presentation/widgets/growth_measurement_sheet.dart';
import 'package:colette/features/baby/presentation/widgets/growth_trend_summary.dart';
import 'package:colette/features/baby/presentation/widgets/measurements_section.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Croissance : sélecteur de grandeur, dernière valeur, évolution, courbe
/// (avec repères OMS optionnels) et liste des mesures.
class GrowthPage extends ConsumerWidget {
  const GrowthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    // Écoute aussi pour garder le contrôleur autoDispose en vie pendant
    // les suppressions lancées depuis `MeasurementsSection`.
    ref.listen(babySettingsControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage(error, s))));
      }
    });
    final metric = ref.watch(selectedGrowthMetricProvider);
    final points = metric.seriesOf(
      ref.watch(measurementsProvider).value ?? const [],
    );
    final trend = ref.watch(growthTrendProvider(metric));
    return Scaffold(
      appBar: AppBar(title: Text(s.growthTitle)),
      body: ListView(
        padding: AppSpacing.md.horizontal,
        children: [
          AppSpacing.md.verticalSpace,
          _MetricSelector(selected: metric),
          AppSpacing.md.verticalSpace,
          if (trend == null)
            _EmptySection(metric: metric)
          else
            _ChartSection(metric: metric, points: points, trend: trend),
          SectionHeader(title: s.settingsMeasurementsSection),
          const MeasurementsSection(),
          AppSpacing.xl.verticalSpace,
        ],
      ),
    );
  }
}

/// Poids / Taille / Périmètre.
class _MetricSelector extends ConsumerWidget {
  const _MetricSelector({required this.selected});

  final GrowthMetric selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    return SegmentedButton<GrowthMetric>(
      segments: [
        for (final metric in GrowthMetric.values)
          ButtonSegment(
            value: metric,
            label: Text(GrowthFormat.label(s, metric)),
          ),
      ],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (selection) =>
          ref.read(selectedGrowthMetricProvider.notifier).set(selection.first),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.metric});

  final GrowthMetric metric;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      children: [
        EmptyState(
          icon: switch (metric) {
            GrowthMetric.weight => Icons.monitor_weight_outlined,
            GrowthMetric.length => Icons.straighten,
            GrowthMetric.headCircumference => Icons.child_care_outlined,
          },
          message: GrowthFormat.empty(s, metric),
        ),
        FilledButton.icon(
          onPressed: () => showGrowthMeasurementSheet(context),
          icon: const Icon(Icons.add),
          label: Text(s.actionAddMeasurement),
        ),
      ],
    );
  }
}

class _ChartSection extends ConsumerWidget {
  const _ChartSection({
    required this.metric,
    required this.points,
    required this.trend,
  });

  final GrowthMetric metric;
  final List<GrowthPoint> points;
  final GrowthTrend trend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final hasSex = ref.watch(babyProfileProvider).value?.sex != null;
    final showWho = hasSex && ref.watch(whoCurvesVisibilityProvider);
    final reference = showWho
        ? ref.watch(whoReferenceProvider(metric))
        : const <WhoPercentiles>[];
    final small = Theme.of(context).coletteTextStyles.small
        .copyWith(color: context.appColor(AppColors.textSecondary));
    return ColetteCardSurface(
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.md.value,
        children: [
          GrowthTrendSummary(trend: trend),
          AspectRatio(
            aspectRatio: GrowthChart.aspectRatio,
            child: GrowthChart(
              metric: metric,
              points: points,
              reference: reference,
            ),
          ),
          Text(s.growthCurveHint, style: small),
          _WhoToggle(hasSex: hasSex, visible: showWho),
          if (showWho)
            Text(
              reference.isEmpty ? s.whoCurvesOutOfRange : s.whoCurvesLegend,
              style: small,
            ),
        ],
      ),
    );
  }
}

/// Interrupteur des courbes OMS, commun aux trois grandeurs, inactif tant que
/// le sexe n'est pas renseigné.
class _WhoToggle extends ConsumerWidget {
  const _WhoToggle({required this.hasSex, required this.visible});

  final bool hasSex;
  final bool visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(s.whoCurvesToggle, style: styles.bodyMedium),
      subtitle: hasSex
          ? null
          : Text(
              s.whoCurvesNeedsSex,
              style: styles.small.copyWith(
                color: context.appColor(AppColors.textSecondary),
              ),
            ),
      value: visible,
      onChanged: hasSex
          ? (value) => ref.read(whoCurvesVisibilityProvider.notifier).set(value)
          : null,
    );
  }
}
```

- [ ] **Step 6: Route et carte**

Dans `app_router.dart` : remplacer l'import `weight_curve_page.dart` par `growth_page.dart` ; remplacer

```dart
  /// Courbe de poids, imbriquée sous Aujourd'hui pour garder la barre d'onglets.
  static const weights = '/today/weights';
```

par

```dart
  /// Page Croissance, imbriquée sous Aujourd'hui pour garder la barre d'onglets.
  static const growth = '/today/growth';
```

et la route `GoRoute(path: 'weights', builder: (_, _) => const WeightCurvePage())` par `GoRoute(path: 'growth', builder: (_, _) => const GrowthPage())`.

Dans `weight_card.dart` : `onTap: () => context.push(AppRoutes.growth),`.

```bash
git rm lib/features/baby/presentation/pages/weight_curve_page.dart test/features/baby/presentation/weight_curve_page_test.dart
dart run build_runner build -d
```

- [ ] **Step 7: Run tests to verify they pass**

Run: `flutter test test/features/baby test/features/dashboard test/app`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
dart format lib test && dart analyze && flutter test
git add lib/features/baby/presentation lib/app/router lib/features/dashboard/presentation/widgets/weight_card.dart lib/l10n/app_fr.arb test/features/baby/presentation test/features/dashboard/presentation/weight_card_test.dart
git commit -m "feat: page Croissance à onglets poids, taille et périmètre crânien

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 10 : suppression de l'ancien modèle « pesée »

**Files:**
- Delete: `lib/features/baby/domain/entities/weight_entry.dart` (+ `.freezed.dart`), `weight_trend.dart` (+ `.freezed.dart`), `who_weight_percentiles.dart` (+ `.freezed.dart`), `lib/features/baby/domain/use_cases/compute_weight_trend.dart`, `compute_who_weight_reference.dart`, `lib/features/baby/data/dtos/weight_entry_dto.dart`, `test/features/baby/domain/compute_weight_trend_test.dart`, `test/features/baby/domain/compute_who_weight_reference_test.dart`
- Modify: `baby_repository.dart`, `firestore_baby_repository.dart`, `baby_providers.dart`, `baby_settings_controller.dart`, `lib/l10n/app_fr.arb`, `test/features/baby/data/firestore_baby_repository_test.dart`, `test/features/baby/presentation/baby_settings_controller_test.dart`, `test/features/baby/presentation/baby_providers_retry_test.dart`

- [ ] **Step 1: Adapter les tests restants**

`baby_providers_retry_test.dart` : importer `growth_measurement.dart` au lieu de `weight_entry.dart`, remplacer le stub par `when(() => repo.watchMeasurements(any())).thenAnswer((_) => Stream<List<GrowthMeasurement>>.error(_failure));` et le second test par :

```dart
  test('measurements remonte la failure en AsyncError sans relance', () async {
    final container = containerWith(repo);
    final sub = container.listen(measurementsProvider, (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();
    final state = container.read(measurementsProvider);
    expect(state, isA<AsyncError<List<GrowthMeasurement>>>());
    expect(state.retrying, isFalse);
  });
```

`firestore_baby_repository_test.dart` : supprimer les tests `les pesées sont triées…` et `deleteWeight retire la pesée`, ainsi que l'import `weight_entry.dart` ; ajouter dans le groupe « mesures de croissance » :

```dart
    test('triées de la plus récente à la plus ancienne', () async {
      final repo = FirestoreBabyRepository(FakeFirebaseFirestore());
      await repo.saveMeasurement(
        code,
        GrowthMeasurement(id: 'm1', measuredAt: DateTime(2026, 9, 2), grams: 3200),
      );
      await repo.saveMeasurement(
        code,
        GrowthMeasurement(id: 'm2', measuredAt: DateTime(2026, 9, 10), grams: 3600),
      );
      final measurements = await repo.watchMeasurements(code).first;
      expect(measurements.map((m) => m.id), ['m2', 'm1']);
    });
```

`baby_settings_controller_test.dart` : supprimer les tests `addWeight refuse…` et `addWeight enregistre…`, le `registerFallbackValue(WeightEntry(...))` et l'import `weight_entry.dart`. Ajouter :

```dart
  test('saveMeasurement refuse un poids hors bornes', () async {
    final ok = await controller().saveMeasurement(
      measuredAt: DateTime(2026, 9, 10),
      grams: 500,
    );
    expect(ok, isFalse);
    expect(
      (container.read(babySettingsControllerProvider).error!
              as ValidationFailure)
          .reason,
      ValidationReason.invalidWeight,
    );
    verifyNever(() => repo.saveMeasurement(any(), any()));
  });
```

- [ ] **Step 2: Supprimer l'ancien code**

```bash
git rm lib/features/baby/domain/entities/weight_entry.dart lib/features/baby/domain/entities/weight_entry.freezed.dart \
  lib/features/baby/domain/entities/weight_trend.dart lib/features/baby/domain/entities/weight_trend.freezed.dart \
  lib/features/baby/domain/entities/who_weight_percentiles.dart lib/features/baby/domain/entities/who_weight_percentiles.freezed.dart \
  lib/features/baby/domain/use_cases/compute_weight_trend.dart lib/features/baby/domain/use_cases/compute_who_weight_reference.dart \
  lib/features/baby/data/dtos/weight_entry_dto.dart \
  test/features/baby/domain/compute_weight_trend_test.dart test/features/baby/domain/compute_who_weight_reference_test.dart
```

Les cas de `compute_who_weight_reference_test.dart` sont couverts par `compute_who_reference_test.dart` (tâche 4), ceux de `compute_weight_trend_test.dart` par `compute_growth_trend_test.dart` (tâche 3).

- `baby_repository.dart` : retirer `watchWeights`, `addWeight`, `deleteWeight` et l'import `weight_entry.dart` ; doc de classe : `/// Profil du bébé, mesures de croissance et résumé du plan biberons.`
- `firestore_baby_repository.dart` : retirer les trois implémentations et les imports `weight_entry_dto.dart`, `weight_entry.dart`.
- `baby_providers.dart` : retirer `weights`, `weightTrend`, `whoWeightReference` et les imports `weight_entry.dart`, `weight_trend.dart`, `who_weight_percentiles.dart`, `compute_weight_trend.dart`, `compute_who_weight_reference.dart`.
- `baby_settings_controller.dart` : retirer `minWeightGrams`, `maxWeightGrams`, `addWeight`, `deleteWeight` et l'import `weight_entry.dart`.
- `app_fr.arb` : retirer `weightCurveTitle`, `weightCurveEmpty`, `weightCurveHint`, `settingsWeightsSection`, `settingsWeightsEmpty`, `settingsAddWeight`.

Vérifier qu'aucune référence ne subsiste :

```bash
grep -rnE "WeightEntry|WeightTrend|WhoWeightPercentiles|ComputeWeightTrend|ComputeWhoWeightReference|weightsProvider|weightTrendProvider|whoWeightReferenceProvider|watchWeights|addWeight|deleteWeight|weightCurve(Title|Empty|Hint)|settingsWeights|settingsAddWeight|AppRoutes.weights" lib test --include='*.dart' --include='*.arb' | grep -v '\.g\.dart'
```
Expected: aucune ligne.

- [ ] **Step 3: Generate, analyze, test**

```bash
dart run build_runner build -d
flutter gen-l10n
dart format lib test && dart analyze && flutter test
```
Expected: 0 problème, tous les tests verts.

- [ ] **Step 4: Commit**

```bash
git add -u lib test
git add lib/features/baby/presentation/providers/baby_providers.g.dart
git commit -m "chore: suppression de l'ancien modèle pesée au profit des mesures de croissance

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 11 : vérification finale

- [ ] **Step 1: Vérifications automatiques**

```bash
dart format lib test
dart analyze
flutter test
```
Expected: aucun fichier reformaté, 0 problème, tous les tests verts.

- [ ] **Step 2: Contrôle des règles du design system sur les nouveaux fichiers**

```bash
grep -nE "Colors\.|Color\(0x|TextStyle\(|fontSize|width: [0-9]|height: [0-9]|EdgeInsets\.(all|only|symmetric)\([0-9]" \
  lib/features/baby/presentation/pages/growth_page.dart \
  lib/features/baby/presentation/widgets/growth_*.dart \
  lib/features/baby/presentation/widgets/measurements_section.dart
```
Expected: aucune ligne.

- [ ] **Step 3: Simulateur iPhone, thème clair puis sombre**

Lancer l'app sur un simulateur iPhone (`make run` ou `flutter run -d "iPhone 17 Pro"`). Ne pas créer de foyer de test dans le Firestore de production sans l'accord explicite de Maxence : si aucun foyer n'est déjà configuré sur le simulateur, s'arrêter là et le signaler. Sinon vérifier, en clair puis en sombre :

1. Carte Poids de l'accueil → ouvre « Croissance » sur l'onglet Poids.
2. Onglets Taille et Périmètre : état vide lisible, bouton « Ajouter une mesure ».
3. Feuille : bouton Enregistrer grisé tant que tout est vide, clavier décimal pour les cm.
4. Réglages : section « Mesures ».

- [ ] **Step 4: Rapport**

Lister les commits de la branche (`git log --oneline main..HEAD`), la divergence avec `main` et les conflits simulés (`git merge-tree --write-tree main HEAD`), puis demander à Maxence la validation du merge `--no-ff` « merge: mesures de croissance, taille et périmètre crânien (feat/growth-measurements) ». Rappeler que les deux iPhones doivent recevoir la nouvelle version (installation `devicectl` par-dessus l'app) avant la première mesure sans poids.
