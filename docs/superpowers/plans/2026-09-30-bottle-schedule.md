# Horaires et intervalle des biberons — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal :** remplacer la fourchette codée en dur (2 h 30 – 5 h) par trois réglages du foyer (premier biberon, biberon du soir, intervalle) qui pilotent le prochain biberon, la projection 24 h et le nombre de biberons par jour.

**Architecture :** un value object pur `BottleSchedule` (`baby/domain`) porte la règle (`nextAfter`, `windowAround`, `feedsPerDay`). `CareSettings` stocke trois entiers en minutes et expose `bottleSchedule`. `ComputeFeedingPlan` et `ProjectBottleSchedule` reçoivent ce `BottleSchedule` à la place de `feedsPerDay`. Une nouvelle carte Réglages édite les trois valeurs. Cloud Functions : rappel de secours du matin ajouté en Task 10 (redéploiement après accord).

**Tech stack :** Flutter, Dart 3, freezed, Riverpod 3 codegen, fake_cloud_firestore, mocktail.

**Spec :** `docs/superpowers/specs/2026-09-30-bottle-schedule-design.md`

**Worktree :** `/Users/maxencemontet/Documents/colette/.claude/worktrees/bottle-schedule`, branche `feat/bottle-schedule`. Toutes les commandes s'exécutent depuis ce dossier. Ne jamais toucher au checkout principal, ne jamais `git stash` nu. Commits par `git add` de fichiers ciblés, message en français, terminé par la ligne `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

---

## Fichiers

| Fichier | Rôle |
|---|---|
| Create `lib/features/baby/domain/entities/bottle_schedule.dart` | Règle pure : prochain biberon, fourchette, nombre par jour |
| Create `test/features/baby/domain/bottle_schedule_test.dart` | Tests de la règle |
| Modify `lib/features/baby/domain/entities/care_settings.dart` | 3 champs minutes, bornes, getter `bottleSchedule` ; retrait de `feedsPerDay` (Task 4) |
| Modify `lib/features/baby/data/dtos/baby_profile_dto.dart` | Lecture/écriture des 3 champs ; `feedsPerDay` ni écrit ni lu |
| Modify `lib/features/dashboard/domain/use_cases/compute_feeding_plan.dart` | `schedule` remplace `feedsPerDay` ; suppression `intervalFor`/`minGap`/`maxGap`/`windowAfter` |
| Modify `lib/features/dashboard/domain/use_cases/project_bottle_schedule.dart` | Enchaîne `schedule.nextAfter` |
| Modify `lib/features/dashboard/presentation/providers/dashboard_providers.dart` | Passe `careSettings.bottleSchedule` |
| Modify `lib/features/dashboard/presentation/providers/feeding_plan_sync.dart` | Idem |
| Modify `lib/shared/ui/widgets/int_stepper_row.dart` | Paramètre `format` |
| Create `lib/features/baby/presentation/widgets/bottle_schedule_settings_section.dart` | Carte « Biberons » |
| Modify `lib/features/baby/presentation/widgets/care_settings_section.dart` | Retrait du stepper « Biberons par jour » |
| Modify `lib/features/baby/presentation/pages/settings_page.dart` | Ajout de la section |
| Modify `lib/l10n/app_fr.arb` | 5 clés ajoutées, `settingsFeedsPerDay` retirée |
| Tests modifiés | `compute_feeding_plan_test`, `project_bottle_schedule_test`, `compute_feeding_reference_test`, `feeding_plan_sync_test`, `baby_profile_dto_test`, `baby_settings_controller_test`, `care_settings_section_test`, `int_stepper_row_test` |

---

### Task 0 : préparer le worktree

- [ ] **Step 1 : dépendances et fichiers générés**

`lib/l10n/generated/` n'est pas versionné ; les `.g.dart` / `.freezed.dart` le sont.

```bash
flutter pub get && flutter gen-l10n && dart run build_runner build -d
```

- [ ] **Step 2 : suite de référence**

```bash
flutter test
```

Attendu : tout vert. Si un test échoue déjà sur `main`, le noter et prévenir avant d'aller plus loin.

---

### Task 1 : value object `BottleSchedule`

**Files :**
- Create : `lib/features/baby/domain/entities/bottle_schedule.dart`
- Test : `test/features/baby/domain/bottle_schedule_test.dart`

- [ ] **Step 1 : écrire le test (rouge)**

```dart
import 'package:colette/features/baby/domain/entities/bottle_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Défauts : premier biberon 7 h, biberon du soir 23 h 30, toutes les 3 h.
  const schedule = BottleSchedule();

  group('nextAfter', () {
    DateTime next(int day, int hour, [int minute = 0]) =>
        schedule.nextAfter(DateTime(2026, 9, day, hour, minute));

    test('journée : dernier biberon + intervalle', () {
      expect(next(10, 10), DateTime(2026, 9, 10, 13));
    });

    test('journée : rabattu sur le biberon du soir', () {
      expect(next(10, 22), DateTime(2026, 9, 10, 23, 30));
      expect(next(10, 22, 45), DateTime(2026, 9, 10, 23, 30));
    });

    test('biberon du soir : le suivant est le premier du matin', () {
      expect(next(10, 23), DateTime(2026, 9, 11, 7));
      expect(next(10, 23, 10), DateTime(2026, 9, 11, 7));
      expect(next(10, 23, 30), DateTime(2026, 9, 11, 7));
    });

    test('nuit après minuit : premier du matin le jour même', () {
      expect(next(11, 0, 30), DateTime(2026, 9, 11, 7));
    });

    test('nuit : garde dernier + intervalle s\'il dépasse le matin', () {
      expect(next(11, 5), DateTime(2026, 9, 11, 8));
      expect(next(11, 6), DateTime(2026, 9, 11, 9));
    });

    test('dès 30 min avant le premier biberon, c\'est la journée', () {
      expect(next(11, 6, 30), DateTime(2026, 9, 11, 9, 30));
      expect(next(11, 6, 40), DateTime(2026, 9, 11, 9, 40));
    });

    test('réglages personnalisés', () {
      const custom = BottleSchedule(
        firstBottle: Duration(hours: 6, minutes: 30),
        lastBottle: Duration(hours: 22),
        interval: Duration(hours: 2, minutes: 45),
      );
      expect(
        custom.nextAfter(DateTime(2026, 9, 10, 18)),
        DateTime(2026, 9, 10, 20, 45),
      );
      expect(
        custom.nextAfter(DateTime(2026, 9, 10, 20, 45)),
        DateTime(2026, 9, 10, 22),
      );
      expect(
        custom.nextAfter(DateTime(2026, 9, 10, 22)),
        DateTime(2026, 9, 11, 6, 30),
      );
    });

    test('toujours strictement après le dernier biberon', () {
      for (var minutes = 0; minutes < 24 * 60; minutes += 5) {
        final last = DateTime(2026, 9, 10, 0, minutes);
        expect(schedule.nextAfter(last).isAfter(last), isTrue, reason: '$last');
      }
    });
  });

  test('windowAround : de 30 min avant à 30 min après', () {
    expect(schedule.windowAround(DateTime(2026, 9, 11, 7)), (
      DateTime(2026, 9, 11, 6, 30),
      DateTime(2026, 9, 11, 7, 30),
    ));
  });

  group('feedsPerDay', () {
    test('7 h → 23 h 30 toutes les 3 h : 7', () {
      expect(schedule.feedsPerDay, 7);
    });

    test('intervalle qui divise exactement la plage', () {
      const exact = BottleSchedule(
        firstBottle: Duration(hours: 6, minutes: 30),
        lastBottle: Duration(hours: 23, minutes: 30),
        interval: Duration(hours: 2, minutes: 50),
      );
      expect(exact.feedsPerDay, 7);
    });

    test('7 h → 22 h toutes les 5 h : 4', () {
      const sparse = BottleSchedule(
        lastBottle: Duration(hours: 22),
        interval: Duration(hours: 5),
      );
      expect(sparse.feedsPerDay, 4);
    });

    test('plage vide : au moins 1', () {
      const empty = BottleSchedule(
        firstBottle: Duration(hours: 10),
        lastBottle: Duration(hours: 8),
      );
      expect(empty.feedsPerDay, 1);
    });
  });
}
```

- [ ] **Step 2 : vérifier l'échec**

```bash
flutter test test/features/baby/domain/bottle_schedule_test.dart
```

Attendu : échec de compilation, `bottle_schedule.dart` introuvable.

- [ ] **Step 3 : implémentation**

`lib/features/baby/domain/entities/bottle_schedule.dart` :

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'bottle_schedule.freezed.dart';

/// Rythme des biberons : premier du matin, biberon du soir et intervalle.
@freezed
abstract class BottleSchedule with _$BottleSchedule {
  const BottleSchedule._();

  const factory BottleSchedule({
    /// Heure du premier biberon, depuis minuit.
    @Default(Duration(hours: 7)) Duration firstBottle,

    /// Heure du biberon du soir, depuis minuit ; rien n'est prévu après.
    @Default(Duration(hours: 23, minutes: 30)) Duration lastBottle,

    /// Temps entre deux biberons de journée.
    @Default(Duration(hours: 3)) Duration interval,
  }) = _BottleSchedule;

  /// Demi-largeur de la fourchette autour de l'heure prévue.
  static const halfWindow = Duration(minutes: 30);

  /// Heure prévue du biberon qui suit celui donné à [last].
  ///
  /// Biberon de journée (dès 30 min avant le premier, jusqu'à 30 min avant
  /// celui du soir) : `last + interval`, rabattu sur le biberon du soir.
  /// Biberon du soir ou de nuit : premier biberon du matin suivant, ou
  /// `last + interval` s'il tombe plus tard.
  DateTime nextAfter(DateTime last) {
    final planned = last.add(interval);
    final day = DateTime(last.year, last.month, last.day);
    final morning = _at(day, firstBottle);
    final evening = _at(day, lastBottle);
    final isDaytime =
        !last.isBefore(morning.subtract(halfWindow)) &&
        last.isBefore(evening.subtract(halfWindow));
    if (isDaytime) return planned.isAfter(evening) ? evening : planned;
    final nextMorning = morning.isAfter(last)
        ? morning
        : _at(DateTime(day.year, day.month, day.day + 1), firstBottle);
    return planned.isAfter(nextMorning) ? planned : nextMorning;
  }

