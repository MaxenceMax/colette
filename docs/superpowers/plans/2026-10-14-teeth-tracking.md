# Suivi des dents — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ajouter dans l'onglet Santé une carte « Dents » qui ouvre un schéma interactif des dents de lait et définitives, où l'on note la sortie, la chute et une note pour chaque dent.

**Architecture:** Nouvelle feature `lib/features/teeth/` (domain / data / presentation). Le domaine décode les numéros FDI, porte la table de repères ADA et calcule statut, résumé et validation. La donnée vit dans `households/{code}/teeth/{fdi}`. Le schéma est un `CustomPainter` piloté par une géométrie pure (`TeethLayout`) qui sert aussi au test de toucher.

**Tech Stack:** Flutter (iOS), Riverpod 3 codegen, freezed, fpdart, cloud_firestore, fake_cloud_firestore, mocktail, go_router.

**Spec :** `docs/superpowers/specs/2026-10-14-teeth-tracking-design.md`.

---

## Règles communes à toutes les tâches

- Travailler dans le worktree `.claude/worktrees/teeth-tracking` (branche `feat/teeth-tracking`). Jamais dans le checkout principal, jamais de `git stash` nu.
- Après toute création ou modification d'un fichier annoté (`@freezed`, `@riverpod`) : `dart run build_runner build -d`.
- Après toute modification de `lib/l10n/app_fr.arb` : `flutter gen-l10n` (le dossier `lib/l10n/generated/` n'est pas versionné).
- Commits : `git add` de chemins explicites, message en français, une ligne, terminé par la ligne `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` (via un second `-m`).
- Ne jamais toucher `docs/` (sauf la tâche 14), ni reverter des changements sans lien.
- Design system : `context.appColor(AppColors.x)`, `AppSpacing`, `AppSize`, `AppRadius`, `coletteTextStyles`, `S.of(context)`. Aucune couleur, taille ou chaîne UI en dur.

## Structure des fichiers

| Fichier | Rôle |
| --- | --- |
| `lib/features/teeth/domain/entities/tooth_id.dart` | Enums `Dentition`, `ToothArch`, `ToothSide`, `ToothKind` ; extension type `ToothId` (numéro FDI). |
| `lib/features/teeth/domain/reference/tooth_schedule.dart` | `AgeUnit`, records `AgeRange` et `ToothReference`, table ADA, `toothReferenceOf`. |
| `lib/features/teeth/domain/entities/tooth_record.dart` | Entité freezed `ToothRecord`. |
| `lib/features/teeth/domain/entities/tooth_status.dart` | Enum `ToothStatus`. |
| `lib/features/teeth/domain/entities/teeth_summary.dart` | Record `ExpectedTeethGroup`, classe `TeethSummary`. |
| `lib/features/teeth/domain/use_cases/compute_tooth_status.dart` | Statut d'une dent. |
| `lib/features/teeth/domain/use_cases/validate_tooth_record.dart` | Validation et normalisation de la note. |
| `lib/features/teeth/domain/use_cases/compute_teeth_summary.dart` | Dents en bouche et groupes attendus. |
| `lib/features/teeth/domain/repositories/teeth_repository.dart` | Interface du dépôt. |
| `lib/features/teeth/data/dtos/tooth_record_dto.dart` | `ToothRecord` ↔ document Firestore. |
| `lib/features/teeth/data/repositories/firestore_teeth_repository.dart` | Implémentation Firestore. |
| `lib/features/teeth/presentation/providers/teeth_providers.dart` | Dépôt, flux des dents, résumé. |
| `lib/features/teeth/presentation/providers/teeth_controller.dart` | Enregistrer / effacer une dent. |
| `lib/features/teeth/presentation/teeth_ui.dart` | Libellés (noms, groupes, âges, VoiceOver, compteur). |
| `lib/features/teeth/presentation/widgets/teeth_layout.dart` | Géométrie du schéma et test de toucher. |
| `lib/features/teeth/presentation/widgets/teeth_chart_painter.dart` | Dessin et sémantique des dents. |
| `lib/features/teeth/presentation/widgets/teeth_chart.dart` | Widget du schéma (toucher, libellés Haut/Bas/Droite/Gauche). |
| `lib/features/teeth/presentation/widgets/teeth_legend.dart` | Légende. |
| `lib/features/teeth/presentation/widgets/optional_date_field.dart` | Date facultative (ajouter / modifier / retirer). |
| `lib/features/teeth/presentation/widgets/tooth_sheet.dart` | Fiche d'une dent. |
| `lib/features/teeth/presentation/widgets/teeth_card.dart` | Carte de l'onglet Santé. |
| `lib/features/teeth/presentation/pages/teeth_page.dart` | Page Dents. |
| Modifiés | `core/result/failure.dart`, `core/ui/failure_message.dart`, `core/firebase/firestore_paths.dart`, `l10n/app_fr.arb`, `app/router/app_router.dart`, `features/health/presentation/pages/health_page.dart`, `firestore.rules`. |
| Tests | `test/features/teeth/…` (domaine, data, présentation), `test/features/teeth/teeth_factories.dart`, `test/features/health/presentation/health_page_test.dart`. |

---

### Task 1 : identité d'une dent (`ToothId`)

**Files:**
- Create: `lib/features/teeth/domain/entities/tooth_id.dart`
- Create: `test/features/teeth/teeth_factories.dart`
- Test: `test/features/teeth/domain/tooth_id_test.dart`

- [ ] **Step 1 : écrire la fabrique de test**

`test/features/teeth/teeth_factories.dart` :

```dart
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';

/// Dent de test à partir de son numéro FDI ; échoue si le numéro est inconnu.
ToothId tooth(int number) => ToothId.tryParse(number)!;
```

- [ ] **Step 2 : écrire le test qui échoue**

`test/features/teeth/domain/tooth_id_test.dart` :

```dart
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:flutter_test/flutter_test.dart';

import '../teeth_factories.dart';

void main() {
  test('décode dentition, arcade, côté et type', () {
    (Dentition, ToothArch, ToothSide, ToothKind) decode(int n) {
      final id = tooth(n);
      return (id.dentition, id.arch, id.side, id.kind);
    }

    expect(decode(51), (
      Dentition.primary,
      ToothArch.upper,
      ToothSide.right,
      ToothKind.centralIncisor,
    ));
    expect(decode(55), (
      Dentition.primary,
      ToothArch.upper,
      ToothSide.right,
      ToothKind.secondMolar,
    ));
    expect(decode(65), (
      Dentition.primary,
      ToothArch.upper,
      ToothSide.left,
      ToothKind.secondMolar,
    ));
    expect(decode(71), (
      Dentition.primary,
      ToothArch.lower,
      ToothSide.left,
      ToothKind.centralIncisor,
    ));
    expect(decode(84), (
      Dentition.primary,
      ToothArch.lower,
      ToothSide.right,
      ToothKind.firstMolar,
    ));
    expect(decode(11), (
      Dentition.permanent,
      ToothArch.upper,
      ToothSide.right,
      ToothKind.centralIncisor,
    ));
    expect(decode(18), (
      Dentition.permanent,
      ToothArch.upper,
      ToothSide.right,
      ToothKind.thirdMolar,
    ));
    expect(decode(24), (
      Dentition.permanent,
      ToothArch.upper,
      ToothSide.left,
      ToothKind.firstPremolar,
    ));
    expect(decode(36), (
      Dentition.permanent,
      ToothArch.lower,
      ToothSide.left,
      ToothKind.firstMolar,
    ));
    expect(decode(48), (
      Dentition.permanent,
      ToothArch.lower,
      ToothSide.right,
      ToothKind.thirdMolar,
    ));
  });

  test('tryParse refuse les numéros hors table', () {
    for (final n in [0, 10, 19, 49, 56, 90, 99, 100, -11]) {
      expect(ToothId.tryParse(n), isNull, reason: '$n');
    }
  });

  test('listes complètes, sans doublon, dans l\'ordre du schéma', () {
    expect(ToothId.primaryAll, hasLength(20));
    expect(ToothId.primaryAll.toSet(), hasLength(20));
    expect(ToothId.permanentAll, hasLength(32));
    expect(ToothId.permanentAll.toSet(), hasLength(32));
    expect(
      ToothId.primaryAll.every((id) => id.dentition == Dentition.primary),
      isTrue,
    );
    expect(
      ToothId.permanentAll.every((id) => id.dentition == Dentition.permanent),
      isTrue,
    );
    List<int> numbers(Iterable<ToothId> ids) => [for (final id in ids) id.value];
    expect(numbers(ToothId.primaryAll.take(5)), [55, 54, 53, 52, 51]);
    expect(numbers(ToothId.primaryAll.skip(5).take(5)), [61, 62, 63, 64, 65]);
    expect(numbers(ToothId.primaryAll.skip(10).take(5)), [85, 84, 83, 82, 81]);
    expect(numbers(ToothId.primaryAll.skip(15)), [71, 72, 73, 74, 75]);
    expect(ToothId.permanentAll.first.value, 18);
    expect(ToothId.permanentAll.last.value, 38);
    expect(ToothId.all(Dentition.primary), ToothId.primaryAll);
    expect(ToothId.all(Dentition.permanent), ToothId.permanentAll);
  });
}
```

- [ ] **Step 3 : lancer le test, il échoue**

Run: `flutter test test/features/teeth/domain/tooth_id_test.dart`
Expected: FAIL, `tooth_id.dart` introuvable.

- [ ] **Step 4 : implémenter**

`lib/features/teeth/domain/entities/tooth_id.dart` :

```dart
/// Dentition : dents de lait ou dents définitives.
enum Dentition { primary, permanent }

/// Arcade dentaire.
enum ToothArch { upper, lower }

/// Côté de l'enfant (et non de l'écran).
enum ToothSide { right, left }

/// Type de dent, du milieu vers le fond ; l'index suit la position des dents définitives.
enum ToothKind {
  centralIncisor,
  lateralIncisor,
  canine,
  firstPremolar,
  secondPremolar,
  firstMolar,
  secondMolar,
  thirdMolar,
}

/// Numéro international (FDI) d'une dent : quadrant puis position depuis le milieu.
///
/// Quadrants 1 à 4 (définitives) et 5 à 8 (lait) : haut droite, haut gauche,
/// bas gauche, bas droite, du point de vue de l'enfant.
extension type const ToothId._(int value) {
  /// `null` si [value] ne désigne aucune dent de lait ou définitive.
  static ToothId? tryParse(int value) {
    final quadrant = value ~/ 10;
    final position = value % 10;
    final count = switch (quadrant) {
      1 || 2 || 3 || 4 => _permanentPerQuadrant,
      5 || 6 || 7 || 8 => _primaryPerQuadrant,
      _ => 0,
    };
    return position >= 1 && position <= count ? ToothId._(value) : null;
  }

  static const _primaryPerQuadrant = 5;
  static const _permanentPerQuadrant = 8;

  /// Pas de prémolaire dans la denture de lait : les molaires suivent la canine.
  static const _primaryKinds = [
    ToothKind.centralIncisor,
    ToothKind.lateralIncisor,
    ToothKind.canine,
    ToothKind.firstMolar,
    ToothKind.secondMolar,
  ];

  /// Les 20 dents de lait dans l'ordre du schéma.
  static final List<ToothId> primaryAll = _chartOrder(
    firstQuadrant: 5,
    perQuadrant: _primaryPerQuadrant,
  );

  /// Les 32 dents définitives dans l'ordre du schéma.
  static final List<ToothId> permanentAll = _chartOrder(
    firstQuadrant: 1,
    perQuadrant: _permanentPerQuadrant,
  );

  /// Dents de [dentition] dans l'ordre du schéma.
  static List<ToothId> all(Dentition dentition) => switch (dentition) {
    Dentition.primary => primaryAll,
    Dentition.permanent => permanentAll,
  };

  /// Vu de face, de gauche à droite de l'écran : arcade du haut puis du bas.
  /// La droite de l'enfant est à gauche de l'écran.
  static List<ToothId> _chartOrder({
    required int firstQuadrant,
    required int perQuadrant,
  }) {
    final upperRight = firstQuadrant;
    final upperLeft = firstQuadrant + 1;
    final lowerLeft = firstQuadrant + 2;
    final lowerRight = firstQuadrant + 3;
    return [
      for (var p = perQuadrant; p >= 1; p--) ToothId._(upperRight * 10 + p),
      for (var p = 1; p <= perQuadrant; p++) ToothId._(upperLeft * 10 + p),
      for (var p = perQuadrant; p >= 1; p--) ToothId._(lowerRight * 10 + p),
      for (var p = 1; p <= perQuadrant; p++) ToothId._(lowerLeft * 10 + p),
    ];
  }

  int get _quadrant => value ~/ 10;

  /// Position depuis le milieu : 1 (incisive centrale) à 5 ou 8.
  int get position => value % 10;

  Dentition get dentition =>
      _quadrant >= 5 ? Dentition.primary : Dentition.permanent;

  ToothArch get arch => switch (_quadrant) {
    1 || 2 || 5 || 6 => ToothArch.upper,
    _ => ToothArch.lower,
  };

  ToothSide get side => switch (_quadrant) {
    1 || 4 || 5 || 8 => ToothSide.right,
    _ => ToothSide.left,
  };

  ToothKind get kind => switch (dentition) {
    Dentition.primary => _primaryKinds[position - 1],
    Dentition.permanent => ToothKind.values[position - 1],
  };
}
```

- [ ] **Step 5 : lancer le test, il passe**

Run: `flutter test test/features/teeth/domain/tooth_id_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 6 : commit**

```bash
git add lib/features/teeth/domain/entities/tooth_id.dart test/features/teeth/teeth_factories.dart test/features/teeth/domain/tooth_id_test.dart
git commit -m "feat: numérotation FDI des dents" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2 : table des repères ADA

**Files:**
- Create: `lib/features/teeth/domain/reference/tooth_schedule.dart`
- Test: `test/features/teeth/domain/tooth_schedule_test.dart`

- [ ] **Step 1 : écrire le test qui échoue**

`test/features/teeth/domain/tooth_schedule_test.dart` :

```dart
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/reference/tooth_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

import '../teeth_factories.dart';

void main() {
  test('chaque dent a ses repères ; chute pour les dents de lait seulement', () {
    for (final id in ToothId.primaryAll) {
      expect(toothReferenceOf(id).shedding, isNotNull, reason: '${id.value}');
    }
    for (final id in ToothId.permanentAll) {
      expect(toothReferenceOf(id).shedding, isNull, reason: '${id.value}');
    }
  });

  test('valeurs du tableau ADA', () {
    expect(
      toothReferenceOf(tooth(71)).eruption,
      (from: 6, to: 10, unit: AgeUnit.months),
    );
    expect(
      toothReferenceOf(tooth(51)).eruption,
      (from: 8, to: 12, unit: AgeUnit.months),
    );
    expect(
      toothReferenceOf(tooth(51)).shedding,
      (from: 6, to: 7, unit: AgeUnit.years),
    );
    expect(
      toothReferenceOf(tooth(83)).shedding,
      (from: 9, to: 12, unit: AgeUnit.years),
    );
    expect(
      toothReferenceOf(tooth(65)).eruption,
      (from: 25, to: 33, unit: AgeUnit.months),
    );
    expect(
      toothReferenceOf(tooth(43)).eruption,
      (from: 9, to: 10, unit: AgeUnit.years),
    );
    expect(
      toothReferenceOf(tooth(17)).eruption,
      (from: 12, to: 13, unit: AgeUnit.years),
    );
    expect(
      toothReferenceOf(tooth(38)).eruption,
      (from: 17, to: 21, unit: AgeUnit.years),
    );
  });

  test('droite et gauche ont les mêmes repères', () {
    expect(toothReferenceOf(tooth(54)), toothReferenceOf(tooth(64)));
    expect(toothReferenceOf(tooth(36)), toothReferenceOf(tooth(46)));
  });

  test('fromMonths convertit les années', () {
    expect((from: 6, to: 10, unit: AgeUnit.months).fromMonths, 6);
    expect((from: 6, to: 7, unit: AgeUnit.years).fromMonths, 72);
  });
}
```

- [ ] **Step 2 : lancer le test, il échoue**

Run: `flutter test test/features/teeth/domain/tooth_schedule_test.dart`
Expected: FAIL, `tooth_schedule.dart` introuvable.

- [ ] **Step 3 : implémenter**

`lib/features/teeth/domain/reference/tooth_schedule.dart` :

```dart
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';

/// Unité d'une fourchette d'âge, gardée telle que dans la source.
enum AgeUnit { months, years }

/// Fourchette d'âge `[from, to]` dans l'unité de la source.
typedef AgeRange = ({int from, int to, AgeUnit unit});

/// Repères d'une dent : sortie, et chute pour une dent de lait.
typedef ToothReference = ({AgeRange eruption, AgeRange? shedding});

/// Comparaison des fourchettes quelle que soit leur unité.
extension AgeRangeX on AgeRange {
  /// Début de la fourchette en mois.
  int get fromMonths => switch (unit) {
    AgeUnit.months => from,
    AgeUnit.years => from * 12,
  };
}

/// Repères de [id].
///
/// Source : American Dental Association, *Primary Tooth Development* et
/// *Permanent Tooth Development* (2012), MouthHealthy, lus le 2026-10-14.
ToothReference toothReferenceOf(ToothId id) =>
    _schedule[(id.dentition, id.arch, id.kind)]!;

AgeRange _months(int from, int to) =>
    (from: from, to: to, unit: AgeUnit.months);

AgeRange _years(int from, int to) => (from: from, to: to, unit: AgeUnit.years);

final Map<(Dentition, ToothArch, ToothKind), ToothReference> _schedule = {
  // Dents de lait, haut.
  (Dentition.primary, ToothArch.upper, ToothKind.centralIncisor): (
    eruption: _months(8, 12),
    shedding: _years(6, 7),
  ),
  (Dentition.primary, ToothArch.upper, ToothKind.lateralIncisor): (
    eruption: _months(9, 13),
    shedding: _years(7, 8),
  ),
  (Dentition.primary, ToothArch.upper, ToothKind.canine): (
    eruption: _months(16, 22),
    shedding: _years(10, 12),
  ),
  (Dentition.primary, ToothArch.upper, ToothKind.firstMolar): (
    eruption: _months(13, 19),
    shedding: _years(9, 11),
  ),
  (Dentition.primary, ToothArch.upper, ToothKind.secondMolar): (
    eruption: _months(25, 33),
    shedding: _years(10, 12),
  ),
  // Dents de lait, bas.
  (Dentition.primary, ToothArch.lower, ToothKind.centralIncisor): (
    eruption: _months(6, 10),
    shedding: _years(6, 7),
  ),
  (Dentition.primary, ToothArch.lower, ToothKind.lateralIncisor): (
    eruption: _months(10, 16),
    shedding: _years(7, 8),
  ),
  (Dentition.primary, ToothArch.lower, ToothKind.canine): (
    eruption: _months(17, 23),
    shedding: _years(9, 12),
  ),
  (Dentition.primary, ToothArch.lower, ToothKind.firstMolar): (
    eruption: _months(14, 18),
    shedding: _years(9, 11),
  ),
  (Dentition.primary, ToothArch.lower, ToothKind.secondMolar): (
    eruption: _months(23, 31),
    shedding: _years(10, 12),
  ),
  // Dents définitives, haut.
  (Dentition.permanent, ToothArch.upper, ToothKind.centralIncisor): (
    eruption: _years(7, 8),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.upper, ToothKind.lateralIncisor): (
    eruption: _years(8, 9),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.upper, ToothKind.canine): (
    eruption: _years(11, 12),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.upper, ToothKind.firstPremolar): (
    eruption: _years(10, 11),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.upper, ToothKind.secondPremolar): (
    eruption: _years(10, 12),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.upper, ToothKind.firstMolar): (
    eruption: _years(6, 7),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.upper, ToothKind.secondMolar): (
    eruption: _years(12, 13),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.upper, ToothKind.thirdMolar): (
    eruption: _years(17, 21),
    shedding: null,
  ),
  // Dents définitives, bas.
  (Dentition.permanent, ToothArch.lower, ToothKind.centralIncisor): (
    eruption: _years(6, 7),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.lower, ToothKind.lateralIncisor): (
    eruption: _years(7, 8),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.lower, ToothKind.canine): (
    eruption: _years(9, 10),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.lower, ToothKind.firstPremolar): (
    eruption: _years(10, 12),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.lower, ToothKind.secondPremolar): (
    eruption: _years(11, 12),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.lower, ToothKind.firstMolar): (
    eruption: _years(6, 7),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.lower, ToothKind.secondMolar): (
    eruption: _years(11, 13),
    shedding: null,
  ),
  (Dentition.permanent, ToothArch.lower, ToothKind.thirdMolar): (
    eruption: _years(17, 21),
    shedding: null,
  ),
};
```

- [ ] **Step 4 : lancer le test, il passe**

Run: `flutter test test/features/teeth/domain/tooth_schedule_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5 : commit**

```bash
git add lib/features/teeth/domain/reference/tooth_schedule.dart test/features/teeth/domain/tooth_schedule_test.dart
git commit -m "feat: repères ADA de pousse et de chute des dents" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3 : `ToothRecord` et statut d'une dent

**Files:**
- Create: `lib/features/teeth/domain/entities/tooth_record.dart`
- Create: `lib/features/teeth/domain/entities/tooth_status.dart`
- Create: `lib/features/teeth/domain/use_cases/compute_tooth_status.dart`
- Modify: `test/features/teeth/teeth_factories.dart`
- Test: `test/features/teeth/domain/compute_tooth_status_test.dart`

- [ ] **Step 1 : compléter la fabrique de test**

Remplacer le contenu de `test/features/teeth/teeth_factories.dart` par :

```dart
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';

/// Dent de test à partir de son numéro FDI ; échoue si le numéro est inconnu.
ToothId tooth(int number) => ToothId.tryParse(number)!;

/// Dent notée de test, horodatée au 14 octobre 2026 par `device-a`.
ToothRecord makeTooth(
  int number, {
  DateTime? eruptedAt,
  DateTime? lostAt,
  String? note,
}) => ToothRecord(
  toothId: tooth(number),
  eruptedAt: eruptedAt,
  lostAt: lostAt,
  note: note,
  updatedAt: DateTime(2026, 10, 14),
  updatedByDeviceId: 'device-a',
);
```

- [ ] **Step 2 : écrire le test qui échoue**

`test/features/teeth/domain/compute_tooth_status_test.dart` :

```dart
import 'package:colette/features/teeth/domain/entities/tooth_status.dart';
import 'package:colette/features/teeth/domain/use_cases/compute_tooth_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../teeth_factories.dart';

void main() {
  const status = ComputeToothStatus();
  final erupted = DateTime(2027, 3, 1, 12);
  final lost = DateTime(2033, 5, 2, 12);

  test('absente sans enregistrement ou avec une note seule', () {
    expect(status(null), ToothStatus.absent);
    expect(status(makeTooth(51, note: 'gencive gonflée')), ToothStatus.absent);
  });

  test('sortie', () {
    expect(status(makeTooth(51, eruptedAt: erupted)), ToothStatus.erupted);
  });

  test('tombée, même sans date de sortie', () {
    expect(
      status(makeTooth(51, eruptedAt: erupted, lostAt: lost)),
      ToothStatus.lost,
    );
    expect(status(makeTooth(51, lostAt: lost)), ToothStatus.lost);
  });

  test('isEmpty : ni date ni note', () {
    expect(makeTooth(51).isEmpty, isTrue);
    expect(makeTooth(51, note: '   ').isEmpty, isTrue);
    expect(makeTooth(51, note: 'x').isEmpty, isFalse);
    expect(makeTooth(51, eruptedAt: erupted).isEmpty, isFalse);
    expect(makeTooth(51, lostAt: lost).isEmpty, isFalse);
  });
}
```

- [ ] **Step 3 : lancer le test, il échoue**

Run: `flutter test test/features/teeth/domain/compute_tooth_status_test.dart`
Expected: FAIL, `tooth_record.dart` introuvable.

- [ ] **Step 4 : implémenter**

`lib/features/teeth/domain/entities/tooth_record.dart` :

```dart
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tooth_record.freezed.dart';

/// Ce que les parents ont noté pour une dent : sortie, chute, note.
@freezed
abstract class ToothRecord with _$ToothRecord {
  const ToothRecord._();

  const factory ToothRecord({
    required ToothId toothId,
    DateTime? eruptedAt,
    DateTime? lostAt,
    String? note,
    required DateTime updatedAt,
    required String updatedByDeviceId,
  }) = _ToothRecord;

  /// Rien de noté : ni date, ni note.
  bool get isEmpty =>
      eruptedAt == null && lostAt == null && (note?.trim().isEmpty ?? true);
}
```

`lib/features/teeth/domain/entities/tooth_status.dart` :

```dart
/// État d'une dent sur le schéma.
enum ToothStatus { absent, erupted, lost }
```

`lib/features/teeth/domain/use_cases/compute_tooth_status.dart` :

```dart
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/domain/entities/tooth_status.dart';

/// État d'une dent d'après ce qui a été noté ; `null` = rien de noté.
class ComputeToothStatus {
  const ComputeToothStatus();

  /// Une chute sans date de sortie compte : la dent a pu sortir avant l'app.
  ToothStatus call(ToothRecord? record) => switch (record) {
    ToothRecord(lostAt: _?) => ToothStatus.lost,
    ToothRecord(eruptedAt: _?) => ToothStatus.erupted,
    _ => ToothStatus.absent,
  };
}
```

Run: `dart run build_runner build -d`
Expected: `tooth_record.freezed.dart` généré, sans erreur.

- [ ] **Step 5 : lancer le test, il passe**

Run: `flutter test test/features/teeth/domain/compute_tooth_status_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 6 : commit**

```bash
git add lib/features/teeth/domain/entities/tooth_record.dart lib/features/teeth/domain/entities/tooth_record.freezed.dart lib/features/teeth/domain/entities/tooth_status.dart lib/features/teeth/domain/use_cases/compute_tooth_status.dart test/features/teeth/teeth_factories.dart test/features/teeth/domain/compute_tooth_status_test.dart
git commit -m "feat: dent notée et statut d'une dent" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

(Si `*.freezed.dart` est ignoré par `.gitignore`, retirer ce chemin du `git add` : vérifier avec `git check-ignore lib/features/teeth/domain/entities/tooth_record.freezed.dart`.)

---

### Task 4 : validation d'une dent et messages d'erreur

**Files:**
- Modify: `lib/core/result/failure.dart` (enum `ValidationReason`)
- Modify: `lib/core/ui/failure_message.dart`
- Modify: `lib/l10n/app_fr.arb`
- Create: `lib/features/teeth/domain/use_cases/validate_tooth_record.dart`
- Test: `test/features/teeth/domain/validate_tooth_record_test.dart` (et `test/core/ui/failure_message_test.dart`, existant, qui vérifie un message distinct par raison)

- [ ] **Step 1 : écrire le test qui échoue**

`test/features/teeth/domain/validate_tooth_record_test.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/domain/use_cases/validate_tooth_record.dart';
import 'package:flutter_test/flutter_test.dart';

import '../teeth_factories.dart';

void main() {
  const validate = ValidateToothRecord();
  final birth = DateTime(2026, 9, 1, 8);
  final now = DateTime(2027, 3, 10, 9);

  ValidationReason? reasonOf(ToothRecord record) => validate(
    record,
    birthDate: birth,
    now: now,
  ).fold((failure) => failure.reason, (_) => null);

  ToothRecord valid(ToothRecord record) => validate(
    record,
    birthDate: birth,
    now: now,
  ).fold((failure) => fail('invalide : ${failure.reason}'), (r) => r);

  test('accepte une sortie puis une chute le même jour', () {
    final day = DateTime(2027, 1, 10, 12);
    expect(reasonOf(makeTooth(71, eruptedAt: day, lostAt: day)), isNull);
  });

  test('accepte la date du jour enregistrée à midi, le matin', () {
    expect(reasonOf(makeTooth(71, eruptedAt: DateTime(2027, 3, 10, 12))), isNull);
  });

  test('accepte le jour de la naissance', () {
    expect(reasonOf(makeTooth(71, eruptedAt: DateTime(2026, 9, 1, 0))), isNull);
  });

  test('refuse une date avant la naissance', () {
    expect(
      reasonOf(makeTooth(71, eruptedAt: DateTime(2026, 8, 31, 12))),
      ValidationReason.toothDateBeforeBirth,
    );
    expect(
      reasonOf(makeTooth(71, lostAt: DateTime(2026, 8, 31, 12))),
      ValidationReason.toothDateBeforeBirth,
    );
  });

  test('refuse une date après aujourd\'hui', () {
    expect(
      reasonOf(makeTooth(71, eruptedAt: DateTime(2027, 3, 11, 12))),
      ValidationReason.toothDateInFuture,
    );
    expect(
      reasonOf(makeTooth(71, lostAt: DateTime(2027, 3, 11, 12))),
      ValidationReason.toothDateInFuture,
    );
  });

  test('refuse une chute avant la sortie', () {
    expect(
      reasonOf(
        makeTooth(
          71,
          eruptedAt: DateTime(2027, 1, 10, 12),
          lostAt: DateTime(2027, 1, 9, 12),
        ),
      ),
      ValidationReason.toothLostBeforeErupted,
    );
  });

  test('refuse une chute sur une dent définitive', () {
    expect(
      reasonOf(makeTooth(11, lostAt: DateTime(2027, 1, 10, 12))),
      ValidationReason.toothLossOnPermanent,
    );
  });

  test('rogne la note ; une note vide devient null', () {
    expect(valid(makeTooth(71, note: '  nuit agitée ')).note, 'nuit agitée');
    expect(valid(makeTooth(71, note: '   ')).note, isNull);
  });
}
```

- [ ] **Step 2 : lancer le test, il échoue**

Run: `flutter test test/features/teeth/domain/validate_tooth_record_test.dart`
Expected: FAIL, `validate_tooth_record.dart` introuvable.

- [ ] **Step 3 : ajouter les raisons de validation**

Dans `lib/core/result/failure.dart`, enum `ValidationReason`, après `invalidDocumentName,` :

```dart
  invalidDocumentName,
  toothDateBeforeBirth,
  toothDateInFuture,
  toothLostBeforeErupted,
  toothLossOnPermanent,
}
```

- [ ] **Step 4 : ajouter les messages**

Dans `lib/l10n/app_fr.arb`, à la fin du fichier : ajouter une virgule après la dernière entrée (`"photoReminderBodyNoName": "…"`) puis, avant l'accolade fermante :

```json
  "errorToothDateBeforeBirth": "Une dent ne peut pas sortir ni tomber avant la naissance.",
  "errorToothDateInFuture": "Une date de sortie ou de chute ne peut pas être dans le futur.",
  "errorToothLostBeforeErupted": "La chute ne peut pas précéder la sortie.",
  "errorToothLossOnPermanent": "Une dent définitive ne tombe pas."
```

Dans `lib/core/ui/failure_message.dart`, dans le `switch (reason)`, après `ValidationReason.invalidDocumentName => s.errorInvalidDocumentName,` :

```dart
    ValidationReason.toothDateBeforeBirth => s.errorToothDateBeforeBirth,
    ValidationReason.toothDateInFuture => s.errorToothDateInFuture,
    ValidationReason.toothLostBeforeErupted => s.errorToothLostBeforeErupted,
    ValidationReason.toothLossOnPermanent => s.errorToothLossOnPermanent,
```

Run: `flutter gen-l10n`
Expected: génération sans erreur.

- [ ] **Step 5 : implémenter la validation**

`lib/features/teeth/domain/use_cases/validate_tooth_record.dart` :

```dart
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:fpdart/fpdart.dart';

/// Règles de validité d'une dent notée ; renvoie la dent avec sa note rognée.
///
/// Les dates sont comparées en jours civils : une date choisie au sélecteur est
/// enregistrée à midi, une tolérance en minutes refuserait la date du jour le matin.
class ValidateToothRecord {
  const ValidateToothRecord();

  Either<ValidationFailure, ToothRecord> call(
    ToothRecord record, {
    required DateTime birthDate,
    required DateTime now,
  }) {
    final erupted = record.eruptedAt;
    final lost = record.lostAt;
    if (lost != null && record.toothId.dentition == Dentition.permanent) {
      return left(
        const ValidationFailure(ValidationReason.toothLossOnPermanent),
      );
    }
    final days = [erupted, lost].nonNulls.map((date) => date.dateOnly);
    if (days.any((day) => day.isBefore(birthDate.dateOnly))) {
      return left(
        const ValidationFailure(ValidationReason.toothDateBeforeBirth),
      );
    }
    if (days.any((day) => day.isAfter(now.dateOnly))) {
      return left(const ValidationFailure(ValidationReason.toothDateInFuture));
    }
    if (erupted != null &&
        lost != null &&
        lost.dateOnly.isBefore(erupted.dateOnly)) {
      return left(
        const ValidationFailure(ValidationReason.toothLostBeforeErupted),
      );
    }
    final note = record.note?.trim();
    return right(
      record.copyWith(note: note == null || note.isEmpty ? null : note),
    );
  }
}
```

- [ ] **Step 6 : lancer les tests, ils passent**

Run: `flutter test test/features/teeth/domain/validate_tooth_record_test.dart test/core/ui/failure_message_test.dart`
Expected: PASS (tous). `failure_message_test` confirme un message distinct et non vide pour chaque nouvelle raison.

- [ ] **Step 7 : commit**

```bash
git add lib/core/result/failure.dart lib/core/ui/failure_message.dart lib/l10n/app_fr.arb lib/features/teeth/domain/use_cases/validate_tooth_record.dart test/features/teeth/domain/validate_tooth_record_test.dart
git commit -m "feat: validation des dates de sortie et de chute" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5 : résumé (dents en bouche, prochaines attendues)

**Files:**
- Create: `lib/features/teeth/domain/entities/teeth_summary.dart`
- Create: `lib/features/teeth/domain/use_cases/compute_teeth_summary.dart`
- Test: `test/features/teeth/domain/compute_teeth_summary_test.dart`

- [ ] **Step 1 : écrire le test qui échoue**

`test/features/teeth/domain/compute_teeth_summary_test.dart` :

```dart
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/domain/reference/tooth_schedule.dart';
import 'package:colette/features/teeth/domain/use_cases/compute_teeth_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../teeth_factories.dart';

void main() {
  const compute = ComputeTeethSummary();
  final day = DateTime(2027, 3, 1, 12);

  Map<ToothId, ToothRecord> noted(Iterable<ToothRecord> records) => {
    for (final record in records) record.toothId: record,
  };

  List<(Dentition, ToothArch, ToothKind)> groups(Map<ToothId, ToothRecord> r) =>
      [for (final g in compute(r).next) (g.dentition, g.arch, g.kind)];

  test('à la naissance : incisives centrales du bas puis du haut', () {
    final summary = compute(const {});
    expect(summary.inMouth, 0);
    expect(summary.next, [
      (
        dentition: Dentition.primary,
        arch: ToothArch.lower,
        kind: ToothKind.centralIncisor,
        eruption: (from: 6, to: 10, unit: AgeUnit.months),
      ),
      (
        dentition: Dentition.primary,
        arch: ToothArch.upper,
        kind: ToothKind.centralIncisor,
        eruption: (from: 8, to: 12, unit: AgeUnit.months),
      ),
    ]);
  });

  test('un groupe reste attendu tant qu\'une de ses deux dents manque', () {
    final records = noted([makeTooth(71, eruptedAt: day)]);
    expect(compute(records).inMouth, 1);
    expect(groups(records).first, (
      Dentition.primary,
      ToothArch.lower,
      ToothKind.centralIncisor,
    ));
  });

  test('les deux incisives centrales du bas sorties : groupes suivants', () {
    final records = noted([
      makeTooth(71, eruptedAt: day),
      makeTooth(81, eruptedAt: day),
    ]);
    expect(groups(records), [
      (Dentition.primary, ToothArch.upper, ToothKind.centralIncisor),
      (Dentition.primary, ToothArch.upper, ToothKind.lateralIncisor),
    ]);
  });

  test('une dent tombée ne compte pas en bouche', () {
    final records = noted([
      makeTooth(71, eruptedAt: day, lostAt: DateTime(2033, 5, 2, 12)),
      makeTooth(81, eruptedAt: day),
    ]);
    expect(compute(records).inMouth, 1);
  });

  test('passe aux définitives quand les 20 dents de lait sont notées', () {
    final records = noted([
      for (final id in ToothId.primaryAll) makeTooth(id.value, eruptedAt: day),
    ]);
    expect(compute(records).inMouth, 20);
    // À 6-7 ans ex æquo : le bas avant le haut, puis du milieu vers le fond.
    expect(groups(records), [
      (Dentition.permanent, ToothArch.lower, ToothKind.centralIncisor),
      (Dentition.permanent, ToothArch.lower, ToothKind.firstMolar),
    ]);
  });

  test('plus de groupe quand toutes les dents sont notées', () {
    final records = noted([
      for (final id in [...ToothId.primaryAll, ...ToothId.permanentAll])
        makeTooth(id.value, eruptedAt: day),
    ]);
    expect(compute(records).next, isEmpty);
  });
}
```

- [ ] **Step 2 : lancer le test, il échoue**

Run: `flutter test test/features/teeth/domain/compute_teeth_summary_test.dart`
Expected: FAIL, `compute_teeth_summary.dart` introuvable.

- [ ] **Step 3 : implémenter**

`lib/features/teeth/domain/entities/teeth_summary.dart` :

```dart
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/reference/tooth_schedule.dart';

/// Groupe de dents attendu : un type de dent sur une arcade, droite et gauche confondues.
typedef ExpectedTeethGroup = ({
  Dentition dentition,
  ToothArch arch,
  ToothKind kind,
  AgeRange eruption,
});

/// Résumé des dents pour la carte de l'onglet Santé.
final class TeethSummary {
  const TeethSummary({required this.inMouth, required this.next});

  /// Dents sorties et pas tombées, toutes dentitions confondues.
  final int inMouth;

  /// Au plus deux groupes, dans l'ordre habituel de sortie.
  final List<ExpectedTeethGroup> next;
}
```

`lib/features/teeth/domain/use_cases/compute_teeth_summary.dart` :

```dart
import 'package:colette/features/teeth/domain/entities/teeth_summary.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/domain/entities/tooth_status.dart';
import 'package:colette/features/teeth/domain/reference/tooth_schedule.dart';
import 'package:colette/features/teeth/domain/use_cases/compute_tooth_status.dart';

/// Dents en bouche et prochains groupes attendus, sans lien avec l'âge de l'enfant.
class ComputeTeethSummary {
  const ComputeTeethSummary();

  static const maxGroups = 2;

  TeethSummary call(Map<ToothId, ToothRecord> records) {
    const status = ComputeToothStatus();
    bool isAbsent(ToothId id) => status(records[id]) == ToothStatus.absent;
    final inMouth = records.values
        .where((record) => status(record) == ToothStatus.erupted)
        .length;
    final primaryMissing = ToothId.primaryAll.where(isAbsent).toList();
    final candidates = primaryMissing.isNotEmpty
        ? primaryMissing
        : ToothId.permanentAll.where(isAbsent).toList();
    final groups = <ExpectedTeethGroup>{
      for (final id in candidates)
        (
          dentition: id.dentition,
          arch: id.arch,
          kind: id.kind,
          eruption: toothReferenceOf(id).eruption,
        ),
    }.toList()..sort(_byUsualOrder);
    return TeethSummary(
      inMouth: inMouth,
      next: groups.take(maxGroups).toList(),
    );
  }

  /// Début de fourchette, puis le bas avant le haut, puis du milieu vers le fond.
  static int _byUsualOrder(ExpectedTeethGroup a, ExpectedTeethGroup b) {
    final byAge = a.eruption.fromMonths.compareTo(b.eruption.fromMonths);
    if (byAge != 0) return byAge;
    final byArch = _archRank(a.arch).compareTo(_archRank(b.arch));
    if (byArch != 0) return byArch;
    return a.kind.index.compareTo(b.kind.index);
  }

  static int _archRank(ToothArch arch) => switch (arch) {
    ToothArch.lower => 0,
    ToothArch.upper => 1,
  };
}
```

- [ ] **Step 4 : lancer le test, il passe**

Run: `flutter test test/features/teeth/domain/compute_teeth_summary_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5 : commit**

```bash
git add lib/features/teeth/domain/entities/teeth_summary.dart lib/features/teeth/domain/use_cases/compute_teeth_summary.dart test/features/teeth/domain/compute_teeth_summary_test.dart
git commit -m "feat: dents en bouche et prochaines dents attendues" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6 : dépôt Firestore

**Files:**
- Modify: `lib/core/firebase/firestore_paths.dart`
- Modify: `firestore.rules` (commentaire seulement)
- Create: `lib/features/teeth/domain/repositories/teeth_repository.dart`
- Create: `lib/features/teeth/data/dtos/tooth_record_dto.dart`
- Create: `lib/features/teeth/data/repositories/firestore_teeth_repository.dart`
- Test: `test/features/teeth/data/firestore_teeth_repository_test.dart`

- [ ] **Step 1 : écrire le test qui échoue**

`test/features/teeth/data/firestore_teeth_repository_test.dart` :

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/teeth/data/repositories/firestore_teeth_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../teeth_factories.dart';

void main() {
  const code = 'ABCDEFGH';
  late FakeFirebaseFirestore db;
  late FirestoreTeethRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreTeethRepository(db);
  });

  CollectionReference<Map<String, dynamic>> teeth() =>
      db.collection('households').doc(code).collection('teeth');

  test('aller-retour d\'une dent complète', () async {
    final record = makeTooth(
      51,
      eruptedAt: DateTime(2027, 1, 10, 12),
      lostAt: DateTime(2033, 5, 2, 12),
      note: 'Nuit agitée',
    );
    expect((await repo.saveTooth(code, record)).isRight(), isTrue);
    expect(await repo.watchTeeth(code).first, [record]);
    expect((await teeth().doc('51').get()).exists, isTrue);
  });

  test('dent partielle : clés absentes plutôt que nulles', () async {
    await repo.saveTooth(
      code,
      makeTooth(71, eruptedAt: DateTime(2027, 1, 10, 12)),
    );
    final data = (await teeth().doc('71').get()).data()!;
    expect(data.keys.toSet(), {'eruptedAt', 'updatedAt', 'updatedByDeviceId'});
  });

  test('ignore un numéro inconnu et un document illisible', () async {
    await teeth().doc('99').set({
      'updatedAt': Timestamp.fromDate(DateTime(2026, 10, 14)),
    });
    await teeth().doc('52').set({'note': 'sans date de mise à jour'});
    await repo.saveTooth(
      code,
      makeTooth(61, eruptedAt: DateTime(2027, 2, 1, 12)),
    );
    final records = await repo.watchTeeth(code).first;
    expect([for (final r in records) r.toothId], [tooth(61)]);
  });

  test('supprime une dent', () async {
    await repo.saveTooth(code, makeTooth(51, note: 'x'));
    expect((await repo.deleteTooth(code, tooth(51))).isRight(), isTrue);
    expect(await repo.watchTeeth(code).first, isEmpty);
    expect((await teeth().doc('51').get()).exists, isFalse);
  });
}
```

- [ ] **Step 2 : lancer le test, il échoue**

Run: `flutter test test/features/teeth/data/firestore_teeth_repository_test.dart`
Expected: FAIL, `firestore_teeth_repository.dart` introuvable.

- [ ] **Step 3 : implémenter**

Dans `lib/core/firebase/firestore_paths.dart`, après `medicalAppointments` :

```dart
  /// RDV libres hors calendrier (identifiant = UUID).
  static const medicalAppointments = 'medicalAppointments';

  /// Dents notées, une par dent (identifiant = numéro FDI, ex. `"51"`).
  static const teeth = 'teeth';
}
```

Dans `firestore.rules`, compléter le commentaire de la règle générique :

```
    // Sous-collections : events, weights, devices, sleeps, tastings, customFoods,
    // medicalVisits, medicalAppointments, teeth.
```

`lib/features/teeth/domain/repositories/teeth_repository.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:fpdart/fpdart.dart';

/// Dents notées d'un foyer.
abstract interface class TeethRepository {
  /// Dents notées, dans un ordre quelconque.
  Stream<List<ToothRecord>> watchTeeth(String householdCode);

  /// Remplace entièrement ce qui est noté pour la dent.
  Future<Either<Failure, void>> saveTooth(
    String householdCode,
    ToothRecord record,
  );

  /// Supprime ce qui est noté pour la dent.
  Future<Either<Failure, void>> deleteTooth(
    String householdCode,
    ToothId toothId,
  );
}
```

`lib/features/teeth/data/dtos/tooth_record_dto.dart` :

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';

/// Conversion `ToothRecord` ↔ document `teeth/{numéro}` ; clés absentes plutôt que nulles.
abstract final class ToothRecordDto {
  /// Identifiant du document de [id].
  static String docId(ToothId id) => '${id.value}';

  static Map<String, dynamic> toMap(ToothRecord r) => {
    if (r.eruptedAt case final at?) 'eruptedAt': Timestamp.fromDate(at),
    if (r.lostAt case final at?) 'lostAt': Timestamp.fromDate(at),
    'note': ?r.note,
    'updatedAt': Timestamp.fromDate(r.updatedAt),
    'updatedByDeviceId': r.updatedByDeviceId,
  };

  /// `null` pour un numéro inconnu ou un document illisible (`updatedAt` absent).
  static ToothRecord? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final toothId = switch (int.tryParse(doc.id)) {
      final number? => ToothId.tryParse(number),
      null => null,
    };
    final data = doc.data();
    if (toothId == null || data == null) return null;
    if (data['updatedAt'] is! Timestamp) return null;
    return ToothRecord(
      toothId: toothId,
      eruptedAt: switch (data['eruptedAt']) {
        final Timestamp t => t.toDate(),
        _ => null,
      },
      lostAt: switch (data['lostAt']) {
        final Timestamp t => t.toDate(),
        _ => null,
      },
      note: switch (data['note']) {
        final String n => n,
        _ => null,
      },
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      updatedByDeviceId: data['updatedByDeviceId'] as String? ?? '',
    );
  }
}
```

`lib/features/teeth/data/repositories/firestore_teeth_repository.dart` :

```dart
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/firebase/firestore_paths.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/teeth/data/dtos/tooth_record_dto.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/domain/repositories/teeth_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Dents dans `households/{code}/teeth/{numéro}`.
class FirestoreTeethRepository implements TeethRepository {
  FirestoreTeethRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _teeth(String code) => _db
      .collection(FirestorePaths.households)
      .doc(code)
      .collection(FirestorePaths.teeth);

