# Horaires de biberons choisis — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal :** remplacer premier biberon / biberon du soir / intervalle par une grille d'horaires choisis (N biberons = N heures), rappelés un par un par la Cloud Function.

**Architecture :** `BottleSchedule` (`baby/domain`) ne porte plus qu'une liste d'horaires et garde ses méthodes publiques ; le biberon réel est rattaché à l'horaire le plus proche. `CareSettings` stocke `bottleTimesMinutes` (migration depuis les anciens champs dans le DTO). Le snapshot `feedingPlan` gagne `upcomingBottles` (projection 24 h) que `bottleReminder` rappelle créneau par créneau.

**Tech Stack :** Flutter, Riverpod 3 codegen, freezed, fake_cloud_firestore, mocktail ; Cloud Functions TypeScript + vitest.

Spec : `docs/superpowers/specs/2026-10-07-bottle-custom-times-design.md`. Lire `CLAUDE.md` (design system, l10n, Riverpod) avant toute tâche.

Commandes communes (depuis la racine du worktree `.claude/worktrees/bottle-custom-times`) :
- codegen : `dart run build_runner build -d`
- l10n : `flutter gen-l10n`
- tests ciblés : `flutter test <fichier>`
- fin de tâche : `dart format lib test && dart analyze && flutter test`
- Functions : `cd functions && npm test && npm run build`

Commits : `git add` de fichiers ciblés uniquement (jamais `-A`), message en français, terminé par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Ne jamais toucher `pubspec.yaml`.

---

### Tâche 1 : `BottleSchedule` en grille d'horaires

**Files :**
- Modify : `lib/features/baby/domain/entities/bottle_schedule.dart` (réécriture)
- Modify : `lib/features/baby/domain/entities/care_settings.dart` (getter `bottleSchedule` seulement)
- Test : `test/features/baby/domain/bottle_schedule_test.dart` (réécriture)
- Test (adaptation) : `test/features/dashboard/domain/compute_feeding_plan_test.dart`, `test/features/dashboard/domain/project_bottle_schedule_test.dart`, `test/features/baby/data/baby_profile_dto_test.dart` (ligne `bottleSchedule == const BottleSchedule()` : reste vraie)

- [ ] **Step 1 : réécrire le test de domaine (rouge)**

`test/features/baby/domain/bottle_schedule_test.dart` :

```dart
import 'package:colette/features/baby/domain/entities/bottle_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Défaut : 07h00, 10h00, 13h00, 16h00, 19h00, 22h00, 23h30.
  const schedule = BottleSchedule();
  DateTime at(int day, int hour, [int minute = 0]) =>
      DateTime(2026, 9, day, hour, minute);

  test('défaut : 7 horaires, de 7 h à 23 h 30', () {
    expect(schedule.feedsPerDay, 7);
    expect(schedule.times.first, const Duration(hours: 7));
    expect(schedule.times.last, const Duration(hours: 23, minutes: 30));
  });

  group('slotOf', () {
    test('horaire exact', () {
      expect(schedule.slotOf(at(10, 10)), at(10, 10));
    });

    test('avant le milieu : horaire précédent ; au milieu et après : suivant', () {
      expect(schedule.slotOf(at(10, 11, 29)), at(10, 10));
      expect(schedule.slotOf(at(10, 11, 30)), at(10, 13));
      expect(schedule.slotOf(at(10, 12, 45)), at(10, 13));
    });

    test('nuit : 23 h 30 jusqu\'au milieu (3 h 15), puis 7 h', () {
      expect(schedule.slotOf(at(11, 3)), at(10, 23, 30));
      expect(schedule.slotOf(at(11, 3, 15)), at(11, 7));
      expect(schedule.slotOf(at(10, 23, 50)), at(10, 23, 30));
    });

    test('tôt le matin : 6 h 30 compte pour 7 h', () {
      expect(schedule.slotOf(at(10, 6, 30)), at(10, 7));
    });
  });

  group('nextAfter', () {
    test('donné à l\'heure : horaire suivant', () {
      expect(schedule.nextAfter(at(10, 10)), at(10, 13));
    });

    test('donné en retard : la grille ne bouge pas', () {
      expect(schedule.nextAfter(at(10, 10, 45)), at(10, 13));
    });

    test('donné plus près de l\'horaire suivant : compte pour lui', () {
      expect(schedule.nextAfter(at(10, 12, 45)), at(10, 16));
    });

    test('biberon du soir ou de nuit : premier du lendemain', () {
      expect(schedule.nextAfter(at(10, 23, 30)), at(11, 7));
      expect(schedule.nextAfter(at(11, 2)), at(11, 7));
    });

    test('fin de mois', () {
      expect(
        schedule.nextAfter(DateTime(2026, 9, 30, 23, 30)),
        DateTime(2026, 10, 1, 7),
      );
    });
  });

  group('nextDue', () {
    test('horaire sauté : reste dû jusqu\'au milieu, puis le suivant', () {
      // Dernier biberon 7 h → 10 h dû ; milieu 10 h–13 h = 11 h 30.
      expect(schedule.nextDue(at(10, 7), at(10, 11, 29)), at(10, 10));
      expect(schedule.nextDue(at(10, 7), at(10, 11, 30)), at(10, 13));
      expect(schedule.nextDue(at(10, 7), at(10, 15)), at(10, 16));
    });

    test('nuit : aucun retard après le biberon du soir', () {
      expect(schedule.nextDue(at(10, 23, 30), at(11, 3)), at(11, 7));
    });

    test('dernier biberon très ancien : horaire le plus proche de maintenant', () {
      expect(schedule.nextDue(at(8, 10), at(10, 14)), at(10, 13));
    });
  });

  group('morningAfter', () {
    test('premier horaire strictement après', () {
      expect(schedule.morningAfter(at(10, 6)), at(10, 7));
      expect(schedule.morningAfter(at(10, 7)), at(11, 7));
      expect(schedule.morningAfter(at(10, 23, 30)), at(11, 7));
    });
  });

  group('grille personnalisée', () {
    const five = BottleSchedule(
      times: [
        Duration(hours: 7),
        Duration(hours: 10, minutes: 30),
        Duration(hours: 14),
        Duration(hours: 17, minutes: 30),
        Duration(hours: 21),
      ],
    );

    test('exemples de la spec', () {
      expect(five.feedsPerDay, 5);
      expect(five.nextAfter(at(10, 11, 15)), at(10, 14));
      expect(five.nextAfter(at(10, 12, 45)), at(10, 17, 30));
      expect(five.nextAfter(at(10, 12, 14)), at(10, 14));
    });
  });

  group('fromLegacy', () {
    BottleSchedule legacy(int first, int last, int interval) =>
        BottleSchedule.fromLegacy(
          first: Duration(minutes: first),
          last: Duration(minutes: last),
          interval: Duration(minutes: interval),
        );

    test('réglages par défaut : la grille par défaut', () {
      expect(legacy(420, 1410, 180), const BottleSchedule());
    });

    test('soir à au moins un demi-intervalle : ajouté', () {
      // 7 h, 12 h, 17 h, 22 h : écart 22 h – 17 h = 5 h ≥ 2 h 30.
      expect(legacy(420, 1320, 300).times, const [
        Duration(hours: 7),
        Duration(hours: 12),
        Duration(hours: 17),
        Duration(hours: 22),
      ]);
    });

    test('soir trop près du dernier créneau : il le remplace', () {
      // 7 h, 10 h 15, 13 h 30, 16 h 45, 20 h, 23 h 15 → 23 h 15 remplacé par 23 h 30.
      expect(legacy(420, 1410, 195).times, const [
        Duration(hours: 7),
        Duration(hours: 10, minutes: 15),
        Duration(hours: 13, minutes: 30),
        Duration(hours: 16, minutes: 45),
        Duration(hours: 20),
        Duration(hours: 23, minutes: 30),
      ]);
    });
  });
}
```

