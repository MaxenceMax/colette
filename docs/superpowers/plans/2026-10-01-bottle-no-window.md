# Biberons sans fourchette — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal :** remplacer la fourchette de ± 30 min du prochain biberon par une heure précise (premier biberon du matin à l'heure réglée, puis début du dernier biberon + intervalle), avec retard compté depuis l'heure prévue et rappel push 10 min avant.

**Architecture :** la règle `BottleSchedule` ne change pas (sa marge de 30 min devient interne). On retire les champs de fourchette du snapshot Firestore (écrits à `null`), puis on bascule l'affichage sur l'heure prévue, puis on supprime la fourchette du domaine (`FeedingPlan`, `ProjectedBottle`, use cases). La Cloud Function sait déjà rappeler 10 min avant sans fourchette ; seul le rappel de secours du matin est assoupli.

**Tech stack :** Flutter, Dart 3, freezed, Riverpod 3 codegen, fake_cloud_firestore, mocktail ; Cloud Functions TypeScript (vitest).

**Spec :** `docs/superpowers/specs/2026-10-01-bottle-no-window-design.md`

**Worktree :** `/Users/maxencemontet/Documents/colette/.claude/worktrees/bottle-no-window`, branche `feat/bottle-no-window`. Toutes les commandes s'exécutent depuis ce dossier. Ne jamais toucher au checkout principal, ne jamais `git stash` nu. Commits par `git add` de fichiers ciblés (jamais `git add -A`), message en français, terminé par la ligne `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Ne jamais commiter `lib/features/events/presentation/providers/bottle_timer_controller.g.dart` (dérive générée préexistante). Ne jamais lancer `firebase deploy`.

---

## Fichiers

| Fichier | Rôle |
|---|---|
| Modify `functions/src/bottle-reminder.ts` | Rappel du matin sur `morningBottleAt` seul |
| Modify `functions/src/lib/types.ts` | Fourchettes `Timestamp \| null` |
| Modify `functions/src/bottle-reminder.test.ts` | Test du matin sans fourchette |
| Modify `lib/features/baby/domain/entities/feeding_plan_snapshot.dart` | Retrait des 4 champs de fourchette |
| Modify `lib/features/baby/data/repositories/firestore_baby_repository.dart` | Écrit `null` dans les 4 champs |
| Modify `lib/features/dashboard/presentation/providers/feeding_plan_sync.dart` | Ne passe plus de fourchette |
| Modify `lib/features/dashboard/domain/entities/feeding_plan.dart` | `latenessAt`, `lateBy` depuis l'heure prévue ; puis retrait de la fourchette |
| Modify `lib/features/dashboard/presentation/widgets/next_bottle_card.dart` | « à 12h10 », « demain à 07h00 », « maintenant », retard |
| Modify `lib/features/dashboard/presentation/widgets/bottle_schedule_sheet.dart` | Heure par ligne, mention selon `latenessAt` |
| Modify `lib/l10n/app_fr.arb` | +`nextBottleAtTime`, +`nextBottleAtTimeTomorrow` ; −`nextBottleWindow`, −`nextBottleWindowTomorrow`, −`nextBottleGo`, −`bottleScheduleRange` |
| Modify `lib/features/dashboard/domain/entities/projected_bottle.dart` | Retrait de la fourchette |
| Modify `lib/features/dashboard/domain/use_cases/compute_feeding_plan.dart` | Retrait de la fourchette |
| Modify `lib/features/dashboard/domain/use_cases/project_bottle_schedule.dart` | Retrait de la fourchette |
| Modify `lib/features/baby/domain/entities/bottle_schedule.dart` | `halfWindow` → `margin`, retrait de `windowAround` |
| Tests modifiés | `firestore_baby_repository_test`, `feeding_plan_sync_test`, `compute_feeding_plan_test`, `dashboard_page_test`, `bottle_schedule_sheet_test`, `project_bottle_schedule_test`, `bottle_schedule_test` |

---

### Task 0 : préparer le worktree

- [ ] **Step 1 : dépendances et fichiers générés**

`lib/l10n/generated/` n'est pas versionné ; les `.g.dart` / `.freezed.dart` le sont.

```bash
flutter pub get && flutter gen-l10n && dart run build_runner build -d
(cd functions && npm ci)
```

- [ ] **Step 2 : suites de référence**

```bash
flutter test
(cd functions && npm test && npm run build)
```