  static List<ToothRecord> _decode(QuerySnapshot<Map<String, dynamic>> snap) {
    final records = <ToothRecord>[];
    for (final doc in snap.docs) {
      final record = ToothRecordDto.fromDoc(doc);
      if (record == null) {
        log('Dent illisible ignorée : ${doc.id}', name: 'colette');
        continue;
      }
      records.add(record);
    }
    return records;
  }

  @override
  Stream<List<ToothRecord>> watchTeeth(String householdCode) =>
      _teeth(householdCode).snapshots().map(_decode);

  @override
  Future<Either<Failure, void>> saveTooth(
    String householdCode,
    ToothRecord record,
  ) => guard(
    () => _teeth(householdCode)
        .doc(ToothRecordDto.docId(record.toothId))
        .set(ToothRecordDto.toMap(record)),
  );

  @override
  Future<Either<Failure, void>> deleteTooth(
    String householdCode,
    ToothId toothId,
  ) => guard(
    () => _teeth(householdCode).doc(ToothRecordDto.docId(toothId)).delete(),
  );
}
```

- [ ] **Step 4 : lancer le test, il passe**

Run: `flutter test test/features/teeth/data/firestore_teeth_repository_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5 : commit**

```bash
git add lib/core/firebase/firestore_paths.dart firestore.rules lib/features/teeth/domain/repositories/teeth_repository.dart lib/features/teeth/data/dtos/tooth_record_dto.dart lib/features/teeth/data/repositories/firestore_teeth_repository.dart test/features/teeth/data/firestore_teeth_repository_test.dart
git commit -m "feat: stockage Firestore des dents" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7 : providers et contrôleur

**Files:**
- Create: `lib/features/teeth/presentation/providers/teeth_providers.dart`
- Create: `lib/features/teeth/presentation/providers/teeth_controller.dart`
- Modify: `test/features/teeth/teeth_factories.dart` (mock du dépôt)
- Test: `test/features/teeth/presentation/teeth_providers_test.dart`
- Test: `test/features/teeth/presentation/teeth_controller_test.dart`

- [ ] **Step 1 : ajouter le mock du dépôt à la fabrique**

En tête de `test/features/teeth/teeth_factories.dart`, ajouter les imports :

```dart
import 'package:colette/features/teeth/domain/repositories/teeth_repository.dart';
import 'package:mocktail/mocktail.dart';
```

et à la fin du fichier :

```dart
/// Dépôt simulé pour les tests de présentation.
class MockTeethRepository extends Mock implements TeethRepository {}
```

- [ ] **Step 2 : écrire les tests qui échouent**

`test/features/teeth/presentation/teeth_providers_test.dart` :

```dart
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/teeth/presentation/providers/teeth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../teeth_factories.dart';