- [ ] **Step 2 : lancer le test**

Run : `flutter test test/features/baby/domain/bottle_schedule_test.dart`
Expected : FAIL (compilation : `times`, `slotOf`, `fromLegacy` inexistants).

- [ ] **Step 3 : réécrire l'entité**

`lib/features/baby/domain/entities/bottle_schedule.dart` :

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'bottle_schedule.freezed.dart';

/// Grille des biberons : horaires fixes de la journée, triés.
@freezed
abstract class BottleSchedule with _$BottleSchedule {
  const BottleSchedule._();

  @Assert('times.length > 0', 'au moins un horaire')
  const factory BottleSchedule({
    /// Horaires depuis minuit, triés, espacés d'au moins 30 min (y compris du
    /// dernier au premier du lendemain).
    @Default(defaultBottleTimes) List<Duration> times,
  }) = _BottleSchedule;

  /// Grille tirée des anciens réglages (premier, soir, intervalle) : chaîne
  /// `first + k × interval` avant le soir ; le soir s'ajoute s'il est à au moins
  /// un demi-intervalle du dernier créneau, sinon il le remplace.
  factory BottleSchedule.fromLegacy({
    required Duration first,
    required Duration last,
    required Duration interval,
  }) {
    final span = last - first;
    if (span <= Duration.zero || interval <= Duration.zero) {
      return BottleSchedule(times: [first]);
    }
    final slots = (span.inMinutes / interval.inMinutes).ceil();
    final chain = [for (var i = 0; i < slots; i++) first + interval * i];
    final gap = span - interval * (slots - 1);
    final replaces = gap < interval ~/ 2 && slots > 1;
    return BottleSchedule(
      times: [...replaces ? chain.sublist(0, slots - 1) : chain, last],
    );
  }

  /// Biberons par jour.
  int get feedsPerDay => times.length;

  /// Créneau daté le plus proche de [at] ; au milieu exact, le plus tardif.
  DateTime slotOf(DateTime at) {
    final day = DateTime(at.year, at.month, at.day);
    final slots = [
      _at(_shift(day, -1), times.last),
      for (final time in times) _at(day, time),
      _at(_shift(day, 1), times.first),
    ];
    for (var i = 0; i < slots.length - 1; i++) {
      final from = slots[i];
      final to = slots[i + 1];
      if (at.isBefore(from) || !at.isBefore(to)) continue;
      final middle = from.add(to.difference(from) ~/ 2);
      return at.isBefore(middle) ? from : to;
    }
    return slots.last;
  }

  /// Horaire prévu après un biberon donné à [last] : celui qui suit
  /// l'horaire auquel [last] est rattaché ([slotOf]).
  DateTime nextAfter(DateTime last) => _slotAfter(slotOf(last));

  /// Horaire attendu à [now] : le plus tardif de [nextAfter] et de
  /// l'horaire le plus proche de [now]. Un horaire sauté reste dû jusqu'au
  /// milieu de l'écart avec le suivant ; la nuit ne compte aucun retard.
  DateTime nextDue(DateTime last, DateTime now) {
    final next = nextAfter(last);
    final current = slotOf(now);
    return current.isAfter(next) ? current : next;
  }

  /// Premier horaire de la journée strictement après [at].
  DateTime morningAfter(DateTime at) {
    final day = DateTime(at.year, at.month, at.day);
    final morning = _at(day, times.first);
    return morning.isAfter(at) ? morning : _at(_shift(day, 1), times.first);
  }

  /// Créneau qui suit [slot] dans la grille.
  DateTime _slotAfter(DateTime slot) {
    final day = DateTime(slot.year, slot.month, slot.day);
    final minutes = slot.hour * 60 + slot.minute;
    for (final time in times) {
      if (time.inMinutes > minutes) return _at(day, time);
    }
    return _at(_shift(day, 1), times.first);
  }

  static DateTime _shift(DateTime day, int days) =>
      DateTime(day.year, day.month, day.day + days);

  /// [day] (à minuit) décalé de [time], en heure locale.
  static DateTime _at(DateTime day, Duration time) =>
      DateTime(day.year, day.month, day.day, 0, time.inMinutes);
}

/// Grille par défaut : 07h00, 10h00, 13h00, 16h00, 19h00, 22h00, 23h30.
const defaultBottleTimes = [
  Duration(hours: 7),
  Duration(hours: 10),
  Duration(hours: 13),
  Duration(hours: 16),
  Duration(hours: 19),
  Duration(hours: 22),
  Duration(hours: 23, minutes: 30),
];
```

Dans `care_settings.dart`, remplacer le getter (les trois anciens champs restent jusqu'à la tâche 3) :

```dart
  /// Grille des biberons tirée des réglages.
  BottleSchedule get bottleSchedule => BottleSchedule.fromLegacy(
    first: Duration(minutes: firstBottleMinutes),
    last: Duration(minutes: lastBottleMinutes),
    interval: Duration(minutes: bottleIntervalMinutes),
  );