Attendu : tout vert. Si un test échoue déjà, le noter et prévenir avant d'aller plus loin. `git status` peut montrer `bottle_timer_controller.g.dart` modifié après build_runner : c'est la dérive connue, ne pas la commiter.

---

### Task 1 : Cloud Function — rappel du matin sans fourchette

**Files :**
- Modify : `functions/src/bottle-reminder.ts` (fonction `deadlinesOf`)
- Modify : `functions/src/lib/types.ts` (type `FeedingPlanDoc`)
- Test : `functions/src/bottle-reminder.test.ts` (bloc `describe('deadlinesOf')`)

- [ ] **Step 1 : test rouge**

Dans `describe('deadlinesOf', …)`, après le test « ignore les champs du matin explicitement nuls », ajouter :

```ts
  it('garde le rappel du matin sans fourchette (app sans fourchette)', () => {
    const plan: FeedingPlanDoc = {
      nextBottleAt: at('2026-09-30T21:30:00Z'),
      windowStartAt: null,
      windowEndAt: null,
      suggestedMl: 120,
      morningBottleAt: at('2026-10-01T05:00:00Z'),
      morningWindowStartAt: null,
      morningWindowEndAt: null,
    };

    const deadlines = deadlinesOf(plan);

    expect(deadlines.map((d) => d.key)).toEqual([plan.nextBottleAt, plan.morningBottleAt]);
    expect(deadlines.every((d) => d.windowStartAt === null && d.windowEndAt === null)).toBe(true);
  });

  it('garde les fourchettes du matin écrites par une ancienne version', () => {
    const plan = planWithMorning(at('2026-10-01T05:00:00Z'));

    const morning = deadlinesOf(plan)[1];

    expect(morning.windowStartAt).toEqual(new Date('2026-10-01T04:30:00Z'));
    expect(morning.windowEndAt).toEqual(new Date('2026-10-01T05:30:00Z'));
  });
```

- [ ] **Step 2 : vérifier l'échec**

```bash
cd functions && npx vitest run src/bottle-reminder.test.ts
```

Attendu : échec de compilation TS ou du test (`windowStartAt: null` refusé par le type, et une seule échéance renvoyée).

- [ ] **Step 3 : implémentation**

Dans `functions/src/lib/types.ts`, remplacer le bloc `FeedingPlanDoc` par :

```ts
export type FeedingPlanDoc = {
  nextBottleAt: Timestamp;
  /** Fourchette des versions de l'app qui en écrivaient une ; absente ou nulle sinon
   *  (rappel 10 min avant `nextBottleAt`). */
  windowStartAt?: Timestamp | null;
  windowEndAt?: Timestamp | null;
  suggestedMl: number;
  computedAt?: Timestamp;
  /** Premier biberon du matin après `nextBottleAt` : rappel de secours si aucun biberon
   *  n'est noté d'ici là. Absent ou nul sans biberon. Fourchette du matin : comme ci-dessus. */
  morningBottleAt?: Timestamp | null;
  morningWindowStartAt?: Timestamp | null;
  morningWindowEndAt?: Timestamp | null;
};
```

Dans `functions/src/bottle-reminder.ts`, remplacer le `if (…) { deadlines.push(…) }` de `deadlinesOf` par :

```ts
  if (plan.morningBottleAt && plan.morningBottleAt.toMillis() > plan.nextBottleAt.toMillis()) {
    deadlines.push({
      key: plan.morningBottleAt,
      nextBottleAt: plan.morningBottleAt.toDate(),
      windowStartAt: plan.morningWindowStartAt?.toDate() ?? null,
      windowEndAt: plan.morningWindowEndAt?.toDate() ?? null,
    });
  }
```