  /// Fourchette de 30 min avant à 30 min après [at].
  (DateTime, DateTime) windowAround(DateTime at) =>
      (at.subtract(halfWindow), at.add(halfWindow));

  /// Biberons de journée du premier au soir ; au moins 1.
  int get feedsPerDay {
    final span = lastBottle - firstBottle;
    if (span <= Duration.zero || interval <= Duration.zero) return 1;
    return 1 + (span.inMinutes / interval.inMinutes).ceil();
  }

  /// [day] (à minuit) décalé de [time], en heure locale.
  static DateTime _at(DateTime day, Duration time) =>
      DateTime(day.year, day.month, day.day, 0, time.inMinutes);
}
```

```bash
dart run build_runner build -d
```

- [ ] **Step 4 : vérifier le succès**

```bash
flutter test test/features/baby/domain/bottle_schedule_test.dart
```

Attendu : tous les tests passent.

- [ ] **Step 5 : commit**

```bash
git add lib/features/baby/domain/entities/bottle_schedule.dart lib/features/baby/domain/entities/bottle_schedule.freezed.dart test/features/baby/domain/bottle_schedule_test.dart
git commit -m "feat: règle du prochain biberon selon les horaires du foyer

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2 : horaires dans `CareSettings` et le DTO

`feedsPerDay` reste pour l'instant (retiré en Task 4) afin que tout compile à chaque commit.

**Files :**
- Modify : `lib/features/baby/domain/entities/care_settings.dart`
- Modify : `lib/features/baby/data/dtos/baby_profile_dto.dart` (`CareSettingsDto.toMap` et `fromMap`)
- Test : `test/features/baby/data/baby_profile_dto_test.dart`

- [ ] **Step 1 : écrire le test (rouge)**

Ajouter à la fin de `main()` dans `baby_profile_dto_test.dart` (import `bottle_schedule.dart` en tête) :

```dart
  group('horaires des biberons', () {
    test('défauts sur document vide : 7 h, 23 h 30, 3 h', () {
      final settings = CareSettingsDto.fromMap(const {});
      expect(settings.firstBottleMinutes, 420);
      expect(settings.lastBottleMinutes, 1410);
      expect(settings.bottleIntervalMinutes, 180);
      expect(settings.bottleSchedule, const BottleSchedule());
    });

    test('aller-retour', () {
      const settings = CareSettings(
        firstBottleMinutes: 390,
        lastBottleMinutes: 1380,
        bottleIntervalMinutes: 165,
      );
      final map = CareSettingsDto.toMap(settings);
      expect(map['firstBottleMinutes'], 390);
      expect(map['lastBottleMinutes'], 1380);
      expect(map['bottleIntervalMinutes'], 165);
      expect(CareSettingsDto.fromMap(map), settings);
    });

    test('valeurs hors bornes ramenées aux bornes', () {
      final low = CareSettingsDto.fromMap(const {
        'firstBottleMinutes': 0,
        'lastBottleMinutes': 0,
        'bottleIntervalMinutes': 10,
      });
      expect(low.firstBottleMinutes, CareSettings.minFirstBottleMinutes);
      expect(low.lastBottleMinutes, CareSettings.minLastBottleMinutes);
      expect(low.bottleIntervalMinutes, CareSettings.minBottleIntervalMinutes);
      final high = CareSettingsDto.fromMap(const {
        'firstBottleMinutes': 5000,
        'lastBottleMinutes': 5000,
        'bottleIntervalMinutes': 5000,
      });
      expect(high.firstBottleMinutes, CareSettings.maxFirstBottleMinutes);
      expect(high.lastBottleMinutes, CareSettings.maxLastBottleMinutes);
      expect(high.bottleIntervalMinutes, CareSettings.maxBottleIntervalMinutes);
    });

    test('bottleSchedule reprend les trois réglages', () {
      const settings = CareSettings(
        firstBottleMinutes: 390,
        lastBottleMinutes: 1380,
        bottleIntervalMinutes: 165,
      );
      expect(
        settings.bottleSchedule,
        const BottleSchedule(
          firstBottle: Duration(hours: 6, minutes: 30),
          lastBottle: Duration(hours: 23),
          interval: Duration(hours: 2, minutes: 45),
        ),
      );
    });
  });
```

- [ ] **Step 2 : vérifier l'échec**

```bash
flutter test test/features/baby/data/baby_profile_dto_test.dart
```

Attendu : échec de compilation (`firstBottleMinutes` inconnu).

- [ ] **Step 3 : implémentation**

Dans `care_settings.dart`, importer `package:colette/features/baby/domain/entities/bottle_schedule.dart`, ajouter les champs après `dailyTargetMl` :

```dart
    /// Cible journalière forcée en ml ; `null` = calcul OMS.
    int? dailyTargetMl,

    /// Heure du premier biberon, en minutes depuis minuit.
    @Default(420) int firstBottleMinutes,

    /// Heure du biberon du soir, en minutes depuis minuit.
    @Default(1410) int lastBottleMinutes,

    /// Intervalle entre deux biberons, en minutes.
    @Default(180) int bottleIntervalMinutes,
  }) = _CareSettings;
```

puis, sous `dailyTargetStepMl` :

```dart
  static const bottleTimeStepMinutes = 15;
  static const minFirstBottleMinutes = 4 * 60;
  static const maxFirstBottleMinutes = 10 * 60;
  static const minLastBottleMinutes = 20 * 60;
  static const maxLastBottleMinutes = 23 * 60 + 45;
  static const minBottleIntervalMinutes = 90;
  static const maxBottleIntervalMinutes = 5 * 60;

  /// Rythme des biberons tiré des trois réglages.
  BottleSchedule get bottleSchedule => BottleSchedule(
    firstBottle: Duration(minutes: firstBottleMinutes),
    lastBottle: Duration(minutes: lastBottleMinutes),
    interval: Duration(minutes: bottleIntervalMinutes),
  );
```

Mettre à jour le commentaire de classe : `/// Fréquences des soins attendus, cible de lait, horaires des biberons et de nuit.`

Dans `CareSettingsDto.toMap`, après `'dailyTargetMl': …` :

```dart
    'firstBottleMinutes': settings.firstBottleMinutes,
    'lastBottleMinutes': settings.lastBottleMinutes,
    'bottleIntervalMinutes': settings.bottleIntervalMinutes,
```

Dans `CareSettingsDto.fromMap`, après `dailyTargetMl: _readOptionalInt(…),` :

```dart
      firstBottleMinutes: _readBoundedInt(
        map,
        'firstBottleMinutes',
        420,
        min: CareSettings.minFirstBottleMinutes,
        max: CareSettings.maxFirstBottleMinutes,
      ),
      lastBottleMinutes: _readBoundedInt(
        map,
        'lastBottleMinutes',
        1410,
        min: CareSettings.minLastBottleMinutes,
        max: CareSettings.maxLastBottleMinutes,
      ),
      bottleIntervalMinutes: _readBoundedInt(
        map,
        'bottleIntervalMinutes',
        180,
        min: CareSettings.minBottleIntervalMinutes,
        max: CareSettings.maxBottleIntervalMinutes,
      ),
```

```bash
dart run build_runner build -d
```

- [ ] **Step 4 : vérifier le succès**

```bash
flutter test test/features/baby/
```

Attendu : tout vert.

- [ ] **Step 5 : commit**

```bash
git add lib/features/baby/domain/entities/care_settings.dart lib/features/baby/domain/entities/care_settings.freezed.dart lib/features/baby/data/dtos/baby_profile_dto.dart test/features/baby/data/baby_profile_dto_test.dart
git commit -m "feat: horaires des biberons dans les réglages de soins du foyer

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3 : plan du jour et projection sur `BottleSchedule`

**Files :**
- Modify : `lib/features/dashboard/domain/use_cases/compute_feeding_plan.dart`
- Modify : `lib/features/dashboard/domain/use_cases/project_bottle_schedule.dart`
- Modify : `lib/features/dashboard/presentation/providers/dashboard_providers.dart`
- Modify : `lib/features/dashboard/presentation/providers/feeding_plan_sync.dart`
- Test : `test/features/dashboard/domain/compute_feeding_plan_test.dart`, `test/features/dashboard/domain/project_bottle_schedule_test.dart`, `test/features/dashboard/domain/compute_feeding_reference_test.dart`, `test/features/dashboard/presentation/feeding_plan_sync_test.dart`

Rythme par défaut dans tous ces tests : 7 h / 23 h 30 / 3 h, soit **7 biberons par jour**.

- [ ] **Step 1 : réécrire `compute_feeding_plan_test.dart` (rouge)**

Ajouter l'import `package:colette/features/baby/domain/entities/bottle_schedule.dart`. Déclarer sous `birth` :

```dart
  const schedule = BottleSchedule();
  // 7 h → 22 h toutes les 5 h : 4 biberons par jour.
  const fourFeeds = BottleSchedule(
    lastBottle: Duration(hours: 22),
    interval: Duration(hours: 5),
  );