```

- [ ] **Step 4 : codegen et test de domaine**

Run : `dart run build_runner build -d && flutter test test/features/baby/domain/bottle_schedule_test.dart`
Expected : PASS.

- [ ] **Step 5 : adapter les tests du plan et de la projection**

Run : `flutter test test/features/dashboard test/features/baby`
Pour chaque échec, adapter l'attente à la grille (pas le code) :
- `compute_feeding_plan_test.dart` : `fourFeeds` devient
  ```dart
  const fourFeeds = BottleSchedule(
    times: [
      Duration(hours: 7),
      Duration(hours: 12),
      Duration(hours: 17),
      Duration(hours: 22),
    ],
  );
  ```
  Les tests de biberon manqué suivent désormais `nextDue` (dû jusqu'au milieu de l'écart, puis l'horaire suivant ; pas de retard la nuit). Renommer les tests dont le titre parle d'intervalle ou de marge.
- `project_bottle_schedule_test.dart` : la projection énumère les horaires de la grille (« suit l'intervalle, le biberon du soir puis le matin » devient « suit la grille, puis le premier horaire du lendemain »). Un dernier biberon à 9 h est rattaché à 10 h : le suivant est 13 h.
- Tous les autres tests du dossier doivent rester verts sans changement.

- [ ] **Step 6 : vérification et commit**

Run : `dart format lib test && dart analyze && flutter test`
Expected : aucune erreur, tous les tests verts.

```bash
git add lib/features/baby/domain/entities/bottle_schedule.dart lib/features/baby/domain/entities/care_settings.dart test/features/baby/domain/bottle_schedule_test.dart test/features/dashboard/domain/compute_feeding_plan_test.dart test/features/dashboard/domain/project_bottle_schedule_test.dart
git commit -m "feat: grille d'horaires de biberons, rattachement à l'horaire le plus proche"
```
(ajouter tout autre test adapté au Step 5 ; les fichiers `.freezed.dart` sont versionnés si `git status` les montre modifiés.)

---

### Tâche 2 : `bottleTimesMinutes` dans `CareSettings` et son DTO

**Files :**
- Modify : `lib/features/baby/domain/entities/care_settings.dart`
- Modify : `lib/features/baby/data/dtos/baby_profile_dto.dart`
- Create : `test/features/baby/domain/care_settings_test.dart`
- Modify : `test/features/baby/data/baby_profile_dto_test.dart`

Les trois anciens champs restent dans l'entité jusqu'à la tâche 3 (l'écran les utilise encore), mais `bottleSchedule` ne les lit plus.

- [ ] **Step 1 : tests de l'entité (rouge)**

`test/features/baby/domain/care_settings_test.dart` :

```dart
import 'package:colette/features/baby/domain/entities/bottle_schedule.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const defaults = CareSettings();
  const five = CareSettings(bottleTimesMinutes: [420, 630, 840, 1050, 1260]);

  test('défaut : la grille par défaut', () {
    expect(defaults.bottleTimesMinutes, [420, 600, 780, 960, 1140, 1320, 1410]);
    expect(defaults.bottleSchedule, const BottleSchedule());
  });

  group('bottleTimesAreValid', () {
    test('grille triée, écarts ≥ 30 min, nuit comprise', () {
      expect(CareSettings.bottleTimesAreValid([420, 600, 1410]), isTrue);
      expect(CareSettings.bottleTimesAreValid([0, 30, 1410]), isTrue);
    });

    test('refuse vide, non trié, hors 0–1439, trop proche', () {
      expect(CareSettings.bottleTimesAreValid([]), isFalse);
      expect(CareSettings.bottleTimesAreValid([600, 420]), isFalse);
      expect(CareSettings.bottleTimesAreValid([420, 1440]), isFalse);
      expect(CareSettings.bottleTimesAreValid([420, 445]), isFalse);
      // 23 h 50 → 0 h 10 le lendemain : 20 min.
      expect(CareSettings.bottleTimesAreValid([10, 600, 1430]), isFalse);
    });
  });

  group('withBottleCount', () {
    test('+1 : milieu du plus grand écart de journée, le premier en cas d\'égalité', () {
      expect(defaults.withBottleCount(8).bottleTimesMinutes, [
        420, 510, 600, 780, 960, 1140, 1320, 1410,
      ]);
    });

    test('+1 : l\'écart de nuit n\'est jamais choisi', () {
      expect(five.withBottleCount(6).bottleTimesMinutes, [
        420, 525, 630, 840, 1050, 1260,
      ]);
    });

    test('milieu arrondi au pas de 5 min inférieur', () {
      const odd = CareSettings(bottleTimesMinutes: [420, 485, 1200]);
      // Plus grand écart 485 → 1200 (715 min) : 485 + 355 = 840.
      expect(odd.withBottleCount(4).bottleTimesMinutes, [420, 485, 840, 1200]);
    });

    test('−1 : retire le dernier', () {
      expect(five.withBottleCount(4).bottleTimesMinutes, [420, 630, 840, 1050]);
    });

    test('même nombre : inchangé', () {
      expect(five.withBottleCount(5), five);
    });
  });

  group('canAddBottle', () {
    test('vrai avec un écart de journée ≥ 60 min et moins de 12 biberons', () {
      expect(defaults.canAddBottle, isTrue);
    });

    test('faux à 12 biberons', () {
      final twelve = defaults.withBottleCount(12);
      expect(twelve.bottleTimesMinutes, hasLength(12));
      expect(twelve.canAddBottle, isFalse);
    });

    test('faux si aucun écart de journée n\'atteint 60 min', () {
      const tight = CareSettings(bottleTimesMinutes: [600, 655, 710]);
      expect(tight.canAddBottle, isFalse);
    });
  });

  group('withBottleTime', () {
    test('remplace et retrie', () {
      expect(five.withBottleTime(0, 1380)!.bottleTimesMinutes, [
        630, 840, 1050, 1260, 1380,
      ]);
    });

    test('refuse un horaire à moins de 30 min d\'un autre', () {
      expect(five.withBottleTime(0, 610), isNull);
      expect(five.withBottleTime(4, 400), isNull);
    });

    test('accepte l\'horaire inchangé', () {
      expect(five.withBottleTime(2, 840), five);
    });
  });
}
```

- [ ] **Step 2 : lancer le test**

Run : `flutter test test/features/baby/domain/care_settings_test.dart`
Expected : FAIL (membres inexistants).

- [ ] **Step 3 : implémenter dans `CareSettings`**

Ajouter le champ après `bottleIntervalMinutes` :

```dart
    /// Horaires des biberons, en minutes depuis minuit, triés.
    @Default([420, 600, 780, 960, 1140, 1320, 1410]) List<int> bottleTimesMinutes,
```

Ajouter les constantes :

```dart
  static const minBottlesPerDay = 3;
  static const maxBottlesPerDay = 12;
  static const bottleTimePickerStepMinutes = 5;
  static const minBottleGapMinutes = 30;
  static const _minutesPerDay = 24 * 60;