Le commentaire au-dessus (« L'app calcule toujours le matin strictement après nextBottleAt… ») reste.

- [ ] **Step 4 : vérifier le vert**

```bash
cd functions && npm test && npm run build
```

Attendu : tous les tests verts, `tsc` sans erreur.

- [ ] **Step 5 : commit**

```bash
git add functions/src/bottle-reminder.ts functions/src/lib/types.ts functions/src/bottle-reminder.test.ts
git commit -m "feat: rappel de secours du matin sans fourchette

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2 : snapshot Firestore sans fourchette

**Files :**
- Modify : `lib/features/baby/domain/entities/feeding_plan_snapshot.dart`
- Modify : `lib/features/baby/data/repositories/firestore_baby_repository.dart` (`saveFeedingPlan`)
- Modify : `lib/features/dashboard/presentation/providers/feeding_plan_sync.dart` (`sync`)
- Test : `test/features/baby/data/firestore_baby_repository_test.dart`, `test/features/dashboard/presentation/feeding_plan_sync_test.dart`

- [ ] **Step 1 : tests rouges**

Dans `firestore_baby_repository_test.dart`, remplacer les deux tests « saveFeedingPlan écrit feedingPlan sans effacer baby » et « saveFeedingPlan sans biberon du matin écrit des clés nulles » par :

```dart
  test('saveFeedingPlan écrit feedingPlan sans effacer baby', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreBabyRepository(db);
    await repo.saveProfile(code, profile);
    await repo.saveFeedingPlan(
      code,
      FeedingPlanSnapshot(
        nextBottleAt: DateTime(2026, 9, 21, 14),
        suggestedMl: 120,
        computedAt: DateTime(2026, 9, 21, 11),
        morningBottleAt: DateTime(2026, 9, 22, 7),
      ),
    );
    final data = (await db.collection('households').doc(code).get()).data()!;
    final plan = data['feedingPlan'] as Map<String, dynamic>;
    expect(plan['suggestedMl'], 120);
    expect(
      (plan['nextBottleAt'] as Timestamp).toDate(),
      DateTime(2026, 9, 21, 14),
    );
    expect(
      (plan['morningBottleAt'] as Timestamp).toDate(),
      DateTime(2026, 9, 22, 7),
    );
    expect(data['baby'], isNotNull);
  });

  test('saveFeedingPlan efface les fourchettes d\'une ancienne version', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreBabyRepository(db);
    await db.collection('households').doc(code).set({
      'feedingPlan': {
        'windowStartAt': Timestamp.fromDate(DateTime(2026, 9, 21, 13, 30)),
        'windowEndAt': Timestamp.fromDate(DateTime(2026, 9, 21, 14, 30)),
        'morningWindowStartAt': Timestamp.fromDate(DateTime(2026, 9, 22, 6, 30)),
        'morningWindowEndAt': Timestamp.fromDate(DateTime(2026, 9, 22, 7, 30)),
      },
    });
    await repo.saveFeedingPlan(
      code,
      FeedingPlanSnapshot(
        nextBottleAt: DateTime(2026, 9, 21, 14),
        suggestedMl: 120,
        computedAt: DateTime(2026, 9, 21, 11),
      ),
    );
    final data = (await db.collection('households').doc(code).get()).data()!;
    final plan = data['feedingPlan'] as Map<String, dynamic>;
    for (final key in [
      'windowStartAt',
      'windowEndAt',
      'morningBottleAt',
      'morningWindowStartAt',
      'morningWindowEndAt',
    ]) {
      expect(plan.containsKey(key), isTrue, reason: key);
      expect(plan[key], isNull, reason: key);
    }
  });
```

Dans `feeding_plan_sync_test.dart`, dans le premier test (dernier biberon à 9 h, `now` 12 h), remplacer les `expect` sur `windowStartAt`, `windowEndAt`, `morningWindowStartAt`, `morningWindowEndAt` par :

```dart
    for (final key in [
      'windowStartAt',
      'windowEndAt',
      'morningWindowStartAt',
      'morningWindowEndAt',
    ]) {
      expect(plan[key], isNull, reason: key);
    }
```

(garder les `expect` sur `nextBottleAt` = 12 h, `suggestedMl` = 70 et `morningBottleAt` = le 11 à 7 h).

- [ ] **Step 2 : vérifier l'échec**

```bash
flutter test test/features/baby/data/firestore_baby_repository_test.dart test/features/dashboard/presentation/feeding_plan_sync_test.dart
```

Attendu : échec de compilation (`windowStartAt` requis dans `FeedingPlanSnapshot`) ou valeurs non nulles.

- [ ] **Step 3 : implémentation**

`feeding_plan_snapshot.dart` devient :

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'feeding_plan_snapshot.freezed.dart';

/// Résumé du plan biberons écrit dans le foyer, lu par les Cloud Functions.
@freezed
abstract class FeedingPlanSnapshot with _$FeedingPlanSnapshot {
  const factory FeedingPlanSnapshot({
    required DateTime nextBottleAt,
    required int suggestedMl,
    required DateTime computedAt,

    /// Premier biberon du matin après [nextBottleAt] : rappel de secours si
    /// aucun biberon n'est noté d'ici là ; `null` sans biberon.
    DateTime? morningBottleAt,
  }) = _FeedingPlanSnapshot;
}
```