```

Dans **chaque** appel `compute(…)`, remplacer `feedsPerDay: 8,` par `schedule: schedule,` et `feedsPerDay: 4,` par `schedule: fourFeeds,`. Le groupe « règles OMS » ne change pas. Remplacer ensuite les tests suivants tels quels.

Premier test :

```dart
  test(
    'jour 10, 3 600 g, 2 biberons de 60 : cible 540, reste 420 sur 5 prises',
    () {
      final now = DateTime(2026, 9, 10, 12);
      final bottles = [
        makeEvent(id: 'a', startAt: DateTime(2026, 9, 10, 6), bottleMl: 60),
        makeEvent(id: 'b', startAt: DateTime(2026, 9, 10, 9), bottleMl: 60),
      ];
      final plan = compute(
        birthDate: birth,
        latestWeightGrams: 3600,
        schedule: schedule,
        todayBottles: bottles,
        lastBottle: bottles.last,
        now: now,
      );
      expect(plan.dailyTargetMl, 540);
      expect(plan.isEstimatedFromAge, isFalse);
      expect(plan.feedsPerDay, 7);
      expect(plan.bottlesGiven, 2);
      expect(plan.bottlesRemaining, 5);
      expect(plan.givenMl, 120);
      expect(plan.remainingMl, 420);
      // 420 / 5 = 84 → 80.
      expect(plan.suggestedMl, 80);
      expect(plan.nextBottleAt, DateTime(2026, 9, 10, 12));
      expect(plan.lateBy(now), Duration.zero);
    },
  );
```

« sans pesée » : la suggestion devient `70` (480 / 7 = 68,6 → 70).

« le retard est compté depuis la fin de la fourchette » :

```dart
  test('le retard est compté depuis la fin de la fourchette', () {
    // 6 h est un biberon de nuit : matin 7 h, mais 6 h + 3 h = 9 h plus tard.
    final last = makeEvent(
      id: 'a',
      startAt: DateTime(2026, 9, 10, 6),
      bottleMl: 90,
    );
    final plan = compute(
      birthDate: birth,
      latestWeightGrams: 3600,
      schedule: schedule,
      todayBottles: [last],
      lastBottle: last,
      now: DateTime(2026, 9, 10, 10),
    );
    expect(plan.nextBottleAt, DateTime(2026, 9, 10, 9));
    expect(plan.windowEnd, DateTime(2026, 9, 10, 9, 30));
    expect(plan.hasWindow, isTrue);
    expect(plan.lateBy(DateTime(2026, 9, 10, 9, 30)), Duration.zero);
    expect(
      plan.lateBy(DateTime(2026, 9, 10, 10, 5)),
      const Duration(minutes: 35),
    );
  });