void main() {
  test('indexe les dents par numéro et les résume', () async {
    final record = makeTooth(71, eruptedAt: DateTime(2027, 1, 10, 12));
    final repo = MockTeethRepository();
    when(
      () => repo.watchTeeth('ABCDEFGH'),
    ).thenAnswer((_) => Stream.value([record]));
    final container = ProviderContainer(
      overrides: [
        teethRepositoryProvider.overrideWithValue(repo),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(teethSummaryProvider, (_, _) {});
    addTearDown(sub.close);
    expect(await container.read(teethProvider.future), {tooth(71): record});
    expect(container.read(teethSummaryProvider)!.inMouth, 1);
  });

  test('sans foyer : aucune dent', () async {
    final container = ProviderContainer(
      overrides: [
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(),
        ),
      ],
    );
    addTearDown(container.dispose);
    expect(await container.read(teethProvider.future), isEmpty);
  });
}
```

`test/features/teeth/presentation/teeth_controller_test.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/presentation/providers/teeth_controller.dart';
import 'package:colette/features/teeth/presentation/providers/teeth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../teeth_factories.dart';

void main() {
  late MockTeethRepository repo;
  late ProviderContainer container;
  final birth = DateTime(2026, 9, 1);
  final now = DateTime(2027, 3, 10, 9);

  setUpAll(() {
    registerFallbackValue(makeTooth(51));
    registerFallbackValue(tooth(51));
  });

  setUp(() {
    repo = MockTeethRepository();
    container = ProviderContainer(
      overrides: [
        teethRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(FixedClock(now)),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(
            householdCode: 'ABCDEFGH',
            deviceId: 'device-b',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  TeethController controller() =>
      container.read(teethControllerProvider.notifier);

  test('enregistre la dent horodatée par cet iPhone, note rognée', () async {
    when(
      () => repo.saveTooth(any(), any()),
    ).thenAnswer((_) async => right(null));
    final ok = await controller().save(
      makeTooth(
        71,
        eruptedAt: DateTime(2027, 3, 10, 12),
        note: ' nuit agitée ',
      ),
      birthDate: birth,
    );
    expect(ok, isTrue);
    final saved =
        verify(
              () => repo.saveTooth('ABCDEFGH', captureAny()),
            ).captured.single
            as ToothRecord;
    expect(saved.updatedAt, now);
    expect(saved.updatedByDeviceId, 'device-b');
    expect(saved.note, 'nuit agitée');
  });

  test('une dent vidée est supprimée', () async {
    when(
      () => repo.deleteTooth(any(), any()),
    ).thenAnswer((_) async => right(null));
    expect(await controller().save(makeTooth(71), birthDate: birth), isTrue);
    verify(() => repo.deleteTooth('ABCDEFGH', tooth(71))).called(1);
    verifyNever(() => repo.saveTooth(any(), any()));
  });

  test('refuse une dent invalide sans écrire', () async {
    final sub = container.listen(teethControllerProvider, (_, _) {});
    addTearDown(sub.close);
    final ok = await controller().save(
      makeTooth(11, lostAt: DateTime(2027, 1, 10, 12)),
      birthDate: birth,
    );
    expect(ok, isFalse);
    expect(
      (container.read(teethControllerProvider).error! as ValidationFailure)
          .reason,
      ValidationReason.toothLossOnPermanent,
    );
    verifyNever(() => repo.saveTooth(any(), any()));
  });

  test('remonte l\'échec d\'écriture', () async {
    when(
      () => repo.saveTooth(any(), any()),
    ).thenAnswer((_) async => left(const NetworkFailure()));
    final sub = container.listen(teethControllerProvider, (_, _) {});
    addTearDown(sub.close);
    final ok = await controller().save(
      makeTooth(71, eruptedAt: DateTime(2027, 3, 1, 12)),
      birthDate: birth,
    );
    expect(ok, isFalse);
    expect(container.read(teethControllerProvider).error, isA<NetworkFailure>());
  });

  test('clear supprime la dent', () async {
    when(
      () => repo.deleteTooth(any(), any()),
    ).thenAnswer((_) async => right(null));
    expect(await controller().clear(tooth(71)), isTrue);
    verify(() => repo.deleteTooth('ABCDEFGH', tooth(71))).called(1);
  });
}
```

- [ ] **Step 3 : lancer les tests, ils échouent**

Run: `flutter test test/features/teeth/presentation/teeth_providers_test.dart test/features/teeth/presentation/teeth_controller_test.dart`
Expected: FAIL, `teeth_providers.dart` introuvable.

- [ ] **Step 4 : implémenter**

`lib/features/teeth/presentation/providers/teeth_providers.dart` :

```dart
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/result/no_retry.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/teeth/data/repositories/firestore_teeth_repository.dart';
import 'package:colette/features/teeth/domain/entities/teeth_summary.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/domain/repositories/teeth_repository.dart';
import 'package:colette/features/teeth/domain/use_cases/compute_teeth_summary.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'teeth_providers.g.dart';

/// Sans état : `keepAlive` comme les autres dépôts Firestore.
@Riverpod(keepAlive: true)
TeethRepository teethRepository(Ref ref) =>
    FirestoreTeethRepository(ref.watch(firestoreProvider));

/// Dents notées du foyer courant, indexées par numéro.
@Riverpod(retry: noRetry)
Stream<Map<ToothId, ToothRecord>> teeth(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(const {});
  return ref
      .watch(teethRepositoryProvider)
      .watchTeeth(code)
      .map((records) => {for (final r in records) r.toothId: r});
}

/// Résumé pour la carte Santé ; `null` tant que les dents ne sont pas lues.
@riverpod
TeethSummary? teethSummary(Ref ref) => switch (ref.watch(teethProvider)) {
  AsyncData(:final value) => const ComputeTeethSummary()(value),
  _ => null,
};
```

`lib/features/teeth/presentation/providers/teeth_controller.dart` :

```dart
import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/domain/use_cases/validate_tooth_record.dart';
import 'package:colette/features/teeth/presentation/providers/teeth_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'teeth_controller.g.dart';

/// Enregistre une dent (ou la supprime si elle est vide), ou l'efface.
@riverpod
class TeethController extends _$TeethController {
  @override
  FutureOr<void> build() {}

  Future<bool> save(ToothRecord record, {required DateTime birthDate}) async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return false;
    // Lu avant l'await : le contrôleur autoDispose peut être détruit pendant l'écriture.
    final repo = ref.read(teethRepositoryProvider);
    final now = ref.read(clockProvider).now();
    final stamped = record.copyWith(
      updatedAt: now,
      updatedByDeviceId: ref.read(deviceIdProvider),
    );
    state = const AsyncLoading();
    final result =
        await const ValidateToothRecord()(
          stamped,
          birthDate: birthDate,
          now: now,
        ).fold<Future<Either<Failure, void>>>(
          (failure) async => left(failure),
          (valid) => valid.isEmpty
              ? repo.deleteTooth(code, valid.toothId)
              : repo.saveTooth(code, valid),
        );
    _settle(result);
    return result.isRight();
  }

  Future<bool> clear(ToothId toothId) async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return false;
    final repo = ref.read(teethRepositoryProvider);
    state = const AsyncLoading();
    final result = await repo.deleteTooth(code, toothId);
    _settle(result);
    return result.isRight();
  }

  void _settle(Either<Failure, void> result) {
    if (!ref.mounted) return;
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }
}
```

Run: `dart run build_runner build -d`
Expected: `teeth_providers.g.dart` et `teeth_controller.g.dart` générés.

- [ ] **Step 5 : lancer les tests, ils passent**

Run: `flutter test test/features/teeth/presentation/teeth_providers_test.dart test/features/teeth/presentation/teeth_controller_test.dart`
Expected: PASS (7 tests).

- [ ] **Step 6 : commit**

```bash
git add lib/features/teeth/presentation/providers/ test/features/teeth/teeth_factories.dart test/features/teeth/presentation/teeth_providers_test.dart test/features/teeth/presentation/teeth_controller_test.dart
git commit -m "feat: providers et contrôleur des dents" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

(Vérifier avec `git status` que seuls les fichiers des dents sont ajoutés par le dossier `providers/`.)

---

### Task 8 : géométrie du schéma (`TeethLayout`)

**Files:**
- Create: `lib/features/teeth/presentation/widgets/teeth_layout.dart`
- Test: `test/features/teeth/presentation/teeth_layout_test.dart`

- [ ] **Step 1 : écrire le test qui échoue**

`test/features/teeth/presentation/teeth_layout_test.dart` :

```dart
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../teeth_factories.dart';

void main() {
  const sizes = [Size(300, 330), Size(390, 429)];

  for (final dentition in Dentition.values) {
    for (final size in sizes) {
      test('$dentition $size : dents séparées et dans le cadre', () {
        final layout = TeethLayout(dentition, size);
        final rects = [for (final id in layout.teeth) layout.rectOf(id)];
        expect(rects, hasLength(ToothId.all(dentition).length));
        for (var i = 0; i < rects.length; i++) {
          for (var j = i + 1; j < rects.length; j++) {
            final a = rects[i];
            final b = rects[j];
            expect(
              (a.center - b.center).distance,
              greaterThanOrEqualTo(a.width / 2 + b.width / 2),
              reason: 'dents $i et $j',
            );
          }
        }
        final frame = Offset.zero & size;
        for (final rect in rects) {
          expect(frame.contains(rect.topLeft), isTrue);
          expect(frame.contains(rect.bottomRight), isTrue);
        }
      });

      test('$dentition $size : toucher le centre d\'une dent la désigne', () {
        final layout = TeethLayout(dentition, size);
        for (final id in layout.teeth) {
          expect(layout.hitTest(layout.rectOf(id).center), id);
        }
        expect(layout.hitTest(size.center(Offset.zero)), isNull);
      });
    }
  }

  test('vu de face : symétrie droite/gauche et haut/bas', () {
    const size = Size(390, 429);
    final layout = TeethLayout(Dentition.primary, size);
    final upperRight = layout.rectOf(tooth(51)).center;
    final upperLeft = layout.rectOf(tooth(61)).center;
    final lowerRight = layout.rectOf(tooth(81)).center;
    // La droite de l'enfant est à gauche de l'écran.
    expect(upperRight.dx, lessThan(size.width / 2));
    expect(upperRight.dx, closeTo(size.width - upperLeft.dx, 1e-9));
    expect(upperRight.dy, closeTo(upperLeft.dy, 1e-9));
    expect(lowerRight.dy, closeTo(size.height - upperRight.dy, 1e-9));
    expect(lowerRight.dx, closeTo(upperRight.dx, 1e-9));
  });

  test('zone tactile élargie autour d\'une petite dent', () {
    const size = Size(390, 429);
    final layout = TeethLayout(Dentition.permanent, size);
    final incisor = layout.rectOf(tooth(11));
    final justOutside = incisor.center.translate(0, -(incisor.height / 2 + 4));
    expect(layout.hitTest(justOutside), tooth(11));
  });
}
```

- [ ] **Step 2 : lancer le test, il échoue**

Run: `flutter test test/features/teeth/presentation/teeth_layout_test.dart`
Expected: FAIL, `teeth_layout.dart` introuvable.

- [ ] **Step 3 : implémenter**

`lib/features/teeth/presentation/widgets/teeth_layout.dart` :

```dart
import 'dart:math';

import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:flutter/painting.dart';

/// Géométrie du schéma : position de chaque dent pour une dentition et une taille.
///
/// Vu de face : la droite de l'enfant est à gauche de l'écran. Chaque arcade est
/// une demi-ellipse ; l'arcade du bas est le reflet de celle du haut.
class TeethLayout {
  TeethLayout(this.dentition, this.size) : _rects = _compute(dentition, size);

  /// Largeur / hauteur du schéma.
  static const aspectRatio = 1 / 1.1;

  /// Libellé « Haut », au centre de l'arcade du haut.
  static const upperLabelAlignment = Alignment(0, -0.4);

  /// Libellé « Bas », au centre de l'arcade du bas.
  static const lowerLabelAlignment = Alignment(0, 0.4);

  // Demi-ellipses, en fractions de la largeur (X) et de la hauteur (Y).
  static const _radiusX = 0.40;
  static const _radiusY = 0.38;
  static const _baseY = 0.46;

  /// Part du quart d'ellipse occupée par les dents d'un côté.
  static const _sweep = pi / 2 * 0.92;

  final Dentition dentition;
  final Size size;
  final Map<ToothId, Rect> _rects;

  /// Rayon minimal de la zone tactile (48 pt de diamètre).
  static double get touchRadius => AppSize.xl.value / 2;

  /// Dents dans l'ordre du schéma.
  Iterable<ToothId> get teeth => _rects.keys;

  Rect rectOf(ToothId id) => _rects[id]!;

  /// Dent la plus proche de [point], si [point] est dans sa zone tactile.
  ToothId? hitTest(Offset point) {
    ToothId? nearest;
    var nearestDistance = double.infinity;
    for (final MapEntry(key: id, value: rect) in _rects.entries) {
      final distance = (rect.center - point).distance;
      final reach = max(rect.width / 2, touchRadius);
      if (distance <= reach && distance < nearestDistance) {
        nearest = id;
        nearestDistance = distance;
      }
    }
    return nearest;
  }

  static Map<ToothId, Rect> _compute(Dentition dentition, Size size) {
    final ids = ToothId.all(dentition);
    final perSide = ids.length ~/ 4;
    return {for (final id in ids) id: _rectOf(id, perSide, size)};
  }

  static Rect _rectOf(ToothId id, int perSide, Size size) {
    final angle = (id.position - 0.5) / perSide * _sweep;
    final direction = id.side == ToothSide.right ? -1.0 : 1.0;
    final x = size.width / 2 + direction * size.width * _radiusX * sin(angle);
    final upperY = size.height * (_baseY - _radiusY * cos(angle));
    final y = id.arch == ToothArch.upper ? upperY : size.height - upperY;
    return Rect.fromCircle(
      center: Offset(x, y),
      radius: size.width * _radiusFactor(id),
    );
  }

  /// Rayon d'une dent en fraction de la largeur : incisives petites, molaires grandes.
  static double _radiusFactor(ToothId id) => switch ((id.dentition, id.kind)) {
    (
      Dentition.primary,
      ToothKind.centralIncisor || ToothKind.lateralIncisor,
    ) =>
      0.040,
    (Dentition.primary, ToothKind.canine) => 0.045,
    (Dentition.primary, _) => 0.052,
    (
      Dentition.permanent,
      ToothKind.centralIncisor || ToothKind.lateralIncisor,
    ) =>
      0.028,
    (Dentition.permanent, ToothKind.canine) => 0.030,
    (
      Dentition.permanent,
      ToothKind.firstPremolar || ToothKind.secondPremolar,
    ) =>
      0.031,
    (Dentition.permanent, _) => 0.034,
  };

  @override
  bool operator ==(Object other) =>
      other is TeethLayout &&
      other.dentition == dentition &&
      other.size == size;

  @override
  int get hashCode => Object.hash(dentition, size);
}
```

- [ ] **Step 4 : lancer le test, il passe**

Run: `flutter test test/features/teeth/presentation/teeth_layout_test.dart`
Expected: PASS (10 tests). Si un test de chevauchement échoue, réduire le facteur de rayon du type concerné de 0,002 et relancer ; ne pas toucher aux tests.

- [ ] **Step 5 : commit**

```bash
git add lib/features/teeth/presentation/widgets/teeth_layout.dart test/features/teeth/presentation/teeth_layout_test.dart
git commit -m "feat: géométrie du schéma dentaire" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9 : textes et libellés des dents

**Files:**
- Modify: `lib/l10n/app_fr.arb`
- Create: `lib/features/teeth/presentation/teeth_ui.dart`
- Test: `test/features/teeth/presentation/teeth_ui_test.dart`

- [ ] **Step 1 : écrire le test qui échoue**

`test/features/teeth/presentation/teeth_ui_test.dart` :

```dart
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/use_cases/compute_teeth_summary.dart';
import 'package:colette/features/teeth/presentation/teeth_ui.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../teeth_factories.dart';

void main() {
  late S s;

  setUpAll(() async => s = await S.delegate.load(const Locale('fr')));

  test('nom complet d\'une dent', () {
    expect(toothName(tooth(51), s), 'Incisive centrale du haut, à droite');
    expect(toothName(tooth(36), s), 'Première molaire du bas, à gauche');
    expect(toothName(tooth(18), s), 'Dent de sagesse du haut, à droite');
  });

  test('repères d\'âge', () {
    expect(
      toothReferenceText(tooth(51), s),
      'Sort en général vers 8-12 mois, tombe vers 6-7 ans.',
    );
    expect(toothReferenceText(tooth(46), s), 'Sort en général vers 6-7 ans.');
  });

  test('libellés VoiceOver', () {
    expect(
      toothSemanticsLabel(tooth(71), null, s),
      'Incisive centrale du bas, à gauche, pas encore sortie',
    );
    expect(
      toothSemanticsLabel(
        tooth(71),
        makeTooth(71, eruptedAt: DateTime(2027, 1, 10, 12)),
        s,
      ),
      'Incisive centrale du bas, à gauche, sortie le 10 janv. 2027',
    );
    expect(
      toothSemanticsLabel(
        tooth(71),
        makeTooth(71, lostAt: DateTime(2033, 5, 2, 12)),
        s,
      ),
      'Incisive centrale du bas, à gauche, tombée le 2 mai 2033',
    );
  });

  test('compteur de la page', () {
    final day = DateTime(2027, 1, 10, 12);
    expect(teethCounterLabel(Dentition.primary, const {}, s), '0 sortie sur 20');
    expect(
      teethCounterLabel(Dentition.primary, {
        tooth(71): makeTooth(71, eruptedAt: day),
      }, s),
      '1 sortie sur 20',
    );
    expect(
      teethCounterLabel(Dentition.primary, {
        tooth(71): makeTooth(71, eruptedAt: day),
        tooth(81): makeTooth(81, eruptedAt: day, lostAt: day),
      }, s),
      '2 sorties sur 20 · 1 tombée',
    );
    expect(
      teethCounterLabel(Dentition.permanent, const {}, s),
      '0 sortie sur 32',
    );
  });

  test('ligne « Ensuite » de la carte', () {
    expect(
      teethNextLabel(const ComputeTeethSummary()(const {}).next, s),
      'Ensuite : incisives centrales du bas (6-10 mois), '
      'puis incisives centrales du haut (8-12 mois)',
    );
    expect(teethNextLabel(const [], s), isNull);
  });
}
```

- [ ] **Step 2 : lancer le test, il échoue**

Run: `flutter test test/features/teeth/presentation/teeth_ui_test.dart`
Expected: FAIL, `teeth_ui.dart` introuvable.

- [ ] **Step 3 : ajouter les textes**

Dans `lib/l10n/app_fr.arb`, ajouter une virgule après la dernière entrée (`"errorToothLossOnPermanent": "…"`) puis, avant l'accolade fermante :

```json
  "teethTitle": "Dents",
  "teethNone": "Pas encore de dent",
  "teethInMouth": "{count, plural, =1{1 dent en bouche} other{{count} dents en bouche}}",
  "@teethInMouth": { "placeholders": { "count": { "type": "int" } } },
  "teethNextOne": "Ensuite : {first}",
  "@teethNextOne": { "placeholders": { "first": { "type": "String" } } },
  "teethNextTwo": "Ensuite : {first}, puis {second}",
  "@teethNextTwo": { "placeholders": { "first": { "type": "String" }, "second": { "type": "String" } } },
  "teethExpectedGroup": "{teeth} {arch} ({range})",
  "@teethExpectedGroup": { "placeholders": { "teeth": { "type": "String" }, "arch": { "type": "String" }, "range": { "type": "String" } } },
  "teethPrimary": "De lait",
  "teethPermanent": "Définitives",
  "teethEruptedCount": "{count, plural, =0{0 sortie} =1{1 sortie} other{{count} sorties}} sur {total}",
  "@teethEruptedCount": { "placeholders": { "count": { "type": "int" }, "total": { "type": "int" } } },
  "teethLostCount": "{count, plural, =1{1 tombée} other{{count} tombées}}",
  "@teethLostCount": { "placeholders": { "count": { "type": "int" } } },
  "teethCounterWithLost": "{erupted} · {lost}",
  "@teethCounterWithLost": { "placeholders": { "erupted": { "type": "String" }, "lost": { "type": "String" } } },
  "teethLegendErupted": "Sortie",
  "teethLegendLost": "Tombée",
  "teethLegendAbsent": "Pas encore",
  "teethUpper": "Haut",
  "teethLower": "Bas",
  "teethRight": "Droite",
  "teethLeft": "Gauche",
  "toothKindCentralIncisor": "Incisive centrale",
  "toothKindLateralIncisor": "Incisive latérale",
  "toothKindCanine": "Canine",
  "toothKindFirstPremolar": "Première prémolaire",
  "toothKindSecondPremolar": "Deuxième prémolaire",
  "toothKindFirstMolar": "Première molaire",
  "toothKindSecondMolar": "Deuxième molaire",
  "toothKindThirdMolar": "Dent de sagesse",
  "toothGroupCentralIncisor": "incisives centrales",
  "toothGroupLateralIncisor": "incisives latérales",
  "toothGroupCanine": "canines",
  "toothGroupFirstPremolar": "premières prémolaires",
  "toothGroupSecondPremolar": "deuxièmes prémolaires",
  "toothGroupFirstMolar": "premières molaires",
  "toothGroupSecondMolar": "deuxièmes molaires",
  "toothGroupThirdMolar": "dents de sagesse",
  "toothArchUpper": "du haut",
  "toothArchLower": "du bas",
  "toothSideRight": "à droite",
  "toothSideLeft": "à gauche",
  "toothName": "{kind} {arch}, {side}",
  "@toothName": { "placeholders": { "kind": { "type": "String" }, "arch": { "type": "String" }, "side": { "type": "String" } } },
  "toothSemanticsAbsent": "{tooth}, pas encore sortie",
  "@toothSemanticsAbsent": { "placeholders": { "tooth": { "type": "String" } } },
  "toothSemanticsErupted": "{tooth}, sortie le {date}",
  "@toothSemanticsErupted": { "placeholders": { "tooth": { "type": "String" }, "date": { "type": "String" } } },
  "toothSemanticsLost": "{tooth}, tombée le {date}",
  "@toothSemanticsLost": { "placeholders": { "tooth": { "type": "String" }, "date": { "type": "String" } } },
  "toothAgeMonths": "{from}-{to} mois",
  "@toothAgeMonths": { "placeholders": { "from": { "type": "int" }, "to": { "type": "int" } } },
  "toothAgeYears": "{from}-{to} ans",
  "@toothAgeYears": { "placeholders": { "from": { "type": "int" }, "to": { "type": "int" } } },
  "toothNumber": "Dent n° {number}",
  "@toothNumber": { "placeholders": { "number": { "type": "int" } } },
  "toothReferenceEruption": "Sort en général vers {range}.",
  "@toothReferenceEruption": { "placeholders": { "range": { "type": "String" } } },
  "toothReferenceFull": "Sort en général vers {eruption}, tombe vers {shedding}.",
  "@toothReferenceFull": { "placeholders": { "eruption": { "type": "String" }, "shedding": { "type": "String" } } },
  "toothEruptedAt": "Sortie le",
  "toothLostAt": "Tombée le",
  "toothAddEruption": "Ajouter la date de sortie",
  "toothAddLoss": "Ajouter la date de chute",
  "toothRemoveDate": "Retirer la date",
  "toothNote": "Note (facultatif)",
  "toothClear": "Tout effacer",
  "toothClearTitle": "Effacer cette dent ?",
  "toothClearBody": "Les dates et la note de cette dent seront supprimées."
```

Run: `flutter gen-l10n`
Expected: génération sans erreur.

- [ ] **Step 4 : implémenter les libellés**

`lib/features/teeth/presentation/teeth_ui.dart` :

```dart
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/features/teeth/domain/entities/teeth_summary.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/domain/entities/tooth_status.dart';
import 'package:colette/features/teeth/domain/reference/tooth_schedule.dart';
import 'package:colette/features/teeth/domain/use_cases/compute_tooth_status.dart';
import 'package:colette/l10n/generated/app_localizations.dart';

/// « Incisive centrale ».
String toothKindLabel(ToothKind kind, S s) => switch (kind) {
  ToothKind.centralIncisor => s.toothKindCentralIncisor,
  ToothKind.lateralIncisor => s.toothKindLateralIncisor,
  ToothKind.canine => s.toothKindCanine,
  ToothKind.firstPremolar => s.toothKindFirstPremolar,
  ToothKind.secondPremolar => s.toothKindSecondPremolar,
  ToothKind.firstMolar => s.toothKindFirstMolar,
  ToothKind.secondMolar => s.toothKindSecondMolar,
  ToothKind.thirdMolar => s.toothKindThirdMolar,
};

/// « incisives centrales ».
String toothGroupLabel(ToothKind kind, S s) => switch (kind) {
  ToothKind.centralIncisor => s.toothGroupCentralIncisor,
  ToothKind.lateralIncisor => s.toothGroupLateralIncisor,
  ToothKind.canine => s.toothGroupCanine,
  ToothKind.firstPremolar => s.toothGroupFirstPremolar,
  ToothKind.secondPremolar => s.toothGroupSecondPremolar,
  ToothKind.firstMolar => s.toothGroupFirstMolar,
  ToothKind.secondMolar => s.toothGroupSecondMolar,
  ToothKind.thirdMolar => s.toothGroupThirdMolar,
};

/// « du haut » / « du bas ».
String toothArchLabel(ToothArch arch, S s) => switch (arch) {
  ToothArch.upper => s.toothArchUpper,
  ToothArch.lower => s.toothArchLower,
};

/// « Incisive centrale du haut, à droite ».
String toothName(ToothId id, S s) => s.toothName(
  toothKindLabel(id.kind, s),
  toothArchLabel(id.arch, s),
  switch (id.side) {
    ToothSide.right => s.toothSideRight,
    ToothSide.left => s.toothSideLeft,
  },
);

/// « 6-10 mois » ou « 6-7 ans ».
String ageRangeLabel(AgeRange range, S s) => switch (range.unit) {
  AgeUnit.months => s.toothAgeMonths(range.from, range.to),
  AgeUnit.years => s.toothAgeYears(range.from, range.to),
};

/// « incisives centrales du bas (6-10 mois) ».
String expectedGroupLabel(ExpectedTeethGroup group, S s) =>
    s.teethExpectedGroup(
      toothGroupLabel(group.kind, s),
      toothArchLabel(group.arch, s),
      ageRangeLabel(group.eruption, s),
    );

/// Repère d'âge affiché dans la fiche.
String toothReferenceText(ToothId id, S s) {
  final reference = toothReferenceOf(id);
  final eruption = ageRangeLabel(reference.eruption, s);
  return switch (reference.shedding) {
    null => s.toothReferenceEruption(eruption),
    final shedding => s.toothReferenceFull(
      eruption,
      ageRangeLabel(shedding, s),
    ),
  };
}

/// Libellé VoiceOver d'une dent du schéma.
String toothSemanticsLabel(ToothId id, ToothRecord? record, S s) {
  final name = toothName(id, s);
  return switch ((const ComputeToothStatus()(record), record)) {
    (ToothStatus.lost, ToothRecord(lostAt: final at?)) =>
      s.toothSemanticsLost(name, formatShortDate(at)),
    (ToothStatus.erupted, ToothRecord(eruptedAt: final at?)) =>
      s.toothSemanticsErupted(name, formatShortDate(at)),
    _ => s.toothSemanticsAbsent(name),
  };
}

/// Compteur de la page : « 3 sorties sur 20 », suivi des dents tombées.
String teethCounterLabel(
  Dentition dentition,
  Map<ToothId, ToothRecord> records,
  S s,
) {
  const status = ComputeToothStatus();
  final ids = ToothId.all(dentition);
  final statuses = [for (final id in ids) status(records[id])];
  final noted = statuses.where((st) => st != ToothStatus.absent).length;
  final lost = statuses.where((st) => st == ToothStatus.lost).length;
  final erupted = s.teethEruptedCount(noted, ids.length);
  return lost == 0
      ? erupted
      : s.teethCounterWithLost(erupted, s.teethLostCount(lost));
}

/// Ligne « Ensuite : … » de la carte ; `null` sans groupe attendu.
String? teethNextLabel(List<ExpectedTeethGroup> next, S s) => switch (next) {
  [] => null,
  [final first] => s.teethNextOne(expectedGroupLabel(first, s)),
  [final first, final second, ...] => s.teethNextTwo(
    expectedGroupLabel(first, s),
    expectedGroupLabel(second, s),
  ),
};
```

- [ ] **Step 5 : lancer le test, il passe**

Run: `flutter test test/features/teeth/presentation/teeth_ui_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 6 : commit**

```bash
git add lib/l10n/app_fr.arb lib/features/teeth/presentation/teeth_ui.dart test/features/teeth/presentation/teeth_ui_test.dart
git commit -m "feat: textes et libellés des dents" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 10 : schéma interactif et légende

**Files:**
- Create: `lib/features/teeth/presentation/widgets/teeth_chart_painter.dart`
- Create: `lib/features/teeth/presentation/widgets/teeth_chart.dart`
- Create: `lib/features/teeth/presentation/widgets/teeth_legend.dart`
- Test: `test/features/teeth/presentation/teeth_chart_test.dart`

- [ ] **Step 1 : écrire le test qui échoue**

`test/features/teeth/presentation/teeth_chart_test.dart` :

```dart
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_chart.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_layout.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_legend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../teeth_factories.dart';

void main() {
  final records = <ToothId, ToothRecord>{
    tooth(71): makeTooth(71, eruptedAt: DateTime(2027, 1, 10, 12)),
  };

  Future<List<ToothId>> pumpChart(
    WidgetTester tester,
    Dentition dentition,
  ) async {
    final tapped = <ToothId>[];
    await pumpApp(
      tester,
      Scaffold(
        body: ListView(
          children: [
            TeethChart(
              dentition: dentition,
              records: records,
              onToothTap: tapped.add,
            ),
            const TeethLegend(),
          ],
        ),
      ),
      viewSize: const Size(390, 900),
    );
    return tapped;
  }

  Future<void> tapTooth(
    WidgetTester tester,
    Dentition dentition,
    ToothId id,
  ) async {
    final canvas = tester.getRect(find.byKey(TeethChart.canvasKey));
    final layout = TeethLayout(dentition, canvas.size);
    await tester.tapAt(canvas.topLeft + layout.rectOf(id).center);
    await tester.pump();
  }

  testWidgets('toucher une dent la signale', (tester) async {
    final tapped = await pumpChart(tester, Dentition.primary);
    await tapTooth(tester, Dentition.primary, tooth(51));
    await tapTooth(tester, Dentition.primary, tooth(85));
    expect(tapped, [tooth(51), tooth(85)]);
  });

  testWidgets('toucher le centre du schéma ne fait rien', (tester) async {
    final tapped = await pumpChart(tester, Dentition.permanent);
    await tester.tap(find.byKey(TeethChart.canvasKey));
    expect(tapped, isEmpty);
  });

  testWidgets('libellés, légende et VoiceOver', (tester) async {
    final handle = tester.ensureSemantics();
    final tapped = await pumpChart(tester, Dentition.primary);
    for (final text in [
      'Haut',
      'Bas',
      'Droite',
      'Gauche',
      'Sortie',
      'Tombée',
      'Pas encore',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(
      find.semantics.byLabel(
        'Incisive centrale du bas, à gauche, sortie le 10 janv. 2027',
      ),
      findsOne,
    );
    final upperRight = find.semantics.byLabel(
      'Incisive centrale du haut, à droite, pas encore sortie',
    );
    expect(upperRight, findsOne);
    tester.semantics.tap(upperRight);
    expect(tapped, [tooth(51)]);
    handle.dispose();
  });
}
```

- [ ] **Step 2 : lancer le test, il échoue**

Run: `flutter test test/features/teeth/presentation/teeth_chart_test.dart`
Expected: FAIL, `teeth_chart.dart` introuvable.

- [ ] **Step 3 : implémenter le peintre**

`lib/features/teeth/presentation/widgets/teeth_chart_painter.dart` :

```dart
import 'dart:math';

import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/domain/entities/tooth_status.dart';
import 'package:colette/features/teeth/domain/use_cases/compute_tooth_status.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_layout.dart';
import 'package:flutter/material.dart';

/// Couleurs du schéma, résolues selon le thème.
typedef TeethChartColors = ({
  Color erupted,
  Color lostFill,
  Color lostStroke,
  Color mark,
  Color absent,
  Color selected,
});

/// Dessine les dents selon leur état ; une zone VoiceOver par dent.
class TeethChartPainter extends CustomPainter {
  TeethChartPainter({
    required this.layout,
    required this.records,
    required this.selected,
    required this.colors,
    required this.labelOf,
    required this.onToothTap,
  });

  final TeethLayout layout;
  final Map<ToothId, ToothRecord> records;
  final ToothId? selected;
  final TeethChartColors colors;
  final String Function(ToothId) labelOf;
  final ValueChanged<ToothId> onToothTap;

  @override
  void paint(Canvas canvas, Size size) {
    const status = ComputeToothStatus();
    final strokeWidth = AppSpacing.xxs.value;
    for (final id in layout.teeth) {
      final rect = layout.rectOf(id);
      final oval = Path()..addOval(rect);
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      switch (status(records[id])) {
        case ToothStatus.erupted:
          canvas.drawPath(oval, Paint()..color = colors.erupted);
        case ToothStatus.lost:
          canvas.drawPath(oval, Paint()..color = colors.lostFill);
          canvas.drawPath(oval, stroke..color = colors.lostStroke);
          _drawCross(canvas, rect, strokeWidth);
        case ToothStatus.absent:
          canvas.drawPath(_dashed(oval), stroke..color = colors.absent);
      }
      if (id == selected) {
        canvas.drawPath(
          oval,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = AppSpacing.xs.value
            ..color = colors.selected,
        );
      }
    }
  }

  void _drawCross(Canvas canvas, Rect rect, double strokeWidth) {
    final inner = rect.deflate(rect.width / 4);
    final paint = Paint()
      ..color = colors.mark
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(inner.topLeft, inner.bottomRight, paint)
      ..drawLine(inner.topRight, inner.bottomLeft, paint);
  }

  /// Contour pointillé de [source] : traits et blancs de même longueur.
  static Path _dashed(Path source) {
    final dash = AppSpacing.xs.value;
    final result = Path();
    for (final metric in source.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += dash * 2) {
        result.addPath(
          metric.extractPath(start, min(start + dash, metric.length)),
          Offset.zero,
        );
      }
    }
    return result;
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder => (size) => [
    for (final id in layout.teeth)
      CustomPainterSemantics(
        key: ValueKey(id.value),
        rect: layout.rectOf(id),
        properties: SemanticsProperties(
          label: labelOf(id),
          textDirection: TextDirection.ltr,
          button: true,
          selected: id == selected,
          onTap: () => onToothTap(id),
        ),
      ),
  ];

  bool _differs(TeethChartPainter old) =>
      old.layout != layout ||
      !mapEquals(old.records, records) ||
      old.selected != selected;

  @override
  bool shouldRepaint(TeethChartPainter oldDelegate) =>
      _differs(oldDelegate) || oldDelegate.colors != colors;

  @override
  bool shouldRebuildSemantics(TeethChartPainter oldDelegate) =>
      _differs(oldDelegate);
}
```

- [ ] **Step 4 : implémenter le widget et la légende**

`lib/features/teeth/presentation/widgets/teeth_chart.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/presentation/teeth_ui.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_chart_painter.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_layout.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Schéma interactif d'une dentition : deux arcades, une forme par dent.
class TeethChart extends StatelessWidget {
  const TeethChart({
    super.key,
    required this.dentition,
    required this.records,
    required this.onToothTap,
    this.selected,
  });

  /// Clé de la zone de dessin, pour viser une dent dans les tests.
  static const canvasKey = Key('teethChartCanvas');

  final Dentition dentition;
  final Map<ToothId, ToothRecord> records;
  final ValueChanged<ToothId> onToothTap;
  final ToothId? selected;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final label = Theme.of(context).coletteTextStyles.small
        .copyWith(color: context.appColor(AppColors.textSecondary));
    final colors = (
      erupted: context.appColor(AppColors.primary),
      lostFill: context.appColor(AppColors.surfaceContainer),
      lostStroke: context.appColor(AppColors.border),
      mark: context.appColor(AppColors.textSecondary),
      absent: context.appColor(AppColors.textSecondary),
      selected: context.appColor(AppColors.accent),
    );
    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.xs.value,
      children: [
        AspectRatio(
          aspectRatio: TeethLayout.aspectRatio,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = TeethLayout(dentition, constraints.biggest);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                // Les dents portent leur propre action VoiceOver (peintre).
                excludeFromSemantics: true,
                onTapUp: (details) {
                  if (layout.hitTest(details.localPosition) case final id?) {
                    onToothTap(id);
                  }
                },
                child: CustomPaint(
                  key: canvasKey,
                  painter: TeethChartPainter(
                    layout: layout,
                    records: records,
                    selected: selected,
                    colors: colors,
                    labelOf: (id) => toothSemanticsLabel(id, records[id], s),
                    onToothTap: onToothTap,
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: TeethLayout.upperLabelAlignment,
                        child: Text(s.teethUpper, style: label),
                      ),
                      Align(
                        alignment: TeethLayout.lowerLabelAlignment,
                        child: Text(s.teethLower, style: label),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Text(s.teethRight, style: label),
            Text(s.teethLeft, style: label),
          ],
        ),
      ],
    );
  }
}
```

`lib/features/teeth/presentation/widgets/teeth_legend.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Légende du schéma : sortie, tombée, pas encore.
class TeethLegend extends StatelessWidget {
  const TeethLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.md.value,
      runSpacing: AppSpacing.xs.value,
      children: [
        _LegendItem(
          label: s.teethLegendErupted,
          fill: AppColors.primary,
          border: AppColors.primary,
        ),
        _LegendItem(
          label: s.teethLegendLost,
          fill: AppColors.surfaceContainer,
          border: AppColors.border,
        ),
        _LegendItem(
          label: s.teethLegendAbsent,
          fill: AppColors.transparent,
          border: AppColors.textSecondary,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.fill,
    required this.border,
  });

  final String label;
  final AppColors fill;
  final AppColors border;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: .min,
    spacing: AppSpacing.xs.value,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.appColor(fill),
          border: Border.all(
            color: context.appColor(border),
            width: AppSpacing.xxs.value,
          ),
        ),
        child: AppSize.xs.square,
      ),
      Text(label, style: Theme.of(context).coletteTextStyles.small),
    ],
  );
}
```

- [ ] **Step 5 : lancer le test, il passe**

Run: `flutter test test/features/teeth/presentation/teeth_chart_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 6 : commit**

```bash
git add lib/features/teeth/presentation/widgets/teeth_chart_painter.dart lib/features/teeth/presentation/widgets/teeth_chart.dart lib/features/teeth/presentation/widgets/teeth_legend.dart test/features/teeth/presentation/teeth_chart_test.dart
git commit -m "feat: schéma dentaire interactif" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 11 : fiche d'une dent

**Files:**
- Create: `lib/features/teeth/presentation/widgets/optional_date_field.dart`
- Create: `lib/features/teeth/presentation/widgets/tooth_sheet.dart`
- Test: `test/features/teeth/presentation/tooth_sheet_test.dart`

- [ ] **Step 1 : écrire le test qui échoue**

`test/features/teeth/presentation/tooth_sheet_test.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/presentation/providers/teeth_providers.dart';
import 'package:colette/features/teeth/presentation/widgets/tooth_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';
import '../teeth_factories.dart';

void main() {
  late MockTeethRepository repo;

  setUpAll(() {
    registerFallbackValue(makeTooth(51));
    registerFallbackValue(tooth(51));
  });

  setUp(() {
    repo = MockTeethRepository();
    when(() => repo.saveTooth(any(), any())).thenAnswer((_) async => right(null));
    when(
      () => repo.deleteTooth(any(), any()),
    ).thenAnswer((_) async => right(null));
  });

  Future<void> pumpSheet(
    WidgetTester tester,
    ToothId id, {
    ToothRecord? initial,
  }) => pumpApp(
    tester,
    Scaffold(body: ToothSheet(toothId: id, initial: initial)),
    viewSize: const Size(390, 1200),
    overrides: [
      teethRepositoryProvider.overrideWithValue(repo),
      clockProvider.overrideWithValue(FixedClock(DateTime(2027, 3, 10, 9))),
      householdLocalStoreProvider.overrideWithValue(
        InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
      ),
      babyProfileProvider.overrideWith(
        (ref) => Stream.value(
          BabyProfile(name: 'C', birthDate: DateTime(2026, 9, 1)),
        ),
      ),
    ],
  );

  testWidgets('dent de lait vide : repère, sortie du jour et note', (
    tester,
  ) async {
    await pumpSheet(tester, tooth(71));
    expect(find.text('Incisive centrale du bas, à gauche'), findsOneWidget);
    expect(find.text('Dent n° 71'), findsOneWidget);
    expect(
      find.text('Sort en général vers 6-10 mois, tombe vers 6-7 ans.'),
      findsOneWidget,
    );
    expect(find.text('Ajouter la date de chute'), findsOneWidget);
    await tester.tap(find.text('Ajouter la date de sortie'));
    await tester.pumpAndSettle();
    expect(find.text('10 mars 2027'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Nuit agitée');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final saved =
        verify(() => repo.saveTooth('ABCDEFGH', captureAny())).captured.single
            as ToothRecord;
    expect(saved.eruptedAt, DateTime(2027, 3, 10, 12));
    expect(saved.lostAt, isNull);
    expect(saved.note, 'Nuit agitée');
  });

  testWidgets('dent définitive : pas de date de chute', (tester) async {
    await pumpSheet(tester, tooth(36));
    expect(find.text('Sort en général vers 6-7 ans.'), findsOneWidget);
    expect(find.text('Ajouter la date de chute'), findsNothing);
    expect(find.text('Tout effacer'), findsNothing);
  });

  testWidgets('retirer la date de sortie', (tester) async {
    await pumpSheet(
      tester,
      tooth(71),
      initial: makeTooth(71, eruptedAt: DateTime(2027, 1, 10, 12)),
    );
    expect(find.text('10 janv. 2027'), findsOneWidget);
    await tester.tap(find.text('Retirer la date'));
    await tester.pumpAndSettle();
    expect(find.text('Ajouter la date de sortie'), findsOneWidget);
  });

  testWidgets('erreur de validation affichée, rien n\'est écrit', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      tooth(71),
      initial: makeTooth(
        71,
        eruptedAt: DateTime(2027, 3, 1, 12),
        lostAt: DateTime(2027, 2, 1, 12),
      ),
    );
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(
      find.text('La chute ne peut pas précéder la sortie.'),
      findsOneWidget,
    );
    verifyNever(() => repo.saveTooth(any(), any()));
  });

  testWidgets('tout effacer demande confirmation puis supprime', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      tooth(71),
      initial: makeTooth(71, eruptedAt: DateTime(2027, 1, 10, 12)),
    );
    await tester.tap(find.text('Tout effacer'));
    await tester.pumpAndSettle();
    expect(find.text('Effacer cette dent ?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Tout effacer'),
      ),
    );
    await tester.pumpAndSettle();
    verify(() => repo.deleteTooth('ABCDEFGH', tooth(71))).called(1);
  });
}
```

- [ ] **Step 2 : lancer le test, il échoue**

Run: `flutter test test/features/teeth/presentation/tooth_sheet_test.dart`
Expected: FAIL, `tooth_sheet.dart` introuvable.

- [ ] **Step 3 : implémenter le champ de date facultatif**

`lib/features/teeth/presentation/widgets/optional_date_field.dart` :

```dart
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/date_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Date facultative : bouton d'ajout, puis champ de date et bouton pour la retirer.
class OptionalDateField extends StatelessWidget {
  const OptionalDateField({
    super.key,
    required this.label,
    required this.addLabel,
    required this.value,
    required this.defaultDate,
    required this.minimum,
    required this.maximum,
    required this.onChanged,
  });