```

Remplacer le getter et ajouter les méthodes :

```dart
  /// Grille des biberons tirée des horaires réglés.
  BottleSchedule get bottleSchedule => BottleSchedule(
    times: [for (final m in bottleTimesMinutes) Duration(minutes: m)],
  );

  /// Grille non vide, triée, dans 0–1439, écarts d'au moins 30 min, y
  /// compris du dernier horaire au premier du lendemain.
  static bool bottleTimesAreValid(List<int> times) {
    if (times.isEmpty) return false;
    if (times.any((m) => m < 0 || m >= _minutesPerDay)) return false;
    for (var i = 1; i < times.length; i++) {
      if (times[i] - times[i - 1] < minBottleGapMinutes) return false;
    }
    return times.first + _minutesPerDay - times.last >= minBottleGapMinutes;
  }

  /// Milieu (au pas de 5 min inférieur) du plus grand écart entre deux
  /// horaires consécutifs de la journée, nuit exclue ; `null` si aucun écart
  /// n'atteint deux fois l'écart minimum.
  int? get _bottleInsertion {
    int? best;
    var bestGap = 2 * minBottleGapMinutes - 1;
    for (var i = 1; i < bottleTimesMinutes.length; i++) {
      final gap = bottleTimesMinutes[i] - bottleTimesMinutes[i - 1];
      if (gap > bestGap) {
        bestGap = gap;
        final half = gap ~/ 2;
        best = bottleTimesMinutes[i - 1] +
            half - half % bottleTimePickerStepMinutes;
      }
    }
    return best;
  }

  /// Un biberon de plus est-il possible ?
  bool get canAddBottle =>
      bottleTimesMinutes.length < maxBottlesPerDay && _bottleInsertion != null;

  /// Copie avec [count] biberons : ajoute au milieu du plus grand écart de
  /// journée (tant que [canAddBottle]), ou retire les derniers.
  CareSettings withBottleCount(int count) {
    var settings = this;
    while (settings.bottleTimesMinutes.length < count && settings.canAddBottle) {
      final inserted = settings._bottleInsertion!;
      settings = settings.copyWith(
        bottleTimesMinutes: [...settings.bottleTimesMinutes, inserted]..sort(),
      );
    }
    if (settings.bottleTimesMinutes.length > count && count >= 1) {
      settings = settings.copyWith(
        bottleTimesMinutes: settings.bottleTimesMinutes.sublist(0, count),
      );
    }
    return settings;
  }

  /// Copie avec l'horaire [index] remplacé par [minutes], retriée ; `null` si
  /// la grille obtenue est invalide (horaire trop proche d'un autre).
  CareSettings? withBottleTime(int index, int minutes) {
    final times = [...bottleTimesMinutes]..[index] = minutes;
    times.sort();
    return bottleTimesAreValid(times)
        ? copyWith(bottleTimesMinutes: times)
        : null;
  }
```

Note : `withBottleCount(12)` sur la grille par défaut doit atteindre 12 (les écarts de 180 et 90 min se divisent jusqu'à 45 min) ; si le test « faux à 12 biberons » échoue sur la longueur, vérifier l'algorithme, pas le test.

- [ ] **Step 4 : codegen et tests de l'entité**

Run : `dart run build_runner build -d && flutter test test/features/baby/domain/care_settings_test.dart`
Expected : PASS.

- [ ] **Step 5 : tests du DTO (rouge)**

Dans `test/features/baby/data/baby_profile_dto_test.dart`, remplacer le groupe des horaires de biberons (lignes ~250–290, qui testent `firstBottleMinutes`…) par :

```dart
  group('horaires des biberons', () {
    test('absents : grille par défaut', () {
      final settings = CareSettingsDto.fromMap(const {});
      expect(settings.bottleTimesMinutes, [420, 600, 780, 960, 1140, 1320, 1410]);
      expect(settings.bottleSchedule, const BottleSchedule());
    });

    test('écrit bottleTimesMinutes, plus les anciens champs', () {
      final map = CareSettingsDto.toMap(
        const CareSettings(bottleTimesMinutes: [420, 630, 840, 1050, 1260]),
      );
      expect(map['bottleTimesMinutes'], [420, 630, 840, 1050, 1260]);
      expect(map.containsKey('firstBottleMinutes'), isFalse);
      expect(map.containsKey('lastBottleMinutes'), isFalse);
      expect(map.containsKey('bottleIntervalMinutes'), isFalse);
    });

    test('relit une grille valide, triée', () {
      final settings = CareSettingsDto.fromMap(const {
        'bottleTimesMinutes': [1260, 420, 840],
      });
      expect(settings.bottleTimesMinutes, [420, 840, 1260]);
    });

    test('anciens champs seuls : convertis par fromLegacy', () {
      final settings = CareSettingsDto.fromMap(const {
        'firstBottleMinutes': 420,
        'lastBottleMinutes': 1320,
        'bottleIntervalMinutes': 300,
      });
      expect(settings.bottleTimesMinutes, [420, 720, 1020, 1320]);
    });

    test('grille invalide : repli sur les anciens champs', () {
      final settings = CareSettingsDto.fromMap(const {
        'bottleTimesMinutes': [420, 430],
        'firstBottleMinutes': 420,
        'lastBottleMinutes': 1320,
        'bottleIntervalMinutes': 300,
      });
      expect(settings.bottleTimesMinutes, [420, 720, 1020, 1320]);
    });

    test('grille non numérique ou vide : défaut', () {
      for (final raw in [<Object>[], ['7h'], 'x', 3.5]) {
        expect(
          CareSettingsDto.fromMap({'bottleTimesMinutes': raw}).bottleTimesMinutes,
          [420, 600, 780, 960, 1140, 1320, 1410],
        );
      }
    });

    test('anciens champs hors bornes : bornés comme avant', () {
      final settings = CareSettingsDto.fromMap(const {
        'firstBottleMinutes': 0,
        'lastBottleMinutes': 5000,
        'bottleIntervalMinutes': 10,
      });
      // Bornés à 4 h, 23 h 45, 1 h 30 : chaîne 4 h … 23 h 30, puis le soir
      // (à 15 min < 45 min du dernier créneau) remplace 23 h 30.
      expect(settings.bottleTimesMinutes.first, 240);
      expect(settings.bottleTimesMinutes.last, 1425);
      expect(CareSettings.bottleTimesAreValid(settings.bottleTimesMinutes), isTrue);
    });
  });
```

Retirer aussi toute autre assertion du fichier sur `firstBottleMinutes`, `lastBottleMinutes`, `bottleIntervalMinutes`.

- [ ] **Step 6 : lancer le test**

Run : `flutter test test/features/baby/data/baby_profile_dto_test.dart`
Expected : FAIL (écriture des anciens champs, lecture de la grille).

- [ ] **Step 7 : implémenter le DTO**

Dans `CareSettingsDto.toMap`, remplacer les trois lignes `firstBottleMinutes` / `lastBottleMinutes` / `bottleIntervalMinutes` par :

```dart
    'bottleTimesMinutes': settings.bottleTimesMinutes,