Dans `firestore_baby_repository.dart`, le corps de `saveFeedingPlan` devient :

```dart
    () => _household(householdCode).set({
      'feedingPlan': {
        'nextBottleAt': Timestamp.fromDate(snapshot.nextBottleAt),
        'suggestedMl': snapshot.suggestedMl,
        'computedAt': Timestamp.fromDate(snapshot.computedAt),
        'morningBottleAt': _timestampOrNull(snapshot.morningBottleAt),
        // Écriture merge : efface les fourchettes des versions précédentes,
        // la Cloud Function rappelle alors 10 min avant l'heure prévue.
        'windowStartAt': null,
        'windowEndAt': null,
        'morningWindowStartAt': null,
        'morningWindowEndAt': null,
      },
    }, SetOptions(merge: true)),
```

Dans `feeding_plan_sync.dart`, remplacer le bloc `morning` / `morningWindow` et la construction du snapshot par :

```dart
      final morning = lastBottle == null
          ? null
          : schedule.morningAfter(plan.nextBottleAt);
      await babyRepository.saveFeedingPlan(
        code,
        FeedingPlanSnapshot(
          nextBottleAt: plan.nextBottleAt,
          suggestedMl: plan.suggestedMl,
          computedAt: now,
          morningBottleAt: morning,
        ),
      );
```

Puis :

```bash
dart run build_runner build -d
```

- [ ] **Step 4 : vérifier le vert**

```bash
flutter test test/features/baby/data/firestore_baby_repository_test.dart test/features/dashboard/presentation/feeding_plan_sync_test.dart
dart analyze
```

Attendu : tests verts, analyse sans erreur.

- [ ] **Step 5 : commit**

```bash
git add lib/features/baby/domain/entities/feeding_plan_snapshot.dart lib/features/baby/domain/entities/feeding_plan_snapshot.freezed.dart lib/features/baby/data/repositories/firestore_baby_repository.dart lib/features/dashboard/presentation/providers/feeding_plan_sync.dart test/features/baby/data/firestore_baby_repository_test.dart test/features/dashboard/presentation/feeding_plan_sync_test.dart
git commit -m "feat: snapshot du plan biberons sans fourchette

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3 : retard depuis l'heure prévue, carte et feuille 24 h

La fourchette existe encore dans le domaine à ce stade ; l'affichage cesse simplement de l'utiliser.

**Files :**
- Modify : `lib/features/dashboard/domain/entities/feeding_plan.dart`
- Modify : `lib/features/dashboard/presentation/widgets/next_bottle_card.dart` (`_WhenText`, doc de la classe)
- Modify : `lib/features/dashboard/presentation/widgets/bottle_schedule_sheet.dart` (`_BottleRow`)
- Modify : `lib/l10n/app_fr.arb`
- Test : `test/features/dashboard/domain/compute_feeding_plan_test.dart`, `test/features/dashboard/presentation/dashboard_page_test.dart`, `test/features/dashboard/presentation/bottle_schedule_sheet_test.dart`

- [ ] **Step 1 : tests rouges — domaine**

Dans `compute_feeding_plan_test.dart` :

1. Renommer le test « le retard est compté depuis la fin de la fourchette » en « le retard est compté depuis l'heure prévue » et remplacer ses quatre dernières lignes `expect` (après `expect(plan.nextBottleAt, DateTime(2026, 9, 10, 9));`) par :

```dart
    expect(plan.lateBy(DateTime(2026, 9, 10, 9)), Duration.zero);
    expect(
      plan.lateBy(DateTime(2026, 9, 10, 9, 30)),
      const Duration(minutes: 30),
    );
    expect(
      plan.lateBy(DateTime(2026, 9, 10, 10, 5)),
      const Duration(hours: 1, minutes: 5),
    );
```

2. Ajouter, juste après ce test :

```dart
  test('latenessAt ignore un dépassement de moins d\'une minute', () {
    final at = DateTime(2026, 9, 10, 9, 0, 23);
    expect(FeedingPlan.latenessAt(at, DateTime(2026, 9, 10, 9)), Duration.zero);
    expect(
      FeedingPlan.latenessAt(at, DateTime(2026, 9, 10, 9, 1)),
      Duration.zero,
    );
    expect(
      FeedingPlan.latenessAt(at, DateTime(2026, 9, 10, 9, 2)),
      const Duration(minutes: 1, seconds: 37),
    );
  });