```

Groupe « fourchette », remplacer les deux premiers tests (le troisième, « sans biberon », prend seulement `schedule: schedule`) :

```dart
  group('fourchette', () {
    (DateTime, DateTime) windowFor(DateTime last) {
      final bottle = makeEvent(id: 'a', startAt: last, bottleMl: 60);
      final plan = compute(
        birthDate: birth,
        latestWeightGrams: 3600,
        schedule: schedule,
        todayBottles: [bottle],
        lastBottle: bottle,
        now: last,
      );
      return (plan.windowStart, plan.windowEnd);
    }

    test('de 30 min avant à 30 min après l\'heure prévue', () {
      expect(windowFor(DateTime(2026, 9, 10, 10)), (
        DateTime(2026, 9, 10, 12, 30),
        DateTime(2026, 9, 10, 13, 30),
      ));
    });

    test('biberon de 22 h : fourchette du soir autour de 23 h 30', () {
      expect(windowFor(DateTime(2026, 9, 10, 22)), (
        DateTime(2026, 9, 10, 23),
        DateTime(2026, 9, 11, 0),
      ));
    });

    test('biberon du soir : fourchette du matin, 6 h 30 – 7 h 30', () {
      expect(windowFor(DateTime(2026, 9, 10, 23, 10)), (
        DateTime(2026, 9, 11, 6, 30),
        DateTime(2026, 9, 11, 7, 30),
      ));
    });

    test('ouverte 30 min avant l\'heure prévue, fermée 30 min après', () {
      final last = makeEvent(
        id: 'a',
        startAt: DateTime(2026, 9, 10, 10),
        bottleMl: 60,
      );
      FeedingPlan at(DateTime now) => compute(
        birthDate: birth,
        latestWeightGrams: 3600,
        schedule: schedule,
        todayBottles: [last],
        lastBottle: last,
        now: now,
      );
      expect(
        at(DateTime(2026, 9, 10, 12, 29)).isOpen(DateTime(2026, 9, 10, 12, 29)),
        isFalse,
      );
      expect(
        at(DateTime(2026, 9, 10, 12, 30)).isOpen(DateTime(2026, 9, 10, 12, 30)),
        isTrue,
      );
      expect(
        at(DateTime(2026, 9, 10, 13, 30)).isOpen(DateTime(2026, 9, 10, 13, 30)),
        isTrue,
      );
      expect(
        at(DateTime(2026, 9, 10, 13, 31)).isOpen(DateTime(2026, 9, 10, 13, 31)),
        isFalse,
      );
    });
```

« toutes les prises données » :

```dart
  test('toutes les prises données : suggestion = cible / prises', () {
    final bottles = List.generate(
      7,
      (i) => makeEvent(
        id: '$i',
        startAt: DateTime(2026, 9, 10, i * 2),
        bottleMl: 60,
      ),
    );
    final plan = compute(
      birthDate: birth,
      latestWeightGrams: 3600,
      schedule: schedule,
      todayBottles: bottles,
      lastBottle: bottles.last,
      now: DateTime(2026, 9, 10, 16),
    );
    expect(plan.bottlesRemaining, 0);
    // 540 / 7 = 77,1 → 80.
    expect(plan.suggestedMl, 80);
  });
```

Supprimer le test « feedsPerDay à 0 est traité comme 1 sans planter » (le minimum de 1 est couvert par `bottle_schedule_test`).

Groupe « cible ajustée », premier test : commentaire et valeur deviennent

```dart
      expect(plan.remainingMl, 540);
      // 540 / 6 = 90.
      expect(plan.suggestedMl, 90);
```

« la suggestion est bornée entre 30 et 240 ml » et « override très haut » utilisent `schedule: fourFeeds` (valeurs attendues inchangées).

- [ ] **Step 2 : réécrire `project_bottle_schedule_test.dart` (rouge)**

Contenu complet :

```dart
import 'package:colette/features/baby/domain/entities/bottle_schedule.dart';
import 'package:colette/features/dashboard/domain/entities/feeding_plan.dart';
import 'package:colette/features/dashboard/domain/entities/projected_bottle.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_feeding_plan.dart';
import 'package:colette/features/dashboard/domain/use_cases/project_bottle_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/care_event_factory.dart';

void main() {
  const project = ProjectBottleSchedule();
  // 7 h / 23 h 30 / 3 h : 7 biberons par jour.
  const schedule = BottleSchedule();
  // Jour 3 le 10 septembre (100 ml/kg), jour 4 le 11 (120 ml/kg).
  final birth = DateTime(2026, 9, 8);

  FeedingPlan planFor({
    required DateTime now,
    DateTime? lastAt,
    int? override,
  }) {
    final last = lastAt == null
        ? null
        : makeEvent(id: 'b', startAt: lastAt, bottleMl: 60);
    return const ComputeFeedingPlan()(
      birthDate: birth,
      latestWeightGrams: 3600,
      schedule: schedule,
      todayBottles: [?last],
      lastBottle: last,
      now: now,
      dailyTargetMlOverride: override,
    );
  }

  List<ProjectedBottle> projectFor(FeedingPlan plan, DateTime now) => project(
    plan: plan,
    schedule: schedule,
    birthDate: birth,
    latestWeightGrams: 3600,
    now: now,
  );

  List<DateTime> times(List<ProjectedBottle> bottles) => [
    for (final b in bottles) b.at,
  ];

  test('suit l\'intervalle, le biberon du soir puis le matin, sur 24 h', () {
    final now = DateTime(2026, 9, 10, 10);
    final bottles = projectFor(
      planFor(now: now, lastAt: DateTime(2026, 9, 10, 9)),
      now,
    );
    expect(times(bottles), [
      DateTime(2026, 9, 10, 12),
      DateTime(2026, 9, 10, 15),
      DateTime(2026, 9, 10, 18),
      DateTime(2026, 9, 10, 21),
      DateTime(2026, 9, 10, 23, 30),
      DateTime(2026, 9, 11, 7),
    ]);
    for (final b in bottles) {
      expect(b.windowStart, b.at.subtract(BottleSchedule.halfWindow));
      expect(b.windowEnd, b.at.add(BottleSchedule.halfWindow));
    }
    // Aujourd'hui : (360 − 60) / 6 = 50. Demain : 430 / 7 = 61,4 → 60.
    expect(bottles.take(5).map((b) => b.suggestedMl), everyElement(50));
    expect(bottles.last.suggestedMl, 60);
  });

  test('journée type après le biberon du soir', () {
    final now = DateTime(2026, 9, 10, 6, 50);
    final bottles = projectFor(
      planFor(now: now, lastAt: DateTime(2026, 9, 9, 23, 30)),
      now,
    );
    expect(times(bottles), [
      DateTime(2026, 9, 10, 7),
      DateTime(2026, 9, 10, 10),
      DateTime(2026, 9, 10, 13),
      DateTime(2026, 9, 10, 16),
      DateTime(2026, 9, 10, 19),
      DateTime(2026, 9, 10, 22),
      DateTime(2026, 9, 10, 23, 30),
    ]);
  });

  test('fourchette ouverte : la suite part de maintenant', () {
    final now = DateTime(2026, 9, 10, 10, 15);
    final bottles = projectFor(
      planFor(now: now, lastAt: DateTime(2026, 9, 10, 7)),
      now,
    );
    expect(bottles.first.at, DateTime(2026, 9, 10, 10));
    expect(bottles[1].at, DateTime(2026, 9, 10, 13, 15));
    expect(bottles[1].windowStart, DateTime(2026, 9, 10, 12, 45));
    expect(bottles[1].windowEnd, DateTime(2026, 9, 10, 13, 45));
  });

  test('en retard : la suite part de maintenant', () {
    final now = DateTime(2026, 9, 10, 10);
    final bottles = projectFor(
      planFor(now: now, lastAt: DateTime(2026, 9, 10, 4)),
      now,
    );
    expect(bottles.first.at, DateTime(2026, 9, 10, 7));
    expect(bottles.first.windowEnd, DateTime(2026, 9, 10, 7, 30));
    expect(bottles[1].at, DateTime(2026, 9, 10, 13));
    expect(bottles.last.at, DateTime(2026, 9, 11, 7));
  });

  test('sans biberon : maintenant, puis selon l\'intervalle', () {
    final now = DateTime(2026, 9, 10, 10);
    final bottles = projectFor(planFor(now: now), now);
    expect(bottles.first.windowStart, now);
    expect(bottles.first.windowEnd, now);
    expect(bottles[1].at, DateTime(2026, 9, 10, 13));
    expect(bottles[1].windowStart, DateTime(2026, 9, 10, 12, 30));
    expect(bottles[1].windowEnd, DateTime(2026, 9, 10, 13, 30));
  });

  test('cible ajustée pour demain, bornée à 240 ml', () {
    final now = DateTime(2026, 9, 10, 20);
    final bottles = project(
      plan: planFor(
        now: now,
        lastAt: DateTime(2026, 9, 10, 19),
        override: 3000,
      ),
      schedule: schedule,
      birthDate: birth,
      latestWeightGrams: 3600,
      now: now,
      dailyTargetMlOverride: 3000,
    );
    expect(bottles.last.suggestedMl, ComputeFeedingPlan.maxSuggestedMl);
  });

  test('sans pesée, demain suit les repères par âge', () {
    final now = DateTime(2026, 9, 10, 20);
    final plan = const ComputeFeedingPlan()(
      birthDate: DateTime(2026, 9, 6),
      latestWeightGrams: null,
      schedule: schedule,
      todayBottles: const [],
      lastBottle: null,
      now: now,
    );
    final bottles = project(
      plan: plan,
      schedule: schedule,
      birthDate: DateTime(2026, 9, 6),
      latestWeightGrams: null,
      now: now,
    );
    // Jour 6 demain : 480 ml / 7 = 68,6 → 70.
    expect(bottles.last.suggestedMl, 70);
  });
}
```

- [ ] **Step 3 : adapter les deux autres tests**

`compute_feeding_reference_test.dart` : importer `bottle_schedule.dart`, remplacer `feedsPerDay: 8,` par `schedule: const BottleSchedule(),`.

`feeding_plan_sync_test.dart` :
- premier test : fenêtre `11 h 30 – 12 h 30` au lieu de `11 h 30 – 14 h`, et `suggestedMl` `70` au lieu de `60` (âge jour 10 : 480 ml ; (480 − 60) / 6 = 70). Renommer le test `'sync écrit nextBottleAt = dernier biberon + 3 h, sa fourchette et la suggestion'`.

```dart
      expect(
        (plan['windowEndAt'] as Timestamp).toDate(),
        DateTime(2026, 9, 10, 12, 30),
      );
      expect(plan['suggestedMl'], 70);
```

- deuxième test : commentaire et valeur

```dart
    // Sans pesée la cible OMS serait 480 (suggestion 70) ; avec 600 : (600 − 60) / 6 → 90.
    expect(plan['suggestedMl'], 90);
```

- [ ] **Step 4 : vérifier l'échec**

```bash
flutter test test/features/dashboard/
```

Attendu : échec de compilation (`schedule` paramètre inconnu).

- [ ] **Step 5 : implémentation `ComputeFeedingPlan`**

Importer `package:colette/features/baby/domain/entities/bottle_schedule.dart`. Commentaire de classe :

```dart
/// Plan biberons selon l'OMS : 150 ml/kg/jour (montée progressive la 1re semaine),
/// réparti sur les biberons du jour du [BottleSchedule] ; repères par âge sans pesée.
/// Une cible ajustée (`dailyTargetMlOverride`) remplace la cible OMS.
/// Le prochain biberon suit le rythme du foyer, fourchette de ± 30 min.
```

Signature et début de `call` :

```dart
  FeedingPlan call({
    required DateTime birthDate,
    required int? latestWeightGrams,
    required BottleSchedule schedule,
    required List<CareEvent> todayBottles,
    required CareEvent? lastBottle,
    required DateTime now,
    int? dailyTargetMlOverride,
  }) {
    final feedsPerDay = schedule.feedsPerDay;
    final day = dayOfLife(birthDate, now);
    final omsTargetMl = dailyTargetFor(
      dayOfLife: day,
      latestWeightGrams: latestWeightGrams,
    );
    final dailyTargetMl = dailyTargetMlOverride ?? omsTargetMl;
    final nextBottleAt = lastBottle == null
        ? now
        : schedule.nextAfter(lastBottle.startAt);
    final (windowStart, windowEnd) = lastBottle == null
        ? (now, now)
        : schedule.windowAround(nextBottleAt);
```

Dans le reste de `call`, remplacer `safeFeedsPerDay` par `feedsPerDay` (3 occurrences, dont `feedsPerDay: feedsPerDay` dans le constructeur). Supprimer `intervalFor`, `minGap`, `maxGap`, `windowAfter` et leurs commentaires. Retirer la ligne de doc « `feedsPerDay` est borné à 1 minimum… ».

- [ ] **Step 6 : implémentation `ProjectBottleSchedule`**

```dart
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/baby/domain/entities/bottle_schedule.dart';
import 'package:colette/features/dashboard/domain/entities/feeding_plan.dart';
import 'package:colette/features/dashboard/domain/entities/projected_bottle.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_feeding_plan.dart';

/// Projette les biberons des 24 prochaines heures à partir du plan du jour.
///
/// Le premier est le prochain biberon du plan. Les suivants enchaînent le
/// rythme du foyer ([BottleSchedule.nextAfter]), chacun supposé donné à son
/// heure prévue, en partant de `max(nextBottleAt, now)`. Les prises du
/// lendemain suivent la cible de demain répartie sur `feedsPerDay`.
class ProjectBottleSchedule {
  const ProjectBottleSchedule();

  static const horizon = Duration(hours: 24);

  List<ProjectedBottle> call({
    required FeedingPlan plan,
    required BottleSchedule schedule,
    required DateTime birthDate,
    required int? latestWeightGrams,
    required DateTime now,
    int? dailyTargetMlOverride,
  }) {
    final end = now.add(horizon);
    final tomorrowMl = _tomorrowSuggestedMl(
      feedsPerDay: plan.feedsPerDay,
      birthDate: birthDate,
      latestWeightGrams: latestWeightGrams,
      now: now,
      dailyTargetMlOverride: dailyTargetMlOverride,
    );
    final firstGiven = plan.nextBottleAt.isAfter(now) ? plan.nextBottleAt : now;
    final bottles = [
      ProjectedBottle(
        at: plan.nextBottleAt,
        windowStart: plan.windowStart,
        windowEnd: plan.windowEnd,
        suggestedMl: plan.suggestedMl,
      ),
    ];
    for (
      var at = schedule.nextAfter(firstGiven);
      at.isBefore(end);
      at = schedule.nextAfter(at)
    ) {
      final (windowStart, windowEnd) = schedule.windowAround(at);
      bottles.add(
        ProjectedBottle(
          at: at,
          windowStart: windowStart,
          windowEnd: windowEnd,
          suggestedMl: at.dateOnly == now.dateOnly
              ? plan.suggestedMl
              : tomorrowMl,
        ),
      );
    }
    return bottles;
  }
```

`_tomorrowSuggestedMl` reste inchangée.

- [ ] **Step 7 : providers**

`dashboard_providers.dart`, dans `feedingPlan` : remplacer `feedsPerDay: profile.careSettings.feedsPerDay,` par `schedule: profile.careSettings.bottleSchedule,`. Dans `bottleSchedule`, ajouter `schedule: profile.careSettings.bottleSchedule,` après `plan: plan,`.

`feeding_plan_sync.dart` : remplacer `feedsPerDay: profile.careSettings.feedsPerDay,` par `schedule: profile.careSettings.bottleSchedule,`.

```bash
dart run build_runner build -d
```

- [ ] **Step 8 : vérifier le succès**

```bash
flutter test test/features/dashboard/ && dart analyze
```

Attendu : tout vert, aucun problème d'analyse. `grep -rn "minGap\|maxGap\|windowAfter\|intervalFor" lib test` ne renvoie rien.

- [ ] **Step 9 : commit**

```bash
git add lib/features/dashboard/domain/use_cases/compute_feeding_plan.dart lib/features/dashboard/domain/use_cases/project_bottle_schedule.dart lib/features/dashboard/presentation/providers/dashboard_providers.dart lib/features/dashboard/presentation/providers/dashboard_providers.g.dart lib/features/dashboard/presentation/providers/feeding_plan_sync.dart test/features/dashboard/
git commit -m "feat: prochain biberon et projection selon les horaires du foyer

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

(`git status` avant le commit : n'ajouter un `.g.dart` que s'il a réellement changé.)

---

### Task 4 : retrait de `feedsPerDay` des réglages

**Files :**
- Modify : `lib/features/baby/domain/entities/care_settings.dart`
- Modify : `lib/features/baby/data/dtos/baby_profile_dto.dart`
- Modify : `lib/features/baby/presentation/widgets/care_settings_section.dart`
- Modify : `lib/l10n/app_fr.arb`
- Test : `test/features/baby/data/baby_profile_dto_test.dart`, `test/features/baby/presentation/baby_settings_controller_test.dart`, `test/features/baby/presentation/care_settings_section_test.dart`

- [ ] **Step 1 : tests (rouge)**

`baby_profile_dto_test.dart` : remplacer le test `'CareSettingsDto.fromMap borne feedsPerDay'` par

```dart
  test('feedsPerDay n\'est plus écrit et l\'ancien champ est ignoré', () {
    expect(
      CareSettingsDto.toMap(const CareSettings()).containsKey('feedsPerDay'),
      isFalse,
    );
    expect(
      CareSettingsDto.fromMap(const {'feedsPerDay': 12}),
      const CareSettings(),
    );
  });
```

`baby_settings_controller_test.dart`, test `'updateCareSettings enregistre et synchronise'` : `const CareSettings(feedsPerDay: 7)` → `const CareSettings(bottleIntervalMinutes: 165)`, et `expect(saved.careSettings.feedsPerDay, 7);` → `expect(saved.careSettings.bottleIntervalMinutes, 165);`.

`care_settings_section_test.dart` : le premier test devient

```dart
  testWidgets('cinq lignes de soin avec switch, sans stepper biberons', (
    tester,
  ) async {
    await pumpSection(tester);
    expect(find.byType(CareFrequencyRow), findsNWidgets(5));
    expect(find.byType(Switch), findsNWidgets(5));
    expect(find.text('Soin du nombril'), findsOneWidget);
    expect(find.text('Biberons par jour'), findsNothing);
    expect(find.text('tous les 2 jours'), findsOneWidget); // bain
  });
```

et le commentaire `// Ordre des lignes : …` devient `// Ordre des lignes : Adrigyl, yeux, nez, nombril, bain.`

- [ ] **Step 2 : vérifier l'échec**

```bash
flutter test test/features/baby/
```

Attendu : échecs du test DTO (`feedsPerDay` encore écrit et lu) et du test de section (`'Biberons par jour'` encore affiché). Le test contrôleur passe déjà (`bottleIntervalMinutes` existe depuis la Task 2).

- [ ] **Step 3 : implémentation**

- `care_settings.dart` : supprimer la ligne `@Default(8) int feedsPerDay,`.
- `baby_profile_dto.dart` : supprimer `'feedsPerDay': settings.feedsPerDay,` dans `toMap` et `feedsPerDay: _readBoundedInt(map, 'feedsPerDay', 8, min: 1, max: 24),` dans `fromMap`.
- `care_settings_section.dart` : supprimer le bloc `IntStepperRow(label: s.settingsFeedsPerDay, …)`, l'import `int_stepper_row.dart` et la variable `s` si elle n'a plus d'usage ; commentaire de classe `/// Fréquence et suivi de chaque soin programmé.`
- `app_fr.arb` : supprimer la ligne `"settingsFeedsPerDay": "Biberons par jour",`.

```bash
dart run build_runner build -d && flutter gen-l10n
```

- [ ] **Step 4 : vérifier le succès**

```bash
flutter test && dart analyze
```

Attendu : tout vert. `grep -rn "feedsPerDay" lib | grep -v "\.g\.dart\|\.freezed\.dart"` ne montre plus que `BottleSchedule.feedsPerDay`, `FeedingPlan.feedsPerDay` et leurs usages.

- [ ] **Step 5 : commit**

```bash
git add lib/features/baby/domain/entities/care_settings.dart lib/features/baby/domain/entities/care_settings.freezed.dart lib/features/baby/data/dtos/baby_profile_dto.dart lib/features/baby/presentation/widgets/care_settings_section.dart lib/l10n/app_fr.arb test/features/baby/
git commit -m "feat: nombre de biberons par jour déduit des horaires

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5 : `IntStepperRow.format`

**Files :**
- Modify : `lib/shared/ui/widgets/int_stepper_row.dart`
- Test : `test/shared/ui/widgets/int_stepper_row_test.dart`

- [ ] **Step 1 : test (rouge)**

Ajouter à `int_stepper_row_test.dart` :

```dart
  testWidgets('format remplace l\'affichage de la valeur', (tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: IntStepperRow(
          label: 'Intervalle',
          value: 165,
          min: 90,
          max: 300,
          step: 15,
          format: (v) => '${v ~/ 60} h ${(v % 60).toString().padLeft(2, '0')}',
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('2 h 45'), findsOneWidget);
    expect(find.text('165'), findsNothing);
  });
```

- [ ] **Step 2 : vérifier l'échec**

```bash
flutter test test/shared/ui/widgets/int_stepper_row_test.dart
```

Attendu : échec de compilation (`format` inconnu).

- [ ] **Step 3 : implémentation**

Dans `IntStepperRow` : ajouter `this.format,` au constructeur après `this.suffix,`, le champ

```dart
  /// Affichage de la valeur ; prime sur [suffix].
  final String Function(int value)? format;
```

et le texte central :

```dart
        Text(
          format?.call(value) ?? (suffix == null ? '$value' : '$value $suffix'),
```

- [ ] **Step 4 : vérifier le succès**

```bash
flutter test test/shared/ui/widgets/int_stepper_row_test.dart
```

- [ ] **Step 5 : commit**

```bash
git add lib/shared/ui/widgets/int_stepper_row.dart test/shared/ui/widgets/int_stepper_row_test.dart
git commit -m "feat: affichage formaté dans IntStepperRow

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6 : carte Réglages « Biberons »

**Files :**
- Create : `lib/features/baby/presentation/widgets/bottle_schedule_settings_section.dart`
- Modify : `lib/features/baby/presentation/pages/settings_page.dart`
- Modify : `lib/l10n/app_fr.arb`
- Test : `test/features/baby/presentation/bottle_schedule_settings_section_test.dart`

- [ ] **Step 1 : libellés**

Dans `app_fr.arb`, juste après `"settingsCareSection": "Soins attendus",` :

```json
  "settingsBottlesSection": "Biberons",
  "settingsFirstBottle": "Premier biberon",
  "settingsLastBottle": "Biberon du soir",
  "settingsBottleInterval": "Intervalle",
  "settingsFeedsPerDaySummary": "{count, plural, =1{≈ 1 biberon par jour} other{≈ {count} biberons par jour}}",
  "@settingsFeedsPerDaySummary": { "placeholders": { "count": { "type": "int" } } },
```

```bash
flutter gen-l10n
```

- [ ] **Step 2 : test (rouge)**

`test/features/baby/presentation/bottle_schedule_settings_section_test.dart` :

```dart
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/widgets/bottle_schedule_settings_section.dart';
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
  final profile = BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1));

  setUpAll(() => registerFallbackValue(profile));

  late MockBabyRepository repo;

  Future<void> pumpSection(WidgetTester tester, BabyProfile profile) async {
    repo = MockBabyRepository();
    when(() => repo.saveProfile(any(), any()))
        .thenAnswer((_) async => right(null));
    await pumpApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: BottleScheduleSettingsSection(profile: profile),
        ),
      ),
      overrides: [
        babyRepositoryProvider.overrideWithValue(repo),
        feedingPlanSyncProvider.overrideWithValue(const NoopFeedingPlanSync()),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
  }

  List<BabyProfile> savedProfiles() =>
      verify(() => repo.saveProfile('ABCDEFGH', captureAny())).captured
          .cast<BabyProfile>();

  // Ordre des lignes : premier biberon, biberon du soir, intervalle.
  final plusButtons = find.widgetWithIcon(IconButton, Icons.add);
  final minusButtons = find.widgetWithIcon(IconButton, Icons.remove);

  testWidgets('affiche les horaires par défaut et le nombre déduit', (
    tester,
  ) async {
    await pumpSection(tester, profile);
    expect(find.text('Premier biberon'), findsOneWidget);
    expect(find.text('Biberon du soir'), findsOneWidget);
    expect(find.text('Intervalle'), findsOneWidget);
    expect(find.text('7 h 00'), findsOneWidget);
    expect(find.text('23 h 30'), findsOneWidget);
    expect(find.text('3 h 00'), findsOneWidget);
    expect(find.text('≈ 7 biberons par jour'), findsOneWidget);
  });

  testWidgets('− du premier biberon enregistre 6 h 45', (tester) async {
    await pumpSection(tester, profile);
    await tester.tap(minusButtons.first);
    await tester.pumpAndSettle();
    expect(savedProfiles().last.careSettings.firstBottleMinutes, 405);
    expect(find.text('6 h 45'), findsOneWidget);
  });

  testWidgets('deux + sur l\'intervalle : 3 h 30 et 6 biberons', (
    tester,
  ) async {
    await pumpSection(tester, profile);
    await tester.tap(plusButtons.at(2));
    await tester.pump();
    await tester.tap(plusButtons.at(2));
    await tester.pumpAndSettle();
    expect(savedProfiles().last.careSettings.bottleIntervalMinutes, 210);
    expect(find.text('3 h 30'), findsOneWidget);
    expect(find.text('≈ 6 biberons par jour'), findsOneWidget);
  });

  testWidgets('le + du soir est désactivé à 23 h 45', (tester) async {
    await pumpSection(
      tester,
      profile.copyWith(
        careSettings: const CareSettings(
          lastBottleMinutes: CareSettings.maxLastBottleMinutes,
        ),
      ),
    );
    expect(find.text('23 h 45'), findsOneWidget);
    expect(tester.widget<IconButton>(plusButtons.at(1)).onPressed, isNull);
    expect(tester.widget<IconButton>(minusButtons.at(1)).onPressed, isNotNull);
  });
}
```

- [ ] **Step 3 : vérifier l'échec**

```bash
flutter test test/features/baby/presentation/bottle_schedule_settings_section_test.dart
```

Attendu : échec de compilation (widget introuvable).

- [ ] **Step 4 : implémentation du widget**

`lib/features/baby/presentation/widgets/bottle_schedule_settings_section.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/int_stepper_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Horaires des biberons : premier, soir, intervalle, et nombre déduit par jour.
/// Tient une copie locale optimiste, comme `CareSettingsSection`.
class BottleScheduleSettingsSection extends ConsumerStatefulWidget {
  const BottleScheduleSettingsSection({super.key, required this.profile});

  final BabyProfile profile;

  @override
  ConsumerState<BottleScheduleSettingsSection> createState() =>
      _BottleScheduleSettingsSectionState();
}

class _BottleScheduleSettingsSectionState
    extends ConsumerState<BottleScheduleSettingsSection> {
  late CareSettings _settings = widget.profile.careSettings;

  @override
  void didUpdateWidget(covariant BottleScheduleSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.profile.careSettings;
    final writing = ref.read(babySettingsControllerProvider).isLoading;
    if (incoming != oldWidget.profile.careSettings && !writing) {
      _settings = incoming;
    }
  }

  /// Fusionne le champ modifié dans le profil frais, pour ne jamais écraser
  /// un champ écrit entre-temps par une autre section des réglages.
  void _update(CareSettings Function(CareSettings settings) apply) {
    setState(() => _settings = apply(_settings));
    ref
        .read(babySettingsControllerProvider.notifier)
        .updateCareSettings(widget.profile, apply(widget.profile.careSettings));
  }

  @override
  Widget build(BuildContext context) {
    // Garde le contrôleur autoDispose vivant pendant l'await de updateCareSettings.
    ref.watch(babySettingsControllerProvider);
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    String hoursMinutes(int minutes) => s.durationHoursMinutes(
      minutes ~/ 60,
      (minutes % 60).toString().padLeft(2, '0'),
    );
    return ColetteCardSurface(
      padding: AppSpacing.sm.all,
      child: Column(
        crossAxisAlignment: .start,
        children: [
          IntStepperRow(
            label: s.settingsFirstBottle,
            value: _settings.firstBottleMinutes,
            min: CareSettings.minFirstBottleMinutes,
            max: CareSettings.maxFirstBottleMinutes,
            step: CareSettings.bottleTimeStepMinutes,
            format: hoursMinutes,
            onChanged: (v) =>
                _update((settings) => settings.copyWith(firstBottleMinutes: v)),
          ),
          IntStepperRow(
            label: s.settingsLastBottle,
            value: _settings.lastBottleMinutes,
            min: CareSettings.minLastBottleMinutes,
            max: CareSettings.maxLastBottleMinutes,
            step: CareSettings.bottleTimeStepMinutes,
            format: hoursMinutes,
            onChanged: (v) =>
                _update((settings) => settings.copyWith(lastBottleMinutes: v)),
          ),
          IntStepperRow(
            label: s.settingsBottleInterval,
            value: _settings.bottleIntervalMinutes,
            min: CareSettings.minBottleIntervalMinutes,
            max: CareSettings.maxBottleIntervalMinutes,
            step: CareSettings.bottleTimeStepMinutes,
            format: hoursMinutes,
            onChanged: (v) => _update(
              (settings) => settings.copyWith(bottleIntervalMinutes: v),
            ),
          ),
          Padding(
            padding: AppSpacing.xs.all,
            child: Text(
              s.settingsFeedsPerDaySummary(
                _settings.bottleSchedule.feedsPerDay,
              ),
              style: styles.small.copyWith(
                color: context.appColor(AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

Vérifier les chemins d'import de `AppColors` et `coletteTextStyles` en les copiant depuis `lib/shared/ui/widgets/int_stepper_row.dart` (mêmes fichiers).

- [ ] **Step 5 : vérifier le succès**

```bash
flutter test test/features/baby/presentation/bottle_schedule_settings_section_test.dart
```

- [ ] **Step 6 : brancher dans la page Réglages**

`settings_page.dart` : importer le widget, puis après `CareSettingsSection(profile: profile),` :

```dart
            SectionHeader(title: s.settingsBottlesSection),
            BottleScheduleSettingsSection(profile: profile),
```

```bash
flutter test test/features/baby/ && dart analyze
```

- [ ] **Step 7 : commit**

```bash
git add lib/features/baby/presentation/widgets/bottle_schedule_settings_section.dart lib/features/baby/presentation/pages/settings_page.dart lib/l10n/app_fr.arb test/features/baby/presentation/bottle_schedule_settings_section_test.dart
git commit -m "feat: carte Biberons dans les réglages (premier, soir, intervalle)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7 : vérification finale

- [ ] **Step 1 : format, analyse, tests**

```bash
dart format lib test && dart analyze && flutter test
```

Attendu : aucun fichier reformaté (sinon commit `chore: format`), aucune alerte, tous les tests verts.

- [ ] **Step 2 : simulateur**

Lancer l'app sur un simulateur iPhone (ouvrir d'abord le panneau Simulateur). Sans foyer, l'onglet Réglages n'affiche pas la carte : **ne pas créer de foyer de test dans le Firestore de production** sans accord de Maxence. Si aucun foyer n'est disponible, le signaler et laisser la vérification visuelle (clair et sombre) au test iPhone.

- [ ] **Step 3 : rendre compte**

Lister les commits de la branche (`git log --oneline main..HEAD`), la divergence avec `main` et le résultat de `git merge-tree --write-tree main HEAD`, puis demander à Maxence la validation du merge. Pas de merge ni de push sans son accord.

---

## Ajouts du 2026-09-30 après la revue de la Task 3

Décisions de Maxence : (1) un biberon trop proche du biberon du soir en tient lieu (écart minimum d'un demi-intervalle) ; (2) un biberon manqué ne laisse pas l'app « en retard » toute la nuit : le plan bascule sur le premier biberon du matin, avec un rappel push de secours à l'ouverture de sa fourchette ; (3) le retard s'affiche en heures et minutes. Ces tâches s'exécutent après la Task 6 ; la Task 7 (vérification finale) passe en dernier.

### Task 8 : écart minimum avant le biberon du soir

**Files :**
- Modify : `lib/features/baby/domain/entities/bottle_schedule.dart`
- Test : `test/features/baby/domain/bottle_schedule_test.dart`

Règle : un biberon de journée dont `last + interval` dépasse le biberon du soir est rabattu sur le soir **seulement si** `soir − last ≥ interval / 2` ; sinon il tient lieu de biberon du soir et le suivant est le premier du matin (même calcul que la branche nuit). Avec 7 h / 23 h 30 / 3 h : 22 h 00 → 23 h 30 (écart 1 h 30, gardé) ; 22 h 01 → 7 h ; 22 h 45 → 7 h ; 22 h 59 → 7 h.

`feedsPerDay` suit la même règle : `n = ⌈span / interval⌉`, `écart = span − (n − 1) × interval`, résultat `n` si `écart < interval / 2`, sinon `n + 1` (au moins 1 comme avant).

- [ ] **Step 1 : tests (rouge)**

Dans `bottle_schedule_test.dart`, groupe `nextAfter` :

- remplacer le test `'journée : rabattu sur le biberon du soir'` par :

```dart
    test('journée : rabattu sur le biberon du soir à au moins 1 h 30', () {
      expect(next(10, 21), DateTime(2026, 9, 10, 23, 30));
      expect(next(10, 22), DateTime(2026, 9, 10, 23, 30));
    });

    test('trop près du biberon du soir : il en tient lieu', () {
      expect(next(10, 22, 1), DateTime(2026, 9, 11, 7));
      expect(next(10, 22, 45), DateTime(2026, 9, 11, 7));
    });
```

- remplacer `'22 h 59 est encore la journée : rabattu sur 23 h 30'` par :

```dart
    test('22 h 59 tient lieu de biberon du soir', () {
      expect(next(10, 22, 59), DateTime(2026, 9, 11, 7));
    });
```

- dans `'réglages personnalisés'` (6 h 30 / 22 h / 2 h 45, demi-intervalle 1 h 22 min 30 s), remplacer les attentes par :

```dart
      expect(
        custom.nextAfter(DateTime(2026, 9, 10, 18)),
        DateTime(2026, 9, 10, 20, 45),
      );
      // Écart de 2 h ≥ 1 h 22 : rabattu sur 22 h.
      expect(
        custom.nextAfter(DateTime(2026, 9, 10, 20)),
        DateTime(2026, 9, 10, 22),
      );
      // Écart de 1 h 15 < 1 h 22 : tient lieu de biberon du soir.
      expect(
        custom.nextAfter(DateTime(2026, 9, 10, 20, 45)),
        DateTime(2026, 9, 11, 6, 30),
      );
      expect(
        custom.nextAfter(DateTime(2026, 9, 10, 22)),
        DateTime(2026, 9, 11, 6, 30),
      );
```

Groupe `feedsPerDay`, ajouter :

```dart
    test('dernier créneau trop près du soir : il en tient lieu', () {
      // 7 h, 10 h, 13 h, 16 h, 19 h, 22 h ; 23 h n'est qu'à 1 h de 22 h.
      const close = BottleSchedule(lastBottle: Duration(hours: 23));
      expect(close.feedsPerDay, 6);
    });

    test('plage plus courte que le demi-intervalle : 1', () {
      const short = BottleSchedule(
        firstBottle: Duration(hours: 10),
        lastBottle: Duration(hours: 11),
      );
      expect(short.feedsPerDay, 1);
    });
```

(Les attentes existantes 7 / 7 / 4 / 1 restent vraies.)

- [ ] **Step 2 : vérifier l'échec** — `flutter test test/features/baby/domain/bottle_schedule_test.dart` : échecs sur 22 h 01, 22 h 45, 22 h 59, 20 h 45 personnalisé et `feedsPerDay` 6.

- [ ] **Step 3 : implémentation**

Dans `nextAfter`, remplacer la ligne `if (isDaytime) return planned.isAfter(evening) ? evening : planned;` et le calcul de `nextMorning` par :

```dart
    if (isDaytime && !planned.isAfter(evening)) return planned;
    // Assez loin du biberon du soir : rabattu dessus ; sinon il en tient lieu.
    if (isDaytime && evening.difference(last) >= interval ~/ 2) return evening;
    final nextMorning = morning.isAfter(last)
        ? morning
        : _at(DateTime(day.year, day.month, day.day + 1), firstBottle);
    return planned.isAfter(nextMorning) ? planned : nextMorning;
```

Mettre à jour la doc de `nextAfter` : « Biberon de journée (…) : `last + interval`, rabattu sur le biberon du soir s'il en est à au moins un demi-intervalle ; plus près, il tient lieu de biberon du soir. »

`feedsPerDay` :

```dart
  /// Biberons de journée du premier au soir ; au moins 1. Le dernier créneau
  /// tient lieu de biberon du soir s'il en est à moins d'un demi-intervalle.
  int get feedsPerDay {
    final span = lastBottle - firstBottle;
    if (span <= Duration.zero || interval <= Duration.zero) return 1;
    final slots = (span.inMinutes / interval.inMinutes).ceil();
    final gap = span - interval * (slots - 1);
    return gap < interval ~/ 2 ? slots : slots + 1;
  }
```

- [ ] **Step 4 : vérifier le succès** — le fichier de test, puis `flutter test` complet (d'autres tests peuvent dépendre de 22 h 45 → 23 h 30 : mettre leurs attentes à jour selon la règle, avec un commentaire de calcul), `dart format`, `dart analyze`.

- [ ] **Step 5 : commit** — `feat: un biberon trop proche du soir en tient lieu`

---

### Task 9 : bascule sur le matin après un biberon manqué (app)

**Files :**
- Modify : `lib/features/baby/domain/entities/bottle_schedule.dart` (`morningAfter`, `upcomingMorning`, `nextDue`)
- Modify : `lib/features/dashboard/domain/use_cases/compute_feeding_plan.dart`
- Modify : `lib/features/baby/domain/entities/feeding_plan_snapshot.dart`, `lib/features/baby/data/repositories/firestore_baby_repository.dart`, `lib/features/dashboard/presentation/providers/feeding_plan_sync.dart`
- Test : `bottle_schedule_test.dart`, `compute_feeding_plan_test.dart`, `test/features/baby/data/firestore_baby_repository_test.dart`, `test/features/dashboard/presentation/feeding_plan_sync_test.dart`

Règle : `nextDue(last, now)` = `nextAfter(last)`, sauf si sa fourchette est finie (`now > next + 30 min`) **et** que le premier biberon de la journée en cours à `now` (`upcomingMorning(now)` : celui du jour tant que la fourchette du soir n'est pas ouverte, sinon celui du lendemain) tombe après `next` ; on affiche alors ce biberon du matin. Un biberon de journée manqué reste « en retard » jusqu'à l'ouverture de la fourchette du soir, puis bascule sur le matin. Le snapshot écrit en plus le premier biberon du matin qui suit `nextBottleAt` (`morningAfter`) et sa fourchette, pour le rappel de secours des Cloud Functions (Task 10).

- [ ] **Step 1 : tests `BottleSchedule` (rouge)**

Ajouter à `bottle_schedule_test.dart` :

```dart
  group('morningAfter', () {
    test('premier biberon strictement après', () {
      expect(
        schedule.morningAfter(DateTime(2026, 9, 10, 23, 30)),
        DateTime(2026, 9, 11, 7),
      );
      expect(
        schedule.morningAfter(DateTime(2026, 9, 11, 6, 59)),
        DateTime(2026, 9, 11, 7),
      );
      expect(
        schedule.morningAfter(DateTime(2026, 9, 11, 7)),
        DateTime(2026, 9, 12, 7),
      );
    });
  });

  group('upcomingMorning', () {
    test('celui du jour jusqu\'à l\'ouverture de la fourchette du soir', () {
      expect(
        schedule.upcomingMorning(DateTime(2026, 9, 11, 0, 5)),
        DateTime(2026, 9, 11, 7),
      );
      expect(
        schedule.upcomingMorning(DateTime(2026, 9, 11, 12)),
        DateTime(2026, 9, 11, 7),
      );
      expect(
        schedule.upcomingMorning(DateTime(2026, 9, 11, 22, 59)),
        DateTime(2026, 9, 11, 7),
      );
    });

    test('celui du lendemain dès 23 h', () {
      expect(
        schedule.upcomingMorning(DateTime(2026, 9, 11, 23)),
        DateTime(2026, 9, 12, 7),
      );
    });
  });

  group('nextDue', () {
    DateTime due(DateTime last, DateTime now) => schedule.nextDue(last, now);
    final evening22 = DateTime(2026, 9, 10, 22);

    test('fourchette pas finie : nextAfter', () {
      expect(
        due(evening22, DateTime(2026, 9, 10, 23, 50)),
        DateTime(2026, 9, 10, 23, 30),
      );
      expect(
        due(evening22, DateTime(2026, 9, 11, 0)),
        DateTime(2026, 9, 10, 23, 30),
      );
    });

    test('biberon du soir manqué : premier du matin', () {
      expect(
        due(evening22, DateTime(2026, 9, 11, 0, 5)),
        DateTime(2026, 9, 11, 7),
      );
      expect(
        due(evening22, DateTime(2026, 9, 11, 8)),
        DateTime(2026, 9, 11, 7),
      );
    });

    test('biberon de journée manqué : en retard jusqu\'au soir', () {
      final ten = DateTime(2026, 9, 10, 10);
      expect(due(ten, DateTime(2026, 9, 10, 15)), DateTime(2026, 9, 10, 13));
      expect(
        due(ten, DateTime(2026, 9, 10, 22, 59)),
        DateTime(2026, 9, 10, 13),
      );
      expect(due(ten, DateTime(2026, 9, 10, 23, 10)), DateTime(2026, 9, 11, 7));
    });
  });
```

- [ ] **Step 2 : tests du plan (rouge)**

Dans `compute_feeding_plan_test.dart`, ajouter :

```dart
  group('biberon manqué', () {
    FeedingPlan planAt(DateTime lastAt, DateTime now) {
      final last = makeEvent(id: 'a', startAt: lastAt, bottleMl: 60);
      return compute(
        birthDate: birth,
        latestWeightGrams: 3600,
        schedule: schedule,
        todayBottles: lastAt.day == now.day ? [last] : const [],
        lastBottle: last,
        now: now,
      );
    }

    test('biberon du soir manqué : la nuit, on attend le matin', () {
      final now = DateTime(2026, 9, 11, 0, 5);
      final plan = planAt(DateTime(2026, 9, 10, 22), now);
      expect(plan.nextBottleAt, DateTime(2026, 9, 11, 7));
      expect(plan.windowStart, DateTime(2026, 9, 11, 6, 30));
      expect(plan.windowEnd, DateTime(2026, 9, 11, 7, 30));
      expect(plan.lateBy(now), Duration.zero);
    });

    test('toujours rien à 8 h : en retard depuis 7 h 30', () {
      final now = DateTime(2026, 9, 11, 8);
      final plan = planAt(DateTime(2026, 9, 10, 22), now);
      expect(plan.nextBottleAt, DateTime(2026, 9, 11, 7));
      expect(plan.lateBy(now), const Duration(minutes: 30));
    });

    test('biberon de journée manqué : en retard l\'après-midi', () {
      final now = DateTime(2026, 9, 10, 15);
      final plan = planAt(DateTime(2026, 9, 10, 10), now);
      expect(plan.nextBottleAt, DateTime(2026, 9, 10, 13));
      expect(plan.lateBy(now), const Duration(hours: 1, minutes: 30));
    });
  });
```

`firestore_baby_repository_test.dart`, test `'saveFeedingPlan écrit feedingPlan sans effacer baby'` : ajouter au snapshot `morningBottleAt: DateTime(2026, 9, 22, 7)`, `morningWindowStartAt: DateTime(2026, 9, 22, 6, 30)`, `morningWindowEndAt: DateTime(2026, 9, 22, 7, 30)` et vérifier les trois `Timestamp` relus. Ajouter un test : snapshot sans ces champs → les trois clés valent `null`.

`feeding_plan_sync_test.dart`, premier test (biberon à 9 h, maintenant 12 h) : vérifier en plus `morningBottleAt` = `DateTime(2026, 9, 11, 7)`, `morningWindowStartAt` = `DateTime(2026, 9, 11, 6, 30)`, `morningWindowEndAt` = `DateTime(2026, 9, 11, 7, 30)`.

- [ ] **Step 3 : vérifier l'échec** — `flutter test test/features/baby test/features/dashboard` : erreurs de compilation attendues.

- [ ] **Step 4 : implémentation**

`BottleSchedule` :

```dart
  /// Premier biberon du matin strictement après [at].
  DateTime morningAfter(DateTime at) {
    final day = DateTime(at.year, at.month, at.day);
    final morning = _at(day, firstBottle);
    return morning.isAfter(at)
        ? morning
        : _at(DateTime(day.year, day.month, day.day + 1), firstBottle);
  }

  /// Premier biberon de la journée en cours à [now] : celui du jour, puis
  /// celui du lendemain dès l'ouverture de la fourchette du soir.
  DateTime upcomingMorning(DateTime now) {
    final day = DateTime(now.year, now.month, now.day);
    final eveningStart = _at(day, lastBottle).subtract(halfWindow);
    return now.isBefore(eveningStart)
        ? _at(day, firstBottle)
        : _at(DateTime(day.year, day.month, day.day + 1), firstBottle);
  }

  /// Biberon attendu à [now] après un biberon donné à [last] : [nextAfter],
  /// ou, une fois sa fourchette finie et la soirée entamée, le premier biberon
  /// du matin, pour ne pas compter de retard la nuit.
  DateTime nextDue(DateTime last, DateTime now) {
    final next = nextAfter(last);
    if (!now.isAfter(next.add(halfWindow))) return next;
    final morning = upcomingMorning(now);
    return morning.isAfter(next) ? morning : next;
  }
```

Dans `nextAfter`, le calcul de `nextMorning` devient `final nextMorning = morningAfter(last);` (même résultat).

`ComputeFeedingPlan.call` : `schedule.nextAfter(lastBottle.startAt)` → `schedule.nextDue(lastBottle.startAt, now)`. Doc de classe : ajouter « Un biberon manqué bascule sur le premier du matin une fois la soirée entamée. »

`FeedingPlanSnapshot` : ajouter

```dart
    /// Premier biberon du matin après [nextBottleAt] et sa fourchette : rappel
    /// de secours si aucun biberon n'est noté d'ici là ; `null` sans biberon.
    DateTime? morningBottleAt,
    DateTime? morningWindowStartAt,
    DateTime? morningWindowEndAt,
```

`FirestoreBabyRepository.saveFeedingPlan` : écrire `'morningBottleAt'`, `'morningWindowStartAt'`, `'morningWindowEndAt'` (`Timestamp.fromDate(...)` ou `null`), avec un helper local si utile.

`FirestoreFeedingPlanSync.sync` : après le calcul du plan, avec `final schedule = profile.careSettings.bottleSchedule;` (réutilisé pour `ComputeFeedingPlan`) :

```dart
      final morning = lastBottle == null
          ? null
          : schedule.morningAfter(plan.nextBottleAt);
      final morningWindow = morning == null
          ? null
          : schedule.windowAround(morning);
```

puis passer `morningBottleAt: morning`, `morningWindowStartAt: morningWindow?.$1`, `morningWindowEndAt: morningWindow?.$2` au snapshot.

`dart run build_runner build -d`.

- [ ] **Step 5 : vérifier le succès** — `flutter test` complet, `dart format`, `dart analyze`.

- [ ] **Step 6 : commit** — `feat: un biberon manqué bascule sur le premier du matin`

---

### Task 10 : rappel de secours du matin (Cloud Functions)

**Files :**
- Modify : `functions/src/lib/types.ts` (`FeedingPlanDoc`)
- Modify : `functions/src/bottle-reminder.ts`
- Test : `functions/src/bottle-reminder.test.ts`

Aucun déploiement dans cette tâche : il sera demandé à Maxence après le merge.

- [ ] **Step 0 : dépendances** — `npm --prefix functions ci` (le dossier `node_modules` n'existe pas dans le worktree).

- [ ] **Step 1 : tests (rouge)**

Dans `bottle-reminder.test.ts`, `describe('bottleReminder')`, ajouter :

```ts
  /** Plan dont la fourchette principale est finie depuis des heures, déjà notifiée. */
  function expiredPlanWithMorning(morningStart: Date): FeedingPlanDoc {
    const primaryEnd = new Date(morningStart.getTime() - 6 * 60 * 60 * 1000);
    return {
      nextBottleAt: Timestamp.fromDate(new Date(primaryEnd.getTime() - 30 * 60 * 1000)),
      windowStartAt: Timestamp.fromDate(new Date(primaryEnd.getTime() - 60 * 60 * 1000)),
      windowEndAt: Timestamp.fromDate(primaryEnd),
      suggestedMl: 120,
      computedAt: Timestamp.fromDate(new Date(primaryEnd.getTime() - 3 * 60 * 60 * 1000)),
      morningBottleAt: Timestamp.fromDate(new Date(morningStart.getTime() + 30 * 60 * 1000)),
      morningWindowStartAt: Timestamp.fromDate(morningStart),
      morningWindowEndAt: Timestamp.fromDate(new Date(morningStart.getTime() + 60 * 60 * 1000)),
    };
  }

  it('biberon manqué : rappel de secours à l\'ouverture de la fourchette du matin', async () => {
    const morningStart = new Date(Date.now() - 60 * 1000);
    const plan = expiredPlanWithMorning(morningStart);
    households.push({
      id: 'ABC123',
      fields: { feedingPlan: plan, lastBottleNotifiedFor: plan.nextBottleAt },
      devices: [{ id: 'd1' }],
    });

    await handler();

    const [, , payload] = sendToDevices.mock.calls[0];
    expect(payload.title).toBe('Biberon possible dès maintenant');
    expect(payload.body).toBe(
      `Environ 120 ml, d'ici ${formatHourMinute(plan.morningWindowEndAt!.toDate())}`,
    );
    expect(updates).toEqual([
      { household: 'ABC123', data: { lastBottleNotifiedFor: plan.morningBottleAt } },
    ]);
  });

  it('fourchette du matin pas encore ouverte : rien', async () => {
    const plan = expiredPlanWithMorning(new Date(Date.now() + 5 * 60 * 1000));
    households.push({
      id: 'ABC123',
      fields: { feedingPlan: plan, lastBottleNotifiedFor: plan.nextBottleAt },
      devices: [{ id: 'd1' }],
    });

    await handler();

    expect(sendToDevices).not.toHaveBeenCalled();
    expect(updates).toEqual([]);
  });

  it('rappel du matin déjà envoyé : rien', async () => {
    const plan = expiredPlanWithMorning(new Date(Date.now() - 60 * 1000));
    households.push({
      id: 'ABC123',
      fields: { feedingPlan: plan, lastBottleNotifiedFor: plan.morningBottleAt },
      devices: [{ id: 'd1' }],
    });

    await handler();

    expect(sendToDevices).not.toHaveBeenCalled();
  });
```

- [ ] **Step 2 : vérifier l'échec** — `npm --prefix functions test` : erreurs de type / premier test en échec.

- [ ] **Step 3 : implémentation**

`types.ts`, dans `FeedingPlanDoc` :

```ts
  /** Premier biberon du matin après `nextBottleAt` et sa fourchette : rappel de secours
   *  si aucun biberon n'est noté d'ici là. Absents ou nuls sans biberon ou avant les horaires. */
  morningBottleAt?: Timestamp | null;
  morningWindowStartAt?: Timestamp | null;
  morningWindowEndAt?: Timestamp | null;
```

`bottle-reminder.ts` : extraire les échéances candidates puis prendre la première due.

```ts
type Deadline = { key: Timestamp; nextBottleAt: Date; windowStartAt: Date | null; windowEndAt: Date | null };

/** Échéances à rappeler : le prochain biberon, puis le premier du matin en secours. */
export function deadlinesOf(plan: FeedingPlanDoc): Deadline[] {
  const deadlines: Deadline[] = [
    {
      key: plan.nextBottleAt,
      nextBottleAt: plan.nextBottleAt.toDate(),
      windowStartAt: plan.windowStartAt?.toDate() ?? null,
      windowEndAt: plan.windowEndAt?.toDate() ?? null,
    },
  ];
  if (plan.morningBottleAt && plan.morningWindowStartAt && plan.morningWindowEndAt) {
    deadlines.push({
      key: plan.morningBottleAt,
      nextBottleAt: plan.morningBottleAt.toDate(),
      windowStartAt: plan.morningWindowStartAt.toDate(),
      windowEndAt: plan.morningWindowEndAt.toDate(),
    });
  }
  return deadlines;
}
```

Dans la boucle du handler, remplacer le calcul unique par :

```ts
      const computedAt = plan.computedAt?.toDate() ?? null;
      const deadline = deadlinesOf(plan).find((d) =>
        isReminderDue({ ...d, computedAt, lastNotifiedFor, now }),
      );
      if (!deadline) continue;
```

(`isReminderDue` ignore la clé `key` en trop ; si TypeScript la refuse, passer les champs un à un), puis envoyer `bottleMessage(plan.suggestedMl, deadline.nextBottleAt, deadline.windowStartAt ? deadline.windowEndAt : null)` et écrire `lastBottleNotifiedFor: deadline.key`. Supprimer les variables devenues inutiles.

- [ ] **Step 4 : vérifier le succès** — `npm --prefix functions test` (tous verts) et `npm --prefix functions run build` (tsc sans erreur). Ne pas commiter `functions/lib/` s'il est ignoré ; vérifier avec `git status`.

- [ ] **Step 5 : commit** — `feat: rappel de secours au premier biberon du matin` (fichiers `functions/src/...` uniquement).

---

### Task 11 : retard affiché en heures et minutes

**Files :**
- Modify : `lib/l10n/app_fr.arb` (`nextBottleLate`)
- Modify : `lib/features/dashboard/presentation/widgets/next_bottle_card.dart`, `lib/features/dashboard/presentation/widgets/bottle_schedule_sheet.dart`
- Test : `test/features/dashboard/presentation/dashboard_page_test.dart`, `test/features/dashboard/presentation/bottle_schedule_sheet_test.dart`

- [ ] **Step 1 : tests (rouge)**

`dashboard_page_test.dart` : l'attente `'en retard de 125 min'` devient `'en retard de 2 h 05'`.

`bottle_schedule_sheet_test.dart` (fixture : fourchette ± 25 min, maintenant 22 h le 10) :

```dart
  testWidgets('un retard de plus d\'une heure s\'affiche en heures', (
    tester,
  ) async {
    await pumpSheet(tester, [bottle(DateTime(2026, 9, 10, 20), 70)]);
    // Fin de fourchette 20 h 25 : 1 h 35 de retard à 22 h.
    expect(find.text('en retard de 1 h 35'), findsOneWidget);
  });
```

`'en retard de 35 min'` reste inchangé.

- [ ] **Step 2 : vérifier l'échec** — les deux fichiers de test.

- [ ] **Step 3 : implémentation**

`app_fr.arb` :

```json
  "nextBottleLate": "en retard de {duration}",
  "@nextBottleLate": { "placeholders": { "duration": { "type": "String" } } },
```

`next_bottle_card.dart` : `s.nextBottleLate(late.inMinutes)` → `s.nextBottleLate(formatDuration(late, s))`. `bottle_schedule_sheet.dart` : `s.nextBottleLate(now.difference(bottle.windowEnd).inMinutes)` → `s.nextBottleLate(formatDuration(now.difference(bottle.windowEnd), s))`. Importer `package:colette/shared/ui/duration_format.dart` si absent. `flutter gen-l10n`.

- [ ] **Step 4 : vérifier le succès** — `flutter test` complet, `dart format`, `dart analyze`.

- [ ] **Step 5 : commit** — `fix: retard du biberon affiché en heures et minutes`