```

Ajouter dans `CareSettingsDto` les bornes des anciens champs (elles quittent l'entité à la tâche 3) et la lecture :

```dart
  // Bornes des anciens réglages (premier, soir, intervalle), pour la migration.
  static const _legacyFirstMin = 4 * 60;
  static const _legacyFirstMax = 10 * 60;
  static const _legacyLastMin = 20 * 60;
  static const _legacyLastMax = 23 * 60 + 45;
  static const _legacyIntervalMin = 90;
  static const _legacyIntervalMax = 5 * 60;
  static const _maxStoredBottles = 24;

  /// Grille stockée si valide ; sinon anciens réglages convertis ; sinon défaut.
  static List<int> _readBottleTimes(Map<String, dynamic> map) {
    final raw = map['bottleTimesMinutes'];
    if (raw is List &&
        raw.isNotEmpty &&
        raw.length <= _maxStoredBottles &&
        raw.every((v) => v is int)) {
      final times = raw.cast<int>().toList()..sort();
      if (CareSettings.bottleTimesAreValid(times)) return times;
    }
    final hasLegacy = map.containsKey('firstBottleMinutes') ||
        map.containsKey('lastBottleMinutes') ||
        map.containsKey('bottleIntervalMinutes');
    if (!hasLegacy) return const CareSettings().bottleTimesMinutes;
    final schedule = BottleSchedule.fromLegacy(
      first: Duration(
        minutes: _readBoundedInt(map, 'firstBottleMinutes', 420,
            min: _legacyFirstMin, max: _legacyFirstMax),
      ),
      last: Duration(
        minutes: _readBoundedInt(map, 'lastBottleMinutes', 1410,
            min: _legacyLastMin, max: _legacyLastMax),
      ),
      interval: Duration(
        minutes: _readBoundedInt(map, 'bottleIntervalMinutes', 180,
            min: _legacyIntervalMin, max: _legacyIntervalMax),
      ),
    );
    return [for (final t in schedule.times) t.inMinutes];
  }
```

Dans `fromMap`, ajouter `bottleTimesMinutes: _readBottleTimes(map),` et **retirer** la lecture des trois anciens champs (ils prennent leurs valeurs par défaut dans l'entité, inutilisées). Importer `bottle_schedule.dart`.

- [ ] **Step 8 : tests verts et vérification**

Run : `flutter test test/features/baby && dart format lib test && dart analyze && flutter test`
Expected : tout vert. Si `baby_settings_controller_test.dart` échoue sur `bottleIntervalMinutes`, le remplacer par `bottleTimesMinutes: [420, 630, 840, 1050, 1260]` (même assertion sur le champ sauvegardé).

- [ ] **Step 9 : commit**

```bash
git add lib/features/baby/domain/entities/care_settings.dart lib/features/baby/domain/entities/care_settings.freezed.dart lib/features/baby/data/dtos/baby_profile_dto.dart test/features/baby/domain/care_settings_test.dart test/features/baby/data/baby_profile_dto_test.dart
git commit -m "feat: horaires des biberons stockés, migration depuis premier/soir/intervalle"
```
(ajouter `baby_settings_controller_test.dart` s'il a été modifié ; n'ajouter le `.freezed.dart` que s'il est versionné.)

---

### Tâche 3 : carte « Biberons » des Réglages

**Files :**
- Modify : `lib/core/ui/date_time_picker.dart` (paramètre `minuteInterval`)
- Create : `lib/features/baby/presentation/widgets/bottle_time_row.dart`
- Modify : `lib/features/baby/presentation/widgets/bottle_schedule_settings_section.dart` (réécriture)
- Modify : `lib/l10n/app_fr.arb`
- Modify : `lib/features/baby/domain/entities/care_settings.dart` (retrait des anciens champs et bornes)
- Test : `test/features/baby/presentation/bottle_schedule_settings_section_test.dart` (réécriture)

- [ ] **Step 1 : l10n**

Dans `lib/l10n/app_fr.arb`, retirer `settingsFirstBottle`, `settingsLastBottle`, `settingsBottleInterval`, `settingsFeedsPerDaySummary` (et `@settingsFeedsPerDaySummary`), ajouter à leur place :

```json
  "settingsBottlesPerDay": "Biberons par jour",
  "settingsBottleNth": "{n, plural, =1{1er biberon} other{{n}e biberon}}",
  "@settingsBottleNth": { "placeholders": { "n": { "type": "int" } } },
  "settingsBottleTimeTooClose": "Deux biberons doivent être espacés d'au moins 30 min",