  final String label;
  final String addLabel;
  final DateTime? value;

  /// Date proposée à l'ajout (aujourd'hui à midi).
  final DateTime defaultDate;
  final DateTime minimum;
  final DateTime maximum;
  final ValueChanged<DateTime?> onChanged;

  Future<void> _pick(BuildContext context, DateTime current) async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: current,
      mode: CupertinoDatePickerMode.date,
      minimum: minimum,
      maximum: maximum,
    );
    // Seul le jour compte : midi évite tout décalage lié à l'heure.
    if (picked != null) {
      onChanged(DateTime(picked.year, picked.month, picked.day, 12));
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = value;
    if (date == null) {
      return OutlinedButton.icon(
        onPressed: () => onChanged(defaultDate),
        icon: const Icon(Icons.add),
        label: Text(addLabel),
      );
    }
    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.xs.value,
      children: [
        DateField(
          label: label,
          value: formatShortDate(date),
          onTap: () => _pick(context, date),
        ),
        TextButton.icon(
          onPressed: () => onChanged(null),
          icon: const Icon(Icons.undo),
          label: Text(S.of(context).toothRemoveDate),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4 : implémenter la fiche**

`lib/features/teeth/presentation/widgets/tooth_sheet.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/health/presentation/widgets/sheet_failure_text.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/presentation/providers/teeth_controller.dart';
import 'package:colette/features/teeth/presentation/teeth_ui.dart';
import 'package:colette/features/teeth/presentation/widgets/optional_date_field.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre la fiche de [toothId] ; [initial] `null` si rien n'est noté.
Future<void> showToothSheet(
  BuildContext context, {
  required ToothId toothId,
  ToothRecord? initial,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => ToothSheet(toothId: toothId, initial: initial),
);

/// Fiche d'une dent : repère d'âge, sortie, chute (dent de lait), note.
class ToothSheet extends ConsumerStatefulWidget {
  const ToothSheet({super.key, required this.toothId, this.initial});

  final ToothId toothId;
  final ToothRecord? initial;

  @override
  ConsumerState<ToothSheet> createState() => _ToothSheetState();
}

class _ToothSheetState extends ConsumerState<ToothSheet> {
  late final _note = TextEditingController(text: widget.initial?.note ?? '');
  late DateTime? _eruptedAt = widget.initial?.eruptedAt;
  late DateTime? _lostAt = widget.initial?.lostAt;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save(DateTime birthDate, DateTime now) async {
    final record = ToothRecord(
      toothId: widget.toothId,
      eruptedAt: _eruptedAt,
      lostAt: _lostAt,
      note: _note.text,
      updatedAt: now,
      updatedByDeviceId: '',
    );
    final ok = await ref
        .read(teethControllerProvider.notifier)
        .save(record, birthDate: birthDate);
    if (ok && mounted) await Navigator.of(context).maybePop();
  }

  Future<void> _clear() async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.toothClearTitle),
        content: Text(s.toothClearBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.toothClear),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await ref
        .read(teethControllerProvider.notifier)
        .clear(widget.toothId);
    if (ok && mounted) await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    final id = widget.toothId;
    final birthDate = ref.watch(babyProfileProvider).value?.birthDate;
    final saveState = ref.watch(teethControllerProvider);
    final isSaving = saveState is AsyncLoading;
    final now = ref.watch(clockProvider).now();
    final today = DateTime(now.year, now.month, now.day, 12);
    final minimum = birthDate ?? now;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        shrinkWrap: true,
        padding: AppSpacing.lg.all,
        children: [
          Text(toothName(id, s), style: styles.heading2),
          Text(
            s.toothNumber(id.value),
            style: styles.small.copyWith(color: secondary),
          ),
          AppSpacing.sm.verticalSpace,
          Text(
            toothReferenceText(id, s),
            style: styles.body.copyWith(color: secondary),
          ),
          AppSpacing.lg.verticalSpace,
          OptionalDateField(
            label: s.toothEruptedAt,
            addLabel: s.toothAddEruption,
            value: _eruptedAt,
            defaultDate: today,
            minimum: minimum,
            maximum: now,
            onChanged: (value) => setState(() => _eruptedAt = value),
          ),
          if (id.dentition == Dentition.primary) ...[
            AppSpacing.md.verticalSpace,
            OptionalDateField(
              label: s.toothLostAt,
              addLabel: s.toothAddLoss,
              value: _lostAt,
              defaultDate: today,
              minimum: minimum,
              maximum: now,
              onChanged: (value) => setState(() => _lostAt = value),
            ),
          ],
          AppSpacing.md.verticalSpace,
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: s.toothNote),
            maxLines: null,
            textCapitalization: .sentences,
          ),
          if (saveState case AsyncError(:final error))
            SheetFailureText(failure: error),
          AppSpacing.lg.verticalSpace,
          FilledButton(
            onPressed: isSaving || birthDate == null
                ? null
                : () => _save(birthDate, now),
            child: Text(s.actionSave),
          ),
          if (widget.initial != null)
            TextButton(
              onPressed: isSaving ? null : _clear,
              style: TextButton.styleFrom(
                foregroundColor: context.appColor(AppColors.error),
              ),
              child: Text(s.toothClear),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5 : lancer le test, il passe**

Run: `flutter test test/features/teeth/presentation/tooth_sheet_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 6 : commit**

```bash
git add lib/features/teeth/presentation/widgets/optional_date_field.dart lib/features/teeth/presentation/widgets/tooth_sheet.dart test/features/teeth/presentation/tooth_sheet_test.dart
git commit -m "feat: fiche d'une dent" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 12 : page Dents et route

**Files:**
- Create: `lib/features/teeth/presentation/pages/teeth_page.dart`
- Modify: `lib/app/router/app_router.dart`
- Test: `test/features/teeth/presentation/teeth_page_test.dart`

- [ ] **Step 1 : écrire le test qui échoue**

`test/features/teeth/presentation/teeth_page_test.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/presentation/pages/teeth_page.dart';
import 'package:colette/features/teeth/presentation/providers/teeth_providers.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_chart.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';
import '../teeth_factories.dart';

void main() {
  final day = DateTime(2027, 1, 10, 12);
  final records = <ToothId, ToothRecord>{
    tooth(71): makeTooth(71, eruptedAt: day),
    tooth(81): makeTooth(81, eruptedAt: day, lostAt: DateTime(2027, 2, 1, 12)),
  };

  Future<void> pumpPage(WidgetTester tester) => pumpApp(
    tester,
    const TeethPage(),
    viewSize: const Size(390, 1200),
    overrides: [
      teethRepositoryProvider.overrideWithValue(MockTeethRepository()),
      teethProvider.overrideWith((ref) => Stream.value(records)),
      clockProvider.overrideWithValue(FixedClock(DateTime(2027, 3, 10, 9))),
      householdLocalStoreProvider.overrideWithValue(
        InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
      ),
      babyProfileProvider.overrideWith(
        (ref) => Stream.value(
          BabyProfile(name: 'C', birthDate: DateTime(2026, 9, 1)),
        ),
      ),
    ],
  );

  Future<void> tapTooth(
    WidgetTester tester,
    Dentition dentition,
    ToothId id,
  ) async {
    final canvas = tester.getRect(find.byKey(TeethChart.canvasKey));
    final layout = TeethLayout(dentition, canvas.size);
    await tester.tapAt(canvas.topLeft + layout.rectOf(id).center);
    await tester.pumpAndSettle();
  }

  testWidgets('dents de lait par défaut, compteur, fiche au toucher', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(find.text('Dents'), findsOneWidget);
    expect(find.text('2 sorties sur 20 · 1 tombée'), findsOneWidget);
    await tapTooth(tester, Dentition.primary, tooth(51));
    expect(find.text('Incisive centrale du haut, à droite'), findsOneWidget);
    expect(find.text('Ajouter la date de sortie'), findsOneWidget);
  });

  testWidgets('bascule sur les dents définitives', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('Définitives'));
    await tester.pumpAndSettle();
    expect(find.text('0 sortie sur 32'), findsOneWidget);
    await tapTooth(tester, Dentition.permanent, tooth(36));
    expect(find.text('Première molaire du bas, à gauche'), findsOneWidget);
    expect(find.text('Ajouter la date de chute'), findsNothing);
  });
}
```

- [ ] **Step 2 : lancer le test, il échoue**

Run: `flutter test test/features/teeth/presentation/teeth_page_test.dart`
Expected: FAIL, `teeth_page.dart` introuvable.

- [ ] **Step 3 : implémenter la page**

`lib/features/teeth/presentation/pages/teeth_page.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/presentation/providers/teeth_providers.dart';
import 'package:colette/features/teeth/presentation/teeth_ui.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_chart.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_legend.dart';
import 'package:colette/features/teeth/presentation/widgets/tooth_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Page Dents : schéma des dents de lait ou définitives, fiche au toucher.
class TeethPage extends ConsumerStatefulWidget {
  const TeethPage({super.key});