```

3. Dans le groupe « biberon manqué » :
   - test « toujours rien à 8 h : en retard depuis 7 h 30 » → renommer « toujours rien à 8 h : en retard depuis 7 h » et attendre `const Duration(hours: 1)` ;
   - test « biberon de journée manqué : en retard l'après-midi » → attendre `const Duration(hours: 2)`.

- [ ] **Step 2 : tests rouges — présentation**

Dans `dashboard_page_test.dart` (`now` = 10 septembre 2026, 12 h) :

| Ligne actuelle | Remplacement |
|---|---|
| commentaire `// (540 − 60) / 6 = 80 ; dernier biberon à 9 h : prochain à 12 h, 11 h 30 – 12 h 30.` | `// (540 − 60) / 6 = 80 ; dernier biberon à 9 h : prochain à 12 h, soit maintenant.` |
| `expect(find.text('Go pour un biberon, jusqu\'à 12h30'), findsOneWidget);` | `expect(find.text('maintenant'), findsOneWidget);` |
| test « avant la fourchette, la carte affiche ses bornes » | renommer « avant l'heure prévue, la carte l'affiche » ; `expect(find.text('à 14h00'), findsOneWidget);` |
| test « le matin du lendemain, la fourchette est annoncée « demain » » | renommer « le premier biberon du lendemain est annoncé « demain » » ; `expect(find.text('demain à 07h00'), findsOneWidget);` |
| test « dans la fourchette, la carte affiche sa fin » (dernier biberon 9 h 10) | renommer « avant l'heure prévue, la carte affiche l'heure » ; `expect(find.text('à 12h10'), findsOneWidget);` (garder l'`expect` « 2 h 50 depuis le dernier biberon ») |
| test « après la fourchette, la carte affiche le retard » (dernier biberon 6 h 25) | renommer « après l'heure prévue, la carte affiche le retard » ; commentaire `// 6 h 25 est un biberon de nuit : prochain à 9 h 25, soit 2 h 35 de retard à midi.` ; `expect(find.text('en retard de 2 h 35'), findsOneWidget);` |

Dans `bottle_schedule_sheet_test.dart` (`now` = 10 septembre 2026, 22 h), garder le helper `bottle` (les fourchettes de ± 25 min doivent être ignorées par l'affichage) et remplacer les tests par :

```dart
  testWidgets('groupe par jour avec heure et quantité', (tester) async {
    await pumpSheet(tester, [
      bottle(DateTime(2026, 9, 10, 23), 70),
      bottle(DateTime(2026, 9, 11, 2), 80),
    ]);
    expect(find.text('Prochaines 24 h'), findsOneWidget);
    expect(find.text('Aujourd\'hui'), findsOneWidget);
    expect(find.text('Demain'), findsOneWidget);
    expect(find.text('23h00'), findsOneWidget);
    expect(find.text('70 ml'), findsOneWidget);
    expect(find.text('02h00'), findsOneWidget);
    expect(find.text('80 ml'), findsOneWidget);
  });

  testWidgets('le prochain biberon en retard porte la mention', (tester) async {
    await pumpSheet(tester, [
      bottle(DateTime(2026, 9, 10, 21, 25), 70),
      bottle(DateTime(2026, 9, 11, 1), 80),
    ]);
    expect(find.text('en retard de 35 min'), findsOneWidget);
    expect(find.text('Aujourd\'hui'), findsOneWidget);
  });

  testWidgets('un retard de plus d\'une heure s\'affiche en heures', (
    tester,
  ) async {
    await pumpSheet(tester, [bottle(DateTime(2026, 9, 10, 20, 25), 70)]);
    // Prévu à 20 h 25 : 1 h 35 de retard à 22 h.
    expect(find.text('en retard de 1 h 35'), findsOneWidget);
  });

  testWidgets('le prochain biberon à l\'heure pile porte « maintenant »', (
    tester,
  ) async {
    await pumpSheet(tester, [bottle(DateTime(2026, 9, 10, 22), 70)]);
    expect(find.text('maintenant'), findsOneWidget);
  });

  testWidgets('un biberon à venir ne porte aucune mention', (tester) async {
    // Fourchette ouverte à 21 h 45 : ignorée, seul compte 22 h 10.
    await pumpSheet(tester, [bottle(DateTime(2026, 9, 10, 22, 10), 70)]);
    expect(find.text('maintenant'), findsNothing);
    expect(find.textContaining('en retard'), findsNothing);
  });
```

- [ ] **Step 3 : vérifier l'échec**

```bash
flutter test test/features/dashboard/domain/compute_feeding_plan_test.dart test/features/dashboard/presentation/dashboard_page_test.dart test/features/dashboard/presentation/bottle_schedule_sheet_test.dart
```

Attendu : échecs (`latenessAt` inexistant, anciens textes affichés).

- [ ] **Step 4 : implémentation — domaine**

Dans `feeding_plan.dart`, remplacer la méthode `lateBy` par :

```dart
  /// Retard sur l'heure prévue du prochain biberon, ou zéro.
  Duration lateBy(DateTime now) => latenessAt(nextBottleAt, now);

  /// Retard de [now] sur [at] ; zéro sous une minute, pour ne pas afficher
  /// « en retard de 0 min » quand l'heure prévue porte des secondes.
  static Duration latenessAt(DateTime at, DateTime now) {
    final late = now.difference(at);
    return late >= const Duration(minutes: 1) ? late : Duration.zero;
  }
```

(`hasWindow` et `isOpen` restent jusqu'à la Task 4.)

- [ ] **Step 5 : implémentation — l10n**

Dans `lib/l10n/app_fr.arb`, remplacer les lignes `nextBottleWindow`, `@nextBottleWindow`, `nextBottleWindowTomorrow`, `@nextBottleWindowTomorrow`, `nextBottleGo`, `@nextBottleGo` par :

```json
  "nextBottleAtTime": "à {time}",
  "@nextBottleAtTime": { "placeholders": { "time": { "type": "String" } } },
  "nextBottleAtTimeTomorrow": "demain à {time}",
  "@nextBottleAtTimeTomorrow": { "placeholders": { "time": { "type": "String" } } },
```

et supprimer les lignes `bottleScheduleRange` et `@bottleScheduleRange`. Puis :

```bash
flutter gen-l10n
```

- [ ] **Step 6 : implémentation — carte**

Dans `next_bottle_card.dart`, doc de la classe : `/// Carte « Prochain biberon » : quantité suggérée, heure prévue, progression du jour.`

Remplacer le `build` de `_WhenText` par :

```dart
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final at = plan.nextBottleAt;
    final late = plan.lateBy(now);
    final (text, color) = switch (at) {
      _ when late > Duration.zero => (
        s.nextBottleLate(formatDuration(late, s)),
        AppColors.warning,
      ),
      _ when !now.isBefore(at) => (s.nextBottleNow, AppColors.success),
      _ when at.dateOnly.isAfter(now.dateOnly) => (
        s.nextBottleAtTimeTomorrow(formatHourMinute(at)),
        AppColors.textSecondary,
      ),
      _ => (s.nextBottleAtTime(formatHourMinute(at)), AppColors.textSecondary),
    };
    return Text(
      text,
      style: Theme.of(
        context,
      ).coletteTextStyles.bodyMedium.copyWith(color: context.appColor(color)),
    );
  }
```

- [ ] **Step 7 : implémentation — feuille 24 h**

Dans `bottle_schedule_sheet.dart` :

- ajouter `import 'package:colette/features/dashboard/domain/entities/feeding_plan.dart';` ;
- doc de `_BottleRow` : `/// Ligne « heure … quantité » ; le prochain biberon est surligné.` ;
- remplacer le `Text(s.bottleScheduleRange(…), …)` par :

```dart
                Text(
                  formatHourMinute(bottle.at),
                  style: isNext ? styles.bodyMedium : styles.body,
                ),
```

- remplacer `_status` par :

```dart
  /// Mention du prochain biberon : en retard, à l'heure, ou rien s'il est à venir.
  (String, AppColors)? _status(S s) {
    final late = FeedingPlan.latenessAt(bottle.at, now);
    if (late > Duration.zero) {
      return (s.nextBottleLate(formatDuration(late, s)), AppColors.warning);
    }
    if (!now.isBefore(bottle.at)) return (s.nextBottleNow, AppColors.primary);
    return null;
  }
```

- [ ] **Step 8 : vérifier le vert**

```bash
dart format lib test
flutter test test/features/dashboard
dart analyze
```

Attendu : tests verts, analyse sans erreur ni avertissement (aucune clé l10n supprimée encore référencée : `grep -rn -e nextBottleWindow -e nextBottleGo -e bottleScheduleRange lib test` ne renvoie rien).

- [ ] **Step 9 : commit**

```bash
git add lib/features/dashboard/domain/entities/feeding_plan.dart lib/features/dashboard/presentation/widgets/next_bottle_card.dart lib/features/dashboard/presentation/widgets/bottle_schedule_sheet.dart lib/l10n/app_fr.arb test/features/dashboard/domain/compute_feeding_plan_test.dart test/features/dashboard/presentation/dashboard_page_test.dart test/features/dashboard/presentation/bottle_schedule_sheet_test.dart
git commit -m "feat: prochain biberon annoncé à l'heure prévue, sans fourchette

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4 : retirer la fourchette du domaine

**Files :**
- Modify : `lib/features/baby/domain/entities/bottle_schedule.dart`
- Modify : `lib/features/dashboard/domain/entities/feeding_plan.dart`
- Modify : `lib/features/dashboard/domain/entities/projected_bottle.dart`
- Modify : `lib/features/dashboard/domain/use_cases/compute_feeding_plan.dart`
- Modify : `lib/features/dashboard/domain/use_cases/project_bottle_schedule.dart`
- Test : `test/features/baby/domain/bottle_schedule_test.dart`, `test/features/dashboard/domain/compute_feeding_plan_test.dart`, `test/features/dashboard/domain/project_bottle_schedule_test.dart`, `test/features/dashboard/presentation/bottle_schedule_sheet_test.dart`

Refactor sans changement de comportement : les tests existants (adaptés) doivent rester verts.

- [ ] **Step 1 : adapter les tests**

`bottle_schedule_test.dart` : supprimer le test « windowAround : de 30 min avant à 30 min après ». Remplacer toute autre occurrence de `BottleSchedule.halfWindow` par `BottleSchedule.margin` (`grep -n halfWindow test` pour les trouver).

`compute_feeding_plan_test.dart` :
- supprimer entièrement le `group('fourchette', …)` (ses cas « 10 h → 13 h », « 22 h → 23 h 30 », « 23 h 10 → 7 h » sont couverts par `bottle_schedule_test`) ;
- dans le test « biberon du soir manqué : la nuit, on attend le matin », supprimer les deux `expect` sur `windowStart` / `windowEnd` ;
- supprimer l'import de `feeding_plan.dart` seulement si `dart analyze` le signale inutilisé (le groupe « biberon manqué » utilise encore `FeedingPlan`).

`project_bottle_schedule_test.dart` :
- premier test : supprimer la boucle `for (final b in bottles) { expect(b.windowStart…); expect(b.windowEnd…); }` ;
- test « fourchette ouverte : la suite part de maintenant » → renommer « heure prévue passée : la suite part de maintenant » et supprimer les deux `expect` sur `bottles[1].windowStart` / `windowEnd` ;
- test « en retard : la suite part de maintenant » : supprimer `expect(bottles.first.windowEnd, …)` ;
- test « sans biberon : maintenant, puis selon l'intervalle » : remplacer son contenu après `final bottles = …` par :

```dart
    expect(bottles.first.at, now);
    expect(bottles[1].at, DateTime(2026, 9, 10, 13));
```

`bottle_schedule_sheet_test.dart` : le helper devient

```dart
  ProjectedBottle bottle(DateTime at, int ml) =>
      ProjectedBottle(at: at, suggestedMl: ml);
```

et le commentaire « // Fourchette ouverte à 21 h 45 : ignorée, seul compte 22 h 10. » est supprimé.

- [ ] **Step 2 : vérifier l'échec**

```bash
flutter test test/features/dashboard/presentation/bottle_schedule_sheet_test.dart test/features/baby/domain/bottle_schedule_test.dart
```

Attendu : échec de compilation (`windowStart` requis dans `ProjectedBottle`, `BottleSchedule.margin` inexistant).

- [ ] **Step 3 : `BottleSchedule`**

Dans `bottle_schedule.dart` :

- remplacer

```dart
  /// Demi-largeur de la fourchette autour de l'heure prévue.
  static const halfWindow = Duration(minutes: 30);
```

par

```dart
  /// Marge de classement, jamais affichée : un biberon donné jusqu'à 30 min
  /// avant le premier du matin compte comme celui-ci, à moins de 30 min du
  /// soir comme celui du soir ; un biberon manqué reste dû 30 min.
  static const margin = Duration(minutes: 30);
```

- remplacer toutes les autres occurrences de `halfWindow` par `margin` (dans `nextAfter`, `upcomingMorning`, `nextDue`) ;
- doc de `upcomingMorning` : `/// Premier biberon de la journée en cours à [now] : celui du jour, puis celui du lendemain dès 30 min avant le biberon du soir.` (sur deux lignes `///`) ;
- doc de `nextDue` : remplacer « une fois sa fourchette finie » par « une fois passées 30 min de retard » ;
- supprimer `windowAround` et son commentaire.

- [ ] **Step 4 : `FeedingPlan` et `ProjectedBottle`**

Dans `feeding_plan.dart` :
- doc de la classe : `/// Plan biberons du jour : cible, progression, heure du prochain biberon.` ;
- doc de `nextBottleAt` : `/// Heure prévue du prochain biberon ; `now` sans biberon enregistré.` ;
- supprimer les champs `windowStart`, `windowEnd` (et leurs commentaires), les getters `hasWindow` et `isOpen`.

`projected_bottle.dart` devient :

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'projected_bottle.freezed.dart';

/// Biberon prévu dans la timeline des 24 prochaines heures.
@freezed
abstract class ProjectedBottle with _$ProjectedBottle {
  const factory ProjectedBottle({
    /// Heure prévue de la prise.
    required DateTime at,
    required int suggestedMl,
  }) = _ProjectedBottle;
}
```

- [ ] **Step 5 : use cases**

`compute_feeding_plan.dart` :
- doc de la classe : remplacer « Le prochain biberon suit le rythme du foyer, fourchette de ± 30 min. » par « Le prochain biberon suit le rythme du foyer, à heure fixe. » ;
- supprimer le bloc `final (windowStart, windowEnd) = …;` et les deux arguments `windowStart:` / `windowEnd:` du constructeur `FeedingPlan`.

`project_bottle_schedule.dart` :
- premier `ProjectedBottle` : `ProjectedBottle(at: plan.nextBottleAt, suggestedMl: plan.suggestedMl),` ;
- dans la boucle, supprimer `final (windowStart, windowEnd) = schedule.windowAround(at);` et les arguments `windowStart:` / `windowEnd:`.

Puis :

```bash
dart run build_runner build -d
```

- [ ] **Step 6 : vérifier le vert**

```bash
dart format lib test
dart analyze
flutter test
grep -rn -e windowAround -e halfWindow -e hasWindow -e isOpen -e windowStart -e windowEnd lib/features/dashboard lib/features/baby test/features/dashboard test/features/baby
```

Attendu : analyse propre, suite complète verte, `grep` sans résultat.

- [ ] **Step 7 : commit**

```bash
git add lib/features/baby/domain/entities/bottle_schedule.dart lib/features/baby/domain/entities/bottle_schedule.freezed.dart lib/features/dashboard/domain/entities/feeding_plan.dart lib/features/dashboard/domain/entities/feeding_plan.freezed.dart lib/features/dashboard/domain/entities/projected_bottle.dart lib/features/dashboard/domain/entities/projected_bottle.freezed.dart lib/features/dashboard/domain/use_cases/compute_feeding_plan.dart lib/features/dashboard/domain/use_cases/project_bottle_schedule.dart test/features/baby/domain/bottle_schedule_test.dart test/features/dashboard/domain/compute_feeding_plan_test.dart test/features/dashboard/domain/project_bottle_schedule_test.dart test/features/dashboard/presentation/bottle_schedule_sheet_test.dart
git commit -m "chore: fourchette du prochain biberon retirée du domaine

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

(`git status` après coup : seuls `bottle_timer_controller.g.dart` et rien d'autre peuvent rester modifiés. Si un `.freezed.dart` listé n'a pas changé, `git add` l'ignore.)

---

### Task 5 : vérification finale

- [ ] **Step 1 : suites complètes**

```bash
dart format lib test
dart analyze
flutter test
(cd functions && npm test && npm run build)
```

Attendu : tout vert.

- [ ] **Step 2 : simulateur (si disponible)**

Lancer l'app sur un simulateur iPhone, onglet Aujourd'hui : la carte « Prochain biberon » affiche « à HHhMM », « demain à HHhMM », « maintenant » ou « en retard de … » ; la feuille « Prochaines 24 h » liste des heures. Vérifier en thème clair et sombre. Si le simulateur n'a pas de foyer, le signaler sans créer de foyer dans Firestore de production.

- [ ] **Step 3 : rapport**

Rapporter au contrôleur : commits de la branche, nombre de tests Flutter et Functions, et rappeler que le redéploiement de `bottleReminder` (`firebase deploy --only functions:bottleReminder`) est à lancer par Maxence après le merge.