```

Run : `flutter gen-l10n` puis `grep -rn "settingsFirstBottle\|settingsLastBottle\|settingsBottleInterval\|settingsFeedsPerDaySummary" lib test` : seuls la section et son test doivent apparaître.

- [ ] **Step 2 : test de la section (rouge)**

Réécrire `test/features/baby/presentation/bottle_schedule_settings_section_test.dart` en gardant `pumpSection`, `savedProfiles` et les imports existants (ajouter `package:flutter/cupertino.dart`) :

```dart
  final plus = find.widgetWithIcon(IconButton, Icons.add);
  final minus = find.widgetWithIcon(IconButton, Icons.remove);

  Future<void> pickTime(WidgetTester tester, String current, DateTime value) async {
    await tester.tap(find.text(current));
    await tester.pumpAndSettle();
    tester
        .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
        .onDateTimeChanged(value);
    await tester.tap(find.text('Choisir'));
    await tester.pumpAndSettle();
  }

  testWidgets('affiche le nombre et un horaire par biberon', (tester) async {
    await pumpSection(tester, profile);
    expect(find.text('Biberons par jour'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('1er biberon'), findsOneWidget);
    expect(find.text('7e biberon'), findsOneWidget);
    expect(find.text('07h00'), findsOneWidget);
    expect(find.text('23h30'), findsOneWidget);
  });

  testWidgets('+ ajoute un horaire au milieu du plus grand écart', (tester) async {
    await pumpSection(tester, profile);
    await tester.tap(plus);
    await tester.pumpAndSettle();
    expect(
      savedProfiles().last.careSettings.bottleTimesMinutes,
      [420, 510, 600, 780, 960, 1140, 1320, 1410],
    );
    expect(find.text('08h30'), findsOneWidget);
    expect(find.text('8e biberon'), findsOneWidget);
  });

  testWidgets('− retire le dernier horaire', (tester) async {
    await pumpSection(tester, profile);
    await tester.tap(minus);
    await tester.pumpAndSettle();
    expect(
      savedProfiles().last.careSettings.bottleTimesMinutes,
      [420, 600, 780, 960, 1140, 1320],
    );
    expect(find.text('23h30'), findsNothing);
  });

  testWidgets('+ désactivé à 12 biberons', (tester) async {
    await pumpSection(
      tester,
      profile.copyWith(careSettings: const CareSettings().withBottleCount(12)),
    );
    expect(tester.widget<IconButton>(plus).onPressed, isNull);
  });

  testWidgets('un horaire choisi est enregistré et retrié', (tester) async {
    await pumpSection(tester, profile);
    await pickTime(tester, '07h00', DateTime(2000, 1, 1, 6, 30));
    expect(
      savedProfiles().last.careSettings.bottleTimesMinutes,
      [390, 600, 780, 960, 1140, 1320, 1410],
    );
    expect(find.text('06h30'), findsOneWidget);
  });

  testWidgets('horaire trop proche : refusé, rien n\'est écrit', (tester) async {
    await pumpSection(tester, profile);
    await pickTime(tester, '07h00', DateTime(2000, 1, 1, 9, 50));
    verifyNever(() => repo.saveProfile(any(), any()));
    expect(
      find.text('Deux biberons doivent être espacés d\'au moins 30 min'),
      findsOneWidget,
    );
    expect(find.text('07h00'), findsOneWidget);
  });
```

Run : `flutter test test/features/baby/presentation/bottle_schedule_settings_section_test.dart`
Expected : FAIL.

Si `pumpApp` ne fournit pas de `ScaffoldMessenger` (un `MaterialApp` en fournit un), envelopper comme les autres tests de SnackBar du projet.

- [ ] **Step 3 : `minuteInterval` dans le sélecteur partagé**

Dans `lib/core/ui/date_time_picker.dart`, ajouter le paramètre `int minuteInterval = 1,` (doc : « Pas des minutes ; l'heure initiale est arrondie à ce pas, exigé par `CupertinoDatePicker`. »), puis après les bornes :

```dart
  safeInitial = safeInitial.subtract(
    Duration(minutes: safeInitial.minute % minuteInterval),
  );
```

et passer `minuteInterval: minuteInterval,` au `CupertinoDatePicker`. Les autres appelants ne changent pas.

- [ ] **Step 4 : `BottleTimeRow`**

`lib/features/baby/presentation/widgets/bottle_time_row.dart` :

```dart
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Ligne « 2e biberon … 10h30 » ; un appui ouvre la roue des heures.
class BottleTimeRow extends StatelessWidget {
  const BottleTimeRow({
    super.key,
    required this.index,
    required this.minutes,
    required this.onChanged,
  });

  /// Rang du biberon dans la journée, depuis 0.
  final int index;

  /// Horaire en minutes depuis minuit.
  final int minutes;

  final ValueChanged<int> onChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: DateTime(2000, 1, 1, 0, minutes),
      mode: CupertinoDatePickerMode.time,
      minuteInterval: CareSettings.bottleTimePickerStepMinutes,
    );
    if (picked == null) return;
    onChanged(picked.hour * 60 + picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).coletteTextStyles;
    return Row(
      children: [
        Expanded(
          child: Text(S.of(context).settingsBottleNth(index + 1), style: styles.body),
        ),
        TextButton(
          onPressed: () => _pick(context),
          child: Text(formatHourMinute(DateTime(2000, 1, 1, 0, minutes))),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5 : réécrire la section**

Dans `bottle_schedule_settings_section.dart`, garder `didUpdateWidget` et `_update` tels quels ; doc de classe : `/// Horaires des biberons : nombre par jour et heure de chacun.` Remplacer `build` et ajouter `_setTime` :

```dart
  void _setTime(int index, int minutes) {
    if (_settings.withBottleTime(index, minutes) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).settingsBottleTimeTooClose)),
      );
      return;
    }
    _update((settings) => settings.withBottleTime(index, minutes) ?? settings);
  }

  @override
  Widget build(BuildContext context) {
    // Garde le contrôleur autoDispose vivant pendant l'await de updateCareSettings.
    ref.watch(babySettingsControllerProvider);
    final s = S.of(context);
    final times = _settings.bottleTimesMinutes;
    final count = times.length;
    return ColetteCardSurface(
      padding: AppSpacing.sm.all,
      child: Column(
        crossAxisAlignment: .start,
        children: [
          IntStepperRow(
            label: s.settingsBottlesPerDay,
            value: count,
            min: count < CareSettings.minBottlesPerDay
                ? count
                : CareSettings.minBottlesPerDay,
            max: _settings.canAddBottle ? count + 1 : count,
            onChanged: (v) =>
                _update((settings) => settings.withBottleCount(v)),
          ),
          for (var i = 0; i < count; i++)
            BottleTimeRow(
              key: ValueKey(i),
              index: i,
              minutes: times[i],
              onChanged: (minutes) => _setTime(i, minutes),
            ),
        ],
      ),
    );
  }
```

Retirer les imports devenus inutiles (`app_colors`, `text_styles` si plus utilisés) ; importer `bottle_time_row.dart`.

- [ ] **Step 6 : retirer les anciens champs de l'entité**

Dans `care_settings.dart`, supprimer `firstBottleMinutes`, `lastBottleMinutes`, `bottleIntervalMinutes`, `bottleTimeStepMinutes`, `minFirstBottleMinutes`, `maxFirstBottleMinutes`, `minLastBottleMinutes`, `maxLastBottleMinutes`, `minBottleIntervalMinutes`, `maxBottleIntervalMinutes`. Mettre à jour la doc de classe (« … cible de lait, horaires des biberons et de nuit » reste juste).

Run : `dart run build_runner build -d && grep -rn "firstBottleMinutes\|lastBottleMinutes\|bottleIntervalMinutes\|BottleStepMinutes\|FirstBottleMinutes\|LastBottleMinutes\|BottleIntervalMinutes" lib test`
Expected : seules les clés Firestore en chaîne dans `baby_profile_dto.dart` et ses tests.

- [ ] **Step 7 : tests verts et vérification**

Run : `flutter test test/features/baby/presentation/bottle_schedule_settings_section_test.dart && dart format lib test && dart analyze && flutter test`
Expected : tout vert. `settings_page_test` / `settings_sections_merge_test` : adapter les textes de la carte si elles les cherchent.

Vérifier en thème sombre que rien n'utilise de couleur en dur (TextButton prend le thème).

- [ ] **Step 8 : commit**

```bash
git add lib/core/ui/date_time_picker.dart lib/features/baby/presentation/widgets/bottle_time_row.dart lib/features/baby/presentation/widgets/bottle_schedule_settings_section.dart lib/l10n/app_fr.arb lib/features/baby/domain/entities/care_settings.dart test/features/baby/presentation/bottle_schedule_settings_section_test.dart
git commit -m "feat: nombre de biberons et horaire de chacun dans les Réglages"
```
(ajouter les autres tests adaptés et le `.freezed.dart` s'il est versionné.)

---

### Tâche 4 : `upcomingBottles` dans le snapshot

**Files :**
- Modify : `lib/features/baby/domain/entities/feeding_plan_snapshot.dart`
- Modify : `lib/features/baby/data/repositories/firestore_baby_repository.dart` (`saveFeedingPlan`) — vérifier le nom exact du fichier par `grep -rln saveFeedingPlan lib/features/baby/data`
- Modify : `lib/features/dashboard/presentation/providers/feeding_plan_sync.dart`
- Test : `test/features/baby/data/firestore_baby_repository_test.dart`, `test/features/dashboard/presentation/feeding_plan_sync_test.dart`

- [ ] **Step 1 : tests (rouge)**

Dans `firestore_baby_repository_test.dart`, ajouter :

```dart
  test('saveFeedingPlan écrit les biberons à venir', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreBabyRepository(db);
    await repo.saveFeedingPlan(
      'ABCDEFGH',
      FeedingPlanSnapshot(
        nextBottleAt: DateTime(2026, 9, 10, 13),
        suggestedMl: 90,
        computedAt: DateTime(2026, 9, 10, 11),
        upcomingBottles: [
          UpcomingBottle(at: DateTime(2026, 9, 10, 13), suggestedMl: 90),
          UpcomingBottle(at: DateTime(2026, 9, 10, 16), suggestedMl: 90),
        ],
      ),
    );
    final plan = (await db.collection('households').doc('ABCDEFGH').get())
        .data()!['feedingPlan'] as Map<String, dynamic>;
    final upcoming = (plan['upcomingBottles'] as List).cast<Map<String, dynamic>>();
    expect(upcoming, hasLength(2));
    expect((upcoming[1]['at'] as Timestamp).toDate(), DateTime(2026, 9, 10, 16));
    expect(upcoming[1]['suggestedMl'], 90);
  });
```

(reprendre la construction du repository utilisée par les tests voisins du fichier.)

Dans `feeding_plan_sync_test.dart`, dans le premier test (dernier biberon 9 h, `now` 12 h), ajouter après les assertions existantes :

```dart
    final upcoming = (plan['upcomingBottles'] as List)
        .cast<Map<String, dynamic>>()
        .map((b) => (b['at'] as Timestamp).toDate())
        .toList();
    // Dernier biberon 9 h → rattaché à 10 h ; grille par défaut sur 24 h.
    expect(upcoming.first, DateTime(2026, 9, 10, 13));
    expect(upcoming, contains(DateTime(2026, 9, 11, 7)));
    expect(upcoming.last.isBefore(DateTime(2026, 9, 11, 12)), isTrue);
```

Adapter les attentes existantes de ce test à la grille : `nextBottleAt` passe de 12 h à 13 h (9 h est rattaché à 10 h) ; ajuster le titre (« dernier biberon + 3 h » → « horaire suivant de la grille ») et la suggestion si elle change.

Run : `flutter test test/features/baby/data/firestore_baby_repository_test.dart test/features/dashboard/presentation/feeding_plan_sync_test.dart`
Expected : FAIL.

- [ ] **Step 2 : entité**

Dans `feeding_plan_snapshot.dart`, ajouter au factory :

```dart
    /// Biberons des 24 prochaines heures, rappelés un par un par la Cloud Function.
    @Default([]) List<UpcomingBottle> upcomingBottles,
```

et, dans le même fichier :

```dart
/// Biberon prévu dans le snapshot : heure et quantité conseillée.
@freezed
abstract class UpcomingBottle with _$UpcomingBottle {
  const factory UpcomingBottle({
    required DateTime at,
    required int suggestedMl,
  }) = _UpcomingBottle;
}
```

- [ ] **Step 3 : écriture Firestore**

Dans `saveFeedingPlan`, ajouter dans la map `feedingPlan` :

```dart
        'upcomingBottles': [
          for (final bottle in snapshot.upcomingBottles)
            {
              'at': Timestamp.fromDate(bottle.at),
              'suggestedMl': bottle.suggestedMl,
            },
        ],
```

- [ ] **Step 4 : synchro**

Dans `FirestoreFeedingPlanSync.sync`, après le calcul de `plan`, ajouter la projection et la passer au snapshot :

```dart
      final latestWeightGrams = GrowthMetric.weight.latestOf(measurements)?.grams;
      // (réutiliser latestWeightGrams dans l'appel de ComputeFeedingPlan)
      final upcoming = const ProjectBottleSchedule()(
        plan: plan,
        schedule: schedule,
        birthDate: profile.birthDate,
        latestWeightGrams: latestWeightGrams,
        now: now,
        dailyTargetMlOverride: profile.careSettings.dailyTargetMl,
      );
```

et dans `FeedingPlanSnapshot(...)` :

```dart
          upcomingBottles: [
            for (final bottle in upcoming)
              UpcomingBottle(at: bottle.at, suggestedMl: bottle.suggestedMl),
          ],
```

Importer `project_bottle_schedule.dart`.

- [ ] **Step 5 : codegen, tests verts, vérification**

Run : `dart run build_runner build -d && dart format lib test && dart analyze && flutter test`
Expected : tout vert.

- [ ] **Step 6 : commit**

```bash
git add lib/features/baby/domain/entities/feeding_plan_snapshot.dart lib/features/baby/data/repositories/firestore_baby_repository.dart lib/features/dashboard/presentation/providers/feeding_plan_sync.dart test/features/baby/data/firestore_baby_repository_test.dart test/features/dashboard/presentation/feeding_plan_sync_test.dart
git commit -m "feat: biberons des 24 prochaines heures écrits pour les rappels"
```
(chemins exacts selon le dépôt ; ajouter le `.freezed.dart` s'il est versionné.)

---

### Tâche 5 : `bottleReminder` rappelle chaque horaire

**Files :**
- Modify : `functions/src/lib/types.ts` (`FeedingPlanDoc`)
- Modify : `functions/src/bottle-reminder.ts`
- Test : `functions/src/bottle-reminder.test.ts`

- [ ] **Step 1 : tests (rouge)**

Dans `bottle-reminder.test.ts`, ajouter dans `describe('deadlinesOf', …)` :

```ts
  it('avec upcomingBottles : une échéance par créneau, triées, avec leurs ml', () => {
    const plan: FeedingPlanDoc = {
      nextBottleAt: at('2026-10-07T08:00:00Z'),
      suggestedMl: 120,
      morningBottleAt: at('2026-10-08T05:00:00Z'),
      upcomingBottles: [
        { at: at('2026-10-07T11:00:00Z'), suggestedMl: 120 },
        { at: at('2026-10-07T08:00:00Z'), suggestedMl: 120 },
        { at: at('2026-10-08T05:00:00Z'), suggestedMl: 130 },
      ],
    };

    const deadlines = deadlinesOf(plan);

    expect(deadlines.map((d) => d.nextBottleAt.toISOString())).toEqual([
      '2026-10-07T08:00:00.000Z',
      '2026-10-07T11:00:00.000Z',
      '2026-10-08T05:00:00.000Z',
    ]);
    expect(deadlines.map((d) => d.suggestedMl)).toEqual([120, 120, 130]);
    expect(deadlines.every((d) => d.windowStartAt === null && d.windowEndAt === null)).toBe(true);
  });

  it('upcomingBottles vide ou absent : échéances historiques', () => {
    const plan = planWithMorning(at('2026-10-01T05:00:00Z'));
    expect(deadlinesOf({ ...plan, upcomingBottles: [] })).toEqual(deadlinesOf(plan));
    expect(deadlinesOf(plan)[0].suggestedMl).toBe(120);
  });
```

et dans `describe('bottleReminder', …)` :

```ts
  /** Plan avec grille : un créneau passé, un dû dans 5 min (90 ml), un plus tard. */
  function gridPlan(): FeedingPlanDoc {
    const now = Date.now();
    const slot = (minutes: number) => Timestamp.fromDate(new Date(now + minutes * 60 * 1000));
    return {
      nextBottleAt: slot(-120),
      suggestedMl: 120,
      computedAt: slot(-180),
      upcomingBottles: [
        { at: slot(-120), suggestedMl: 120 },
        { at: slot(5), suggestedMl: 90 },
        { at: slot(185), suggestedMl: 100 },
      ],
    };
  }

  it('grille : rappelle le créneau dû même si nextBottleAt est passé', async () => {
    const plan = gridPlan();
    households.push({ id: 'ABC123', fields: { feedingPlan: plan }, devices: [{ id: 'd1' }] });

    await handler();

    expect(sendToDevices).toHaveBeenCalledTimes(1);
    const [, , payload] = sendToDevices.mock.calls[0];
    expect(payload.title).toBe('Biberon dans 10 min');
    expect(payload.body).toContain('90 ml');
    expect(updates).toEqual([
      { household: 'ABC123', data: { lastBottleNotifiedFor: plan.upcomingBottles![1].at } },
    ]);
  });

  it('grille : pas de doublon pour un créneau déjà rappelé', async () => {
    const plan = gridPlan();
    households.push({
      id: 'ABC123',
      fields: { feedingPlan: plan, lastBottleNotifiedFor: plan.upcomingBottles![1].at },
      devices: [{ id: 'd1' }],
    });

    await handler();

    expect(sendToDevices).not.toHaveBeenCalled();
  });

  it('grille : ne revient pas sur un créneau antérieur au dernier rappelé', async () => {
    const plan = gridPlan();
    households.push({
      id: 'ABC123',
      fields: { feedingPlan: plan, lastBottleNotifiedFor: plan.upcomingBottles![2].at },
      devices: [{ id: 'd1' }],
    });

    await handler();

    expect(sendToDevices).not.toHaveBeenCalled();
  });
```

Run : `cd functions && npm test`
Expected : FAIL (type `upcomingBottles` inconnu, `suggestedMl` absent des échéances).

- [ ] **Step 2 : type**

Dans `functions/src/lib/types.ts`, ajouter à `FeedingPlanDoc` :

```ts
  /** Biberons des 24 prochaines heures (app à horaires choisis) : rappelés un par un, 10 min
   *  avant. Absent avec une ancienne version de l'app : échéances `nextBottleAt` + matin. */
  upcomingBottles?: Array<{ at: Timestamp; suggestedMl: number }> | null;
```

- [ ] **Step 3 : fonction**

Dans `bottle-reminder.ts` :

1. `Deadline` gagne `suggestedMl: number`.
2. `deadlinesOf` commence par :

```ts
  if (plan.upcomingBottles && plan.upcomingBottles.length > 0) {
    return [...plan.upcomingBottles]
      .sort((a, b) => a.at.toMillis() - b.at.toMillis())
      .map((b) => ({
        key: b.at,
        nextBottleAt: b.at.toDate(),
        windowStartAt: null,
        windowEndAt: null,
        suggestedMl: b.suggestedMl,
      }));
  }
```

   et les deux échéances historiques reçoivent `suggestedMl: plan.suggestedMl`. Mettre à jour le commentaire : « Échéances à rappeler : chaque créneau de la grille, sinon (ancienne app) le prochain biberon puis le premier du matin en secours. »
3. Dans le handler, avant `.find(...)`, n'écarter que pour la grille les créneaux antérieurs au dernier rappelé :

```ts
      const fromGrid = Boolean(plan.upcomingBottles?.length);
      const deadline = deadlinesOf(plan)
        .filter((d) => !fromGrid || !lastNotifiedFor || d.nextBottleAt.getTime() > lastNotifiedFor.getTime())
        .find((d) => isReminderDue({ … inchangé … }));
```

4. Le message utilise `deadline.suggestedMl` au lieu de `plan.suggestedMl`.

- [ ] **Step 4 : tests verts et build**

Run : `cd functions && npm test && npm run build`
Expected : tous les tests verts, `tsc` sans erreur.

- [ ] **Step 5 : commit**

```bash
git add functions/src/lib/types.ts functions/src/bottle-reminder.ts functions/src/bottle-reminder.test.ts
git commit -m "feat: rappel 10 min avant chaque horaire de biberon"
```

---

### Tâche 6 : vérification finale

- [ ] **Step 1 :** `grep -rn "margin\|upcomingMorning\|feedsPerDaySummary" lib test` ne renvoie rien de lié aux biberons ; la doc de `ComputeFeedingPlan` et `ProjectBottleSchedule` ne parle plus d'intervalle ni de « rythme du foyer » au sens ancien (« grille du foyer »).
- [ ] **Step 2 :** `dart format lib test && dart analyze && flutter test` puis `cd functions && npm test && npm run build`. Tout vert.
- [ ] **Step 3 :** si `README.md` ou `functions/README*` décrivent premier biberon / soir / intervalle, les mettre à jour ; commit `docs: …`.
- [ ] **Step 4 :** construire pour le simulateur (`flutter build ios --simulator`) pour vérifier la compilation iOS.