  @override
  ConsumerState<TeethPage> createState() => _TeethPageState();
}

class _TeethPageState extends ConsumerState<TeethPage> {
  var _dentition = Dentition.primary;

  /// Dent dont la fiche est ouverte, mise en évidence sur le schéma.
  ToothId? _selected;

  Future<void> _open(ToothId id, ToothRecord? record) async {
    setState(() => _selected = id);
    await showToothSheet(context, toothId: id, initial: record);
    if (mounted) setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.teethTitle)),
      body: switch (ref.watch(teethProvider)) {
        AsyncData(:final value) => _TeethBody(
          dentition: _dentition,
          records: value,
          selected: _selected,
          onDentitionChanged: (dentition) =>
              setState(() => _dentition = dentition),
          onToothTap: (id) => _open(id, value[id]),
        ),
        AsyncError(:final error) => Center(
          child: Padding(
            padding: AppSpacing.lg.all,
            child: Text(failureMessage(error, s), textAlign: .center),
          ),
        ),
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _TeethBody extends StatelessWidget {
  const _TeethBody({
    required this.dentition,
    required this.records,
    required this.selected,
    required this.onDentitionChanged,
    required this.onToothTap,
  });

  final Dentition dentition;
  final Map<ToothId, ToothRecord> records;
  final ToothId? selected;
  final ValueChanged<Dentition> onDentitionChanged;
  final ValueChanged<ToothId> onToothTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ListView(
      padding: AppSpacing.md.all,
      children: [
        SegmentedButton<Dentition>(
          segments: [
            ButtonSegment(
              value: Dentition.primary,
              label: Text(s.teethPrimary),
            ),
            ButtonSegment(
              value: Dentition.permanent,
              label: Text(s.teethPermanent),
            ),
          ],
          selected: {dentition},
          onSelectionChanged: (selection) =>
              onDentitionChanged(selection.single),
        ),
        AppSpacing.md.verticalSpace,
        Text(
          teethCounterLabel(dentition, records, s),
          style: Theme.of(context).coletteTextStyles.body
              .copyWith(color: context.appColor(AppColors.textSecondary)),
        ),
        AppSpacing.md.verticalSpace,
        TeethChart(
          dentition: dentition,
          records: records,
          selected: selected,
          onToothTap: onToothTap,
        ),
        AppSpacing.lg.verticalSpace,
        const TeethLegend(),
      ],
    );
  }
}
```

- [ ] **Step 4 : ajouter la route**

Dans `lib/app/router/app_router.dart` :

1. Ajouter l'import `import 'package:colette/features/teeth/presentation/pages/teeth_page.dart';` (ordre alphabétique des imports).
2. Dans `AppRoutes`, après `static const health = '/health';` :

```dart
  /// Onglet Santé.
  static const health = '/health';

  /// Page Dents, imbriquée sous Santé pour garder la barre d'onglets.
  static const teeth = '/health/teeth';
```

3. Remplacer la branche Santé :

```dart
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.health,
                builder: (_, _) => const HealthPage(),
                routes: [
                  GoRoute(
                    path: 'teeth',
                    builder: (_, _) => const TeethPage(),
                  ),
                ],
              ),
            ],
          ),
```

- [ ] **Step 5 : lancer le test, il passe**

Run: `flutter test test/features/teeth/presentation/teeth_page_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6 : commit**

```bash
git add lib/features/teeth/presentation/pages/teeth_page.dart lib/app/router/app_router.dart test/features/teeth/presentation/teeth_page_test.dart
git commit -m "feat: page Dents sous l'onglet Santé" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 13 : carte « Dents » dans Santé

**Files:**
- Create: `lib/features/teeth/presentation/widgets/teeth_card.dart`
- Modify: `lib/features/health/presentation/pages/health_page.dart`
- Test: `test/features/teeth/presentation/teeth_card_test.dart`
- Modify: `test/features/health/presentation/health_page_test.dart`

- [ ] **Step 1 : écrire le test qui échoue**

`test/features/teeth/presentation/teeth_card_test.dart` :

```dart
import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/theme/theme_service.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/presentation/providers/teeth_providers.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_card.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../teeth_factories.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester,
    Stream<Map<ToothId, ToothRecord>> teeth,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.health,
      routes: [
        GoRoute(
          path: AppRoutes.health,
          builder: (_, _) => const Scaffold(body: TeethCard()),
          routes: [
            GoRoute(
              path: 'teeth',
              builder: (_, _) => const Scaffold(body: Text('page dents')),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [teethProvider.overrideWith((ref) => teeth)],
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

  testWidgets('sans dent : premières dents attendues', (tester) async {
    await pumpCard(tester, Stream.value(const {}));
    expect(find.text('Dents'), findsOneWidget);
    expect(find.text('Pas encore de dent'), findsOneWidget);
    expect(
      find.text(
        'Ensuite : incisives centrales du bas (6-10 mois), '
        'puis incisives centrales du haut (8-12 mois)',
      ),
      findsOneWidget,
    );
  });

  testWidgets('avec des dents : nombre en bouche', (tester) async {
    final day = DateTime(2027, 1, 10, 12);
    await pumpCard(
      tester,
      Stream.value({
        tooth(71): makeTooth(71, eruptedAt: day),
        tooth(81): makeTooth(81, eruptedAt: day),
      }),
    );
    expect(find.text('2 dents en bouche'), findsOneWidget);
    expect(
      find.text(
        'Ensuite : incisives centrales du haut (8-12 mois), '
        'puis incisives latérales du haut (9-13 mois)',
      ),
      findsOneWidget,
    );
  });

  testWidgets('erreur de lecture affichée', (tester) async {
    await pumpCard(tester, Stream.error(const NetworkFailure()));
    final s = S.of(tester.element(find.byType(TeethCard)));
    expect(find.text(s.errorNetwork), findsOneWidget);
  });

  testWidgets('ouvre la page Dents', (tester) async {
    await pumpCard(tester, Stream.value(const {}));
    await tester.tap(find.text('Dents'));
    await tester.pumpAndSettle();
    expect(find.text('page dents'), findsOneWidget);
  });
}
```

- [ ] **Step 2 : lancer le test, il échoue**

Run: `flutter test test/features/teeth/presentation/teeth_card_test.dart`
Expected: FAIL, `teeth_card.dart` introuvable.

- [ ] **Step 3 : implémenter la carte**

`lib/features/teeth/presentation/widgets/teeth_card.dart` :

```dart
import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/teeth/presentation/providers/teeth_providers.dart';
import 'package:colette/features/teeth/presentation/teeth_ui.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Carte « Dents » de l'onglet Santé : dents en bouche et prochaines attendues.
class TeethCard extends ConsumerWidget {
  const TeethCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    final teeth = ref.watch(teethProvider);
    final summary = ref.watch(teethSummaryProvider);
    final lines = switch ((teeth, summary)) {
      (AsyncError(:final error), _) => [failureMessage(error, s)],
      (_, final loaded?) => [
        loaded.inMouth == 0 ? s.teethNone : s.teethInMouth(loaded.inMouth),
        ?teethNextLabel(loaded.next, s),
      ],
      _ => const <String>[],
    };
    return Padding(
      padding: AppSpacing.md.top,
      child: ColetteCardSurface(
        onTap: () => context.push(AppRoutes.teeth),
        child: Row(
          spacing: AppSpacing.md.value,
          children: [
            Icon(Icons.mood, color: context.appColor(AppColors.primary)),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                spacing: AppSpacing.xxs.value,
                children: [
                  Text(s.teethTitle, style: styles.bodyMedium),
                  for (final line in lines)
                    Text(line, style: styles.small.copyWith(color: secondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: secondary),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4 : lancer le test, il passe**

Run: `flutter test test/features/teeth/presentation/teeth_card_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5 : insérer la carte dans Santé (test d'abord)**

Dans `test/features/health/presentation/health_page_test.dart` :

1. Ajouter l'import `import 'package:colette/features/teeth/presentation/providers/teeth_providers.dart';`.
2. Dans `pumpPage`, liste `overrides`, après `medicalTimelineProvider.overrideWithValue(timeline),` :

```dart
        teethProvider.overrideWith((ref) => Stream.value(const {})),
```

3. Ajouter ce test à la fin de `main()` :

```dart
  testWidgets('la carte Dents suit le prochain rendez-vous', (tester) async {
    await pumpPage(tester, timeline: fullTimeline);
    expect(find.text('Dents'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Prochain rendez-vous')).dy,
      lessThan(tester.getTopLeft(find.text('Dents')).dy),
    );
  });
```

Run: `flutter test test/features/health/presentation/health_page_test.dart`
Expected: FAIL sur le nouveau test (« Dents » introuvable), les autres passent.

Dans `lib/features/health/presentation/pages/health_page.dart` :

1. Ajouter l'import `import 'package:colette/features/teeth/presentation/widgets/teeth_card.dart';`.
2. Dans la liste de la `ListView`, après `const NextAppointmentCard(),` :

```dart
          const NextAppointmentCard(),
          const TeethCard(),
```

3. Compléter le commentaire de classe : `/// Page Santé : prochain RDV en évidence, carte Dents, autres RDV programmés, RDV passés`.

Run: `flutter test test/features/health/presentation/`
Expected: PASS (tous les tests Santé, y compris l'ordre des blocs existant).

- [ ] **Step 6 : commit**

```bash
git add lib/features/teeth/presentation/widgets/teeth_card.dart lib/features/health/presentation/pages/health_page.dart test/features/teeth/presentation/teeth_card_test.dart test/features/health/presentation/health_page_test.dart
git commit -m "feat: carte Dents dans l'onglet Santé" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 14 : thèmes clair et sombre, vérification finale

**Files:**
- Test: `test/features/teeth/presentation/teeth_theme_test.dart`

- [ ] **Step 1 : écrire le test**

`test/features/teeth/presentation/teeth_theme_test.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/theme_service.dart';
import 'package:colette/features/teeth/presentation/pages/teeth_page.dart';
import 'package:colette/features/teeth/presentation/providers/teeth_providers.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_card.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_chart.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_chart_painter.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../teeth_factories.dart';

void main() {
  Future<void> pumpThemed(
    WidgetTester tester,
    Widget child,
    ThemeMode mode,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const themeService = ThemeService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teethProvider.overrideWith(
            (ref) => Stream.value({
              tooth(71): makeTooth(71, eruptedAt: DateTime(2027, 1, 10, 12)),
              tooth(81): makeTooth(
                81,
                eruptedAt: DateTime(2027, 1, 10, 12),
                lostAt: DateTime(2027, 2, 1, 12),
              ),
            }),
          ),
          clockProvider.overrideWithValue(
            FixedClock(DateTime(2027, 3, 10, 9)),
          ),
        ],
        child: MaterialApp(
          theme: themeService.light(),
          darkTheme: themeService.dark(),
          themeMode: mode,
          locale: const Locale('fr'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  TeethChartPainter painter(WidgetTester tester) =>
      tester.widget<CustomPaint>(find.byKey(TeethChart.canvasKey)).painter!
          as TeethChartPainter;

  testWidgets('page Dents : aucune exception, couleurs au thème', (
    tester,
  ) async {
    await pumpThemed(tester, const TeethPage(), ThemeMode.light);
    expect(tester.takeException(), isNull);
    expect(painter(tester).colors.erupted, AppColors.primary.light);

    await pumpThemed(tester, const TeethPage(), ThemeMode.dark);
    expect(tester.takeException(), isNull);
    expect(painter(tester).colors.erupted, AppColors.primary.dark);
  });

  testWidgets('carte Dents : aucune exception en clair et en sombre', (
    tester,
  ) async {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      await pumpThemed(tester, const Scaffold(body: TeethCard()), mode);
      expect(tester.takeException(), isNull);
    }
  });
}
```

- [ ] **Step 2 : lancer le test**

Run: `flutter test test/features/teeth/presentation/teeth_theme_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 3 : commit**

```bash
git add test/features/teeth/presentation/teeth_theme_test.dart
git commit -m "test: dents en thème clair et sombre" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 4 : vérification complète**

Run, dans l'ordre :

```bash
dart format lib test
dart analyze
flutter test
```

Expected : `dart format` ne modifie rien (sinon committer `chore: format`), `dart analyze` affiche « No issues found! » (plugin `riverpod_lint` compris), `flutter test` tout vert.

- [ ] **Step 5 : vérification sur simulateur iPhone**

Lancer l'app sur un simulateur iPhone (skill `run` ou outil simulateur iOS). Ne pas créer de foyer de test dans le Firestore de production sans accord de Maxence : vérifier avec le foyer existant du simulateur, ou s'arrêter aux tests si aucun foyer n'est configuré et le signaler. Contrôler, en clair puis en sombre :

- la carte « Dents » sous « Prochain rendez-vous » dans Santé ;
- la page : bascule « De lait » / « Définitives », dents faciles à toucher (incisives définitives comprises), fiche qui s'ouvre sur la bonne dent, contour de sélection ;
- la fiche : dates, retrait d'une date, note, clavier qui ne masque pas « Enregistrer » ;
- VoiceOver (Accessibility Inspector) : une dent annonce son nom et son état.

- [ ] **Step 6 : fin de branche**

Utiliser `superpowers:finishing-a-development-branch`. Rappel des règles du projet : merge `--no-ff` sur `main` avec le message `merge: suivi des dents (feat/teeth-tracking)`, **seulement après validation explicite de Maxence**, sans push implicite. Avant le merge : `git fetch`, comparer `main...origin/main`, simuler les conflits (`git merge-tree --write-tree main feat/teeth-tracking`). Après le merge : `flutter gen-l10n`, `dart analyze`, `flutter test` sur `main`.
