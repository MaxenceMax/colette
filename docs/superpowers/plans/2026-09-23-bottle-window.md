# Fourchette du prochain biberon et timeline 24 h — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal :** remplacer l'heure précise du prochain biberon par une fourchette (±15 % de l'intervalle, bornes arrondies aux 5 min), caler le rappel push sur l'ouverture de la fourchette et ajouter une feuille « Prochaines 24 h ».

**Architecture :** la fourchette est calculée dans le domaine (`ComputeFeedingPlan`) et exposée par `FeedingPlan`. Un nouveau use case pur `ProjectBottleSchedule` projette les prises sur 24 h. Le snapshot Firestore porte les bornes pour la Cloud Function, qui garde l'ancienne règle quand elles manquent.

**Tech Stack :** Flutter, Riverpod 3 codegen, freezed, fake_cloud_firestore, mocktail ; Cloud Functions TypeScript + vitest.

Spec : `docs/superpowers/specs/2026-09-23-bottle-window-design.md`.

Commandes de vérification (depuis la racine du worktree) :

- `dart run build_runner build -d` après toute modification d'un fichier annoté.
- `flutter gen-l10n` après toute modification de `lib/l10n/app_fr.arb`.
- `flutter test <fichier>` ; en fin de plan `dart format lib test`, `dart analyze`, `flutter test`.
- Cloud Functions : `cd functions && npm test && npm run build`.

---

## Task 1 : fourchette dans `ComputeFeedingPlan`

**Files :**
- Modify : `lib/features/dashboard/domain/entities/feeding_plan.dart`
- Modify : `lib/features/dashboard/domain/use_cases/compute_feeding_plan.dart`
- Test : `test/features/dashboard/domain/compute_feeding_plan_test.dart`

- [x] **Step 1 : tests rouges.** Ajouter un groupe `fourchette` et adapter le test de retard :

```dart
  group('fourchette', () {
    test('arrondi aux 5 min, secondes ignorées', () {
      expect(
        ComputeFeedingPlan.roundTo5Minutes(DateTime(2026, 9, 10, 7, 43)),
        DateTime(2026, 9, 10, 7, 45),
      );
      expect(
        ComputeFeedingPlan.roundTo5Minutes(DateTime(2026, 9, 10, 7, 42, 50)),
        DateTime(2026, 9, 10, 7, 40),
      );
      expect(
        ComputeFeedingPlan.roundTo5Minutes(DateTime(2026, 9, 10, 8, 37)),
        DateTime(2026, 9, 10, 8, 35),
      );
    });

    (int, DateTime, DateTime) windowFor(int feeds, DateTime last) {
      final bottle = makeEvent(id: 'a', startAt: last, bottleMl: 60);
      final plan = compute(
        birthDate: birth,
        latestWeightGrams: 3600,
        feedsPerDay: feeds,
        todayBottles: [bottle],
        lastBottle: bottle,
        now: last,
      );
      return (plan.feedsPerDay, plan.windowStart, plan.windowEnd);
    }

    test('8 prises : ±27 min autour de dernier + 3 h', () {
      final (_, start, end) = windowFor(8, DateTime(2026, 9, 10, 5, 10));
      expect(start, DateTime(2026, 9, 10, 7, 45));
      expect(end, DateTime(2026, 9, 10, 8, 35));
    });

    test('6 prises : ±36 min autour de dernier + 4 h', () {
      final (_, start, end) = windowFor(6, DateTime(2026, 9, 10, 6));
      expect(start, DateTime(2026, 9, 10, 9, 25));
      expect(end, DateTime(2026, 9, 10, 10, 35));
    });

    test('12 prises : ±18 min autour de dernier + 2 h', () {
      final (_, start, end) = windowFor(12, DateTime(2026, 9, 10, 6));
      expect(start, DateTime(2026, 9, 10, 7, 40));
      expect(end, DateTime(2026, 9, 10, 8, 20));
    });

    test('sans biberon : fourchette réduite à maintenant', () {
      final now = DateTime(2026, 9, 10, 12, 3);
      final plan = compute(
        birthDate: birth,
        latestWeightGrams: 3600,
        feedsPerDay: 8,
        todayBottles: const [],
        lastBottle: null,
        now: now,
      );
      expect(plan.windowStart, now);
      expect(plan.windowEnd, now);
      expect(plan.hasWindow, isFalse);
    });
  });
```

Remplacer le test « le retard est calculé depuis le dernier biberon + intervalle » par :

```dart
  test('le retard est compté depuis la fin de la fourchette', () {
    final last = makeEvent(
      id: 'a',
      startAt: DateTime(2026, 9, 10, 6),
      bottleMl: 90,
    );
    final plan = compute(
      birthDate: birth,
      latestWeightGrams: 3600,
      feedsPerDay: 8,
      todayBottles: [last],
      lastBottle: last,
      now: DateTime(2026, 9, 10, 10),
    );
    expect(plan.nextBottleAt, DateTime(2026, 9, 10, 9));
    expect(plan.windowEnd, DateTime(2026, 9, 10, 9, 25));
    expect(plan.hasWindow, isTrue);
    expect(plan.lateBy(DateTime(2026, 9, 10, 9, 20)), Duration.zero);
    expect(plan.lateBy(DateTime(2026, 9, 10, 10)), const Duration(minutes: 35));
  });
```

- [x] **Step 2 :** `flutter test test/features/dashboard/domain/compute_feeding_plan_test.dart` → échec de compilation (`roundTo5Minutes`, `windowStart`, `hasWindow` inconnus).

- [x] **Step 3 : implémentation.** Dans `FeedingPlan`, après `nextBottleAt` :

```dart
    /// Heure centrale du prochain biberon.
    required DateTime nextBottleAt,

    /// Début de la fourchette du prochain biberon.
    required DateTime windowStart,

    /// Fin de la fourchette ; égale au début sans biberon enregistré.
    required DateTime windowEnd,
```

et remplacer `lateBy` :

```dart
  /// Vrai si la fourchette a une largeur (au moins un biberon enregistré).
  bool get hasWindow => windowStart.isBefore(windowEnd);

  /// Retard compté depuis la fin de la fourchette, ou zéro.
  Duration lateBy(DateTime now) =>
      now.isAfter(windowEnd) ? now.difference(windowEnd) : Duration.zero;
```

Dans `ComputeFeedingPlan.call` :

```dart
    final (omsTargetMl, estimated) = (
      dailyTargetFor(dayOfLife: day, latestWeightGrams: latestWeightGrams),
      latestWeightGrams == null,
    );
    final dailyTargetMl = dailyTargetMlOverride ?? omsTargetMl;
    final interval = intervalFor(safeFeedsPerDay);
    final nextBottleAt = lastBottle == null
        ? now
        : lastBottle.startAt.add(interval);
    final (windowStart, windowEnd) = lastBottle == null
        ? (now, now)
        : windowAround(nextBottleAt, interval);
```

et passer `windowStart`, `windowEnd` au constructeur. Helpers statiques :

```dart
  /// Demi-largeur de la fourchette, en fraction de l'intervalle.
  static const windowHalfWidthRatio = 0.15;

  /// Intervalle entre deux prises ; `feedsPerDay` borné à 1 minimum.
  static Duration intervalFor(int feedsPerDay) =>
      Duration(minutes: (24 * 60 / max(1, feedsPerDay)).round());

  /// Fourchette à ±15 % de l'intervalle autour de `center`, arrondie aux 5 min.
  static (DateTime, DateTime) windowAround(DateTime center, Duration interval) {
    final half = Duration(
      minutes: (interval.inMinutes * windowHalfWidthRatio).round(),
    );
    return (
      roundTo5Minutes(center.subtract(half)),
      roundTo5Minutes(center.add(half)),
    );
  }

  /// Arrondi aux 5 minutes les plus proches, secondes ignorées.
  static DateTime roundTo5Minutes(DateTime time) {
    final minutes =
        time.microsecondsSinceEpoch ~/ Duration.microsecondsPerMinute;
    final rounded = (minutes / 5).round() * 5;
    return DateTime.fromMicrosecondsSinceEpoch(
      rounded * Duration.microsecondsPerMinute,
      isUtc: time.isUtc,
    );
  }

  /// Cible OMS : au poids si une pesée est connue, sinon repères par âge.
  static int dailyTargetFor({
    required int dayOfLife,
    required int? latestWeightGrams,
  }) => switch (latestWeightGrams) {
    null => dailyTargetFromAge(dayOfLife),
    final grams => weightTargetMl(dayOfLife, grams),
  };
```

- [x] **Step 4 :** `dart run build_runner build -d` puis relancer le test → vert.
- [x] **Step 5 :** commit `feat: fourchette de ±15 % autour du prochain biberon`.

## Task 2 : projection des 24 prochaines heures

**Files :**
- Create : `lib/features/dashboard/domain/entities/projected_bottle.dart`
- Create : `lib/features/dashboard/domain/use_cases/project_bottle_schedule.dart`
- Test : `test/features/dashboard/domain/project_bottle_schedule_test.dart`

- [x] **Step 1 : tests rouges.**

```dart
import 'package:colette/features/dashboard/domain/use_cases/compute_feeding_plan.dart';
import 'package:colette/features/dashboard/domain/use_cases/project_bottle_schedule.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/care_event_factory.dart';

void main() {
  const project = ProjectBottleSchedule();
  // Jour 3 le 10 septembre (100 ml/kg), jour 4 le 11 (120 ml/kg).
  final birth = DateTime(2026, 9, 8);

  List<DateTime> centers(List<dynamic> bottles) =>
      [for (final b in bottles) b.at as DateTime];

  ({List<CareEvent> today, CareEvent? last}) history(DateTime? lastAt) {
    if (lastAt == null) return (today: const [], last: null);
    final bottle = makeEvent(id: 'b', startAt: lastAt, bottleMl: 60);
    return (today: [bottle], last: bottle);
  }

  test('8 prises : le prochain puis toutes les 3 h jusqu\'à 24 h', () {
    final now = DateTime(2026, 9, 10, 10);
    final h = history(DateTime(2026, 9, 10, 9));
    final plan = const ComputeFeedingPlan()(
      birthDate: birth,
      latestWeightGrams: 3600,
      feedsPerDay: 8,
      todayBottles: h.today,
      lastBottle: h.last,
      now: now,
    );
    final bottles = project(
      plan: plan,
      birthDate: birth,
      latestWeightGrams: 3600,
      now: now,
    );
    expect(centers(bottles), [
      DateTime(2026, 9, 10, 12),
      DateTime(2026, 9, 10, 15),
      DateTime(2026, 9, 10, 18),
      DateTime(2026, 9, 10, 21),
      DateTime(2026, 9, 11, 0),
      DateTime(2026, 9, 11, 3),
      DateTime(2026, 9, 11, 6),
      DateTime(2026, 9, 11, 9),
    ]);
    expect(bottles.first.windowStart, DateTime(2026, 9, 10, 11, 35));
    expect(bottles.first.windowEnd, DateTime(2026, 9, 10, 12, 25));
    expect(bottles[1].windowStart, DateTime(2026, 9, 10, 14, 35));
    expect(bottles[1].windowEnd, DateTime(2026, 9, 10, 15, 25));
    // Aujourd'hui : (360 − 60) / 7 = 42,9 → 40. Demain : 430 / 8 = 53,8 → 50.
    expect(bottles.take(4).map((b) => b.suggestedMl), everyElement(40));
    expect(bottles.skip(4).map((b) => b.suggestedMl), everyElement(50));
  });

  test('en retard : la suite repart de maintenant', () {
    final now = DateTime(2026, 9, 10, 10);
    final h = history(DateTime(2026, 9, 10, 6));
    final plan = const ComputeFeedingPlan()(
      birthDate: birth,
      latestWeightGrams: 3600,
      feedsPerDay: 8,
      todayBottles: h.today,
      lastBottle: h.last,
      now: now,
    );
    final bottles = project(
      plan: plan,
      birthDate: birth,
      latestWeightGrams: 3600,
      now: now,
    );
    expect(bottles.first.at, DateTime(2026, 9, 10, 9));
    expect(bottles[1].at, DateTime(2026, 9, 10, 13));
    expect(bottles.last.at, DateTime(2026, 9, 11, 7));
  });

  test('sans biberon : maintenant, puis dans 3 h', () {
    final now = DateTime(2026, 9, 10, 10);
    final plan = const ComputeFeedingPlan()(
      birthDate: birth,
      latestWeightGrams: 3600,
      feedsPerDay: 8,
      todayBottles: const [],
      lastBottle: null,
      now: now,
    );
    final bottles = project(
      plan: plan,
      birthDate: birth,
      latestWeightGrams: 3600,
      now: now,
    );
    expect(bottles.first.windowStart, now);
    expect(bottles.first.windowEnd, now);
    expect(bottles[1].at, DateTime(2026, 9, 10, 13));
  });

  test('cible ajustée pour demain, bornée à 240 ml', () {
    final now = DateTime(2026, 9, 10, 20);
    final h = history(DateTime(2026, 9, 10, 19));
    final plan = const ComputeFeedingPlan()(
      birthDate: birth,
      latestWeightGrams: 3600,
      feedsPerDay: 8,
      todayBottles: h.today,
      lastBottle: h.last,
      now: now,
      dailyTargetMlOverride: 3000,
    );
    final bottles = project(
      plan: plan,
      birthDate: birth,
      latestWeightGrams: 3600,
      now: now,
      dailyTargetMlOverride: 3000,
    );
    expect(bottles.last.suggestedMl, ComputeFeedingPlan.maxSuggestedMl);
  });
}
```

- [x] **Step 2 :** `flutter test test/features/dashboard/domain/project_bottle_schedule_test.dart` → échec (fichiers absents).

- [x] **Step 3 : implémentation.** `projected_bottle.dart` :

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'projected_bottle.freezed.dart';

/// Biberon prévu dans la timeline des 24 prochaines heures.
@freezed
abstract class ProjectedBottle with _$ProjectedBottle {
  const factory ProjectedBottle({
    /// Heure centrale de la prise.
    required DateTime at,
    required DateTime windowStart,
    required DateTime windowEnd,
    required int suggestedMl,
  }) = _ProjectedBottle;
}
```

`project_bottle_schedule.dart` :

```dart
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/dashboard/domain/entities/feeding_plan.dart';
import 'package:colette/features/dashboard/domain/entities/projected_bottle.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_feeding_plan.dart';

/// Projette les biberons des 24 prochaines heures à partir du plan du jour.
///
/// Le premier est le prochain biberon du plan ; les suivants partent de
/// `max(nextBottleAt, now)` et sont espacés de l'intervalle. Les prises du
/// lendemain suivent la cible de demain répartie sur `feedsPerDay`.
class ProjectBottleSchedule {
  const ProjectBottleSchedule();

  static const horizon = Duration(hours: 24);

  List<ProjectedBottle> call({
    required FeedingPlan plan,
    required DateTime birthDate,
    required int? latestWeightGrams,
    required DateTime now,
    int? dailyTargetMlOverride,
  }) {
    final interval = ComputeFeedingPlan.intervalFor(plan.feedsPerDay);
    final end = now.add(horizon);
    final tomorrowMl = _tomorrowSuggestedMl(
      plan: plan,
      birthDate: birthDate,
      latestWeightGrams: latestWeightGrams,
      now: now,
      dailyTargetMlOverride: dailyTargetMlOverride,
    );
    final anchor = plan.nextBottleAt.isAfter(now) ? plan.nextBottleAt : now;
    final bottles = [
      ProjectedBottle(
        at: plan.nextBottleAt,
        windowStart: plan.windowStart,
        windowEnd: plan.windowEnd,
        suggestedMl: plan.suggestedMl,
      ),
    ];
    for (
      var at = anchor.add(interval);
      at.isBefore(end);
      at = at.add(interval)
    ) {
      final (windowStart, windowEnd) = ComputeFeedingPlan.windowAround(
        at,
        interval,
      );
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

  static int _tomorrowSuggestedMl({
    required FeedingPlan plan,
    required DateTime birthDate,
    required int? latestWeightGrams,
    required DateTime now,
    required int? dailyTargetMlOverride,
  }) {
    final day = ComputeFeedingPlan.dayOfLife(birthDate, now.startOfNextDay);
    final target =
        dailyTargetMlOverride ??
        ComputeFeedingPlan.dailyTargetFor(
          dayOfLife: day,
          latestWeightGrams: latestWeightGrams,
        );
    return ComputeFeedingPlan.roundTo10(target / plan.feedsPerDay).clamp(
      ComputeFeedingPlan.minSuggestedMl,
      ComputeFeedingPlan.maxSuggestedMl,
    );
  }
}
```

- [x] **Step 4 :** build_runner puis test → vert.
- [x] **Step 5 :** commit `feat: projection des biberons sur les 24 prochaines heures`.

## Task 3 : bornes dans le snapshot Firestore

**Files :**
- Modify : `lib/features/baby/domain/entities/feeding_plan_snapshot.dart`
- Modify : `lib/features/baby/data/repositories/firestore_baby_repository.dart:67-78`
- Modify : `lib/features/dashboard/presentation/providers/feeding_plan_sync.dart:63-70`
- Test : `test/features/baby/data/firestore_baby_repository_test.dart`, `test/features/dashboard/presentation/feeding_plan_sync_test.dart`

- [x] **Step 1 : tests rouges.** Dans le test repository `saveFeedingPlan`, passer `windowStartAt: DateTime(2026, 9, 21, 13, 35)`, `windowEndAt: DateTime(2026, 9, 21, 14, 25)` et ajouter :

```dart
    final plan = data['feedingPlan'] as Map<String, dynamic>;
    expect(
      (plan['windowStartAt'] as Timestamp).toDate(),
      DateTime(2026, 9, 21, 13, 35),
    );
    expect(
      (plan['windowEndAt'] as Timestamp).toDate(),
      DateTime(2026, 9, 21, 14, 25),
    );
```

Dans le premier test de `feeding_plan_sync_test.dart` (biberon 9h, maintenant 12h) :

```dart
      expect(
        (plan['windowStartAt'] as Timestamp).toDate(),
        DateTime(2026, 9, 10, 11, 35),
      );
      expect(
        (plan['windowEndAt'] as Timestamp).toDate(),
        DateTime(2026, 9, 10, 12, 25),
      );
```

- [x] **Step 2 :** tests → rouges.
- [x] **Step 3 : implémentation.** Snapshot :

```dart
    required DateTime nextBottleAt,
    required DateTime windowStartAt,
    required DateTime windowEndAt,
```

Repository : ajouter `'windowStartAt': Timestamp.fromDate(snapshot.windowStartAt)` et `'windowEndAt': Timestamp.fromDate(snapshot.windowEndAt)`. Sync : `windowStartAt: plan.windowStart, windowEndAt: plan.windowEnd`.

- [x] **Step 4 :** build_runner, tests → verts.
- [x] **Step 5 :** commit `feat: bornes de la fourchette dans le snapshot feedingPlan`.

## Task 4 : rappel à l'ouverture de la fourchette (Cloud Functions)

**Files :**
- Modify : `functions/src/lib/types.ts`, `functions/src/lib/reminder.ts`, `functions/src/bottle-reminder.ts`
- Test : `functions/src/lib/reminder.test.ts`, `functions/src/bottle-reminder.test.ts`

- [x] **Step 1 : tests rouges.** `reminder.test.ts`, nouveau bloc :

```ts
describe('isReminderDue avec fourchette', () => {
  const next = new Date('2026-09-21T12:30:00Z');
  const windowStartAt = new Date('2026-09-21T12:05:00Z');
  const windowEndAt = new Date('2026-09-21T12:55:00Z');
  const computedAt = new Date('2026-09-21T09:30:00Z');
  const base = { nextBottleAt: next, windowStartAt, windowEndAt, computedAt, lastNotifiedFor: null };

  it('pas avant l’ouverture de la fourchette', () => {
    expect(isReminderDue({ ...base, now: new Date('2026-09-21T12:00:00Z') })).toBe(false);
  });

  it('dû dès l’ouverture', () => {
    expect(isReminderDue({ ...base, now: windowStartAt })).toBe(true);
  });

  it('encore dû à la fermeture, plus après', () => {
    expect(isReminderDue({ ...base, now: windowEndAt })).toBe(true);
    expect(isReminderDue({ ...base, now: new Date(windowEndAt.getTime() + 60 * 1000) })).toBe(false);
  });

  it('jamais deux fois pour la même échéance', () => {
    expect(isReminderDue({ ...base, lastNotifiedFor: next, now: windowStartAt })).toBe(false);
  });

  it('plan calculé fourchette ouverte : rien à rappeler', () => {
    expect(isReminderDue({ ...base, computedAt: windowStartAt, now: windowStartAt })).toBe(false);
  });
});
```

`bottle-reminder.test.ts`, nouveau test :

```ts
  it('avec fourchette : notifie à son ouverture avec la borne de fin', async () => {
    const start = new Date(Date.now() - 60 * 1000);
    const end = new Date(start.getTime() + 50 * 60 * 1000);
    const plan: FeedingPlanDoc = {
      nextBottleAt: Timestamp.fromDate(new Date(start.getTime() + 25 * 60 * 1000)),
      windowStartAt: Timestamp.fromDate(start),
      windowEndAt: Timestamp.fromDate(end),
      suggestedMl: 120,
      computedAt: Timestamp.fromDate(new Date(start.getTime() - 3 * 60 * 60 * 1000)),
    };
    households.push({ id: 'ABC123', fields: { feedingPlan: plan }, devices: [{ id: 'd1' }] });

    await handler();

    const [, , payload] = sendToDevices.mock.calls[0];
    expect(payload.title).toBe('Biberon possible dès maintenant');
    expect(payload.body).toBe(`Environ 120 ml, d'ici ${formatHourMinute(end)}`);
    expect(updates).toEqual([{ household: 'ABC123', data: { lastBottleNotifiedFor: plan.nextBottleAt } }]);
  });
```

(importer `formatHourMinute` depuis `./lib/paris-time`).

- [x] **Step 2 :** `cd functions && npm test` → rouges.
- [x] **Step 3 : implémentation.** `types.ts` : `windowStartAt?: Timestamp; windowEndAt?: Timestamp;` dans `FeedingPlanDoc`. `reminder.ts` :

```ts
type Input = {
  nextBottleAt: Date;
  windowStartAt?: Date | null;
  windowEndAt?: Date | null;
  computedAt: Date | null;
  lastNotifiedFor: Date | null;
  now: Date;
};

/**
 * Avec fourchette : dû de son ouverture à sa fermeture, une seule fois par échéance ;
 * un plan calculé fourchette déjà ouverte ne déclenche rien.
 * Sans fourchette (snapshot d'une ancienne version de l'app) : dû entre 10 min avant
 * l'échéance et 15 min après ; un plan calculé à ou après son échéance ne déclenche rien.
 */
export function isReminderDue({ nextBottleAt, windowStartAt, windowEndAt, computedAt, lastNotifiedFor, now }: Input): boolean {
  if (lastNotifiedFor && lastNotifiedFor.getTime() === nextBottleAt.getTime()) return false;
  if (windowStartAt && windowEndAt) {
    if (computedAt && computedAt.getTime() >= windowStartAt.getTime()) return false;
    return windowStartAt.getTime() <= now.getTime() && now.getTime() <= windowEndAt.getTime();
  }
  if (computedAt && computedAt.getTime() >= nextBottleAt.getTime()) return false;
  if (now.getTime() > nextBottleAt.getTime() + REMINDER_TOLERANCE_MS) return false;
  return nextBottleAt.getTime() - REMINDER_LEAD_MS <= now.getTime();
}
```

`bottle-reminder.ts` : lire `windowStartAt`/`windowEndAt` (`?.toDate() ?? null`), les passer à `isReminderDue`, et construire le message :

```ts
/** Texte du rappel : fourchette si le snapshot en porte une, sinon ancienne formulation. */
export function bottleMessage(suggestedMl: number, nextBottleAt: Date, windowEndAt: Date | null) {
  return windowEndAt
    ? { title: 'Biberon possible dès maintenant', body: `Environ ${suggestedMl} ml, d'ici ${formatHourMinute(windowEndAt)}` }
    : { title: 'Biberon dans 10 min', body: `Environ ${suggestedMl} ml, prévu vers ${formatHourMinute(nextBottleAt)}` };
}
```

- [x] **Step 4 :** `npm test && npm run build` → verts.
- [x] **Step 5 :** commit `feat: rappel biberon à l'ouverture de la fourchette`.

## Task 5 : carte « Prochain biberon », feuille « Prochaines 24 h »

**Files :**
- Modify : `lib/l10n/app_fr.arb`
- Modify : `lib/features/dashboard/presentation/providers/dashboard_providers.dart`
- Modify : `lib/features/dashboard/presentation/widgets/next_bottle_card.dart`
- Create : `lib/features/dashboard/presentation/widgets/bottle_schedule_sheet.dart`
- Test : `test/features/dashboard/presentation/dashboard_page_test.dart`, `test/features/dashboard/presentation/bottle_schedule_sheet_test.dart`

- [x] **Step 1 : l10n.** Remplacer `nextBottleAt` par :

```json
  "nextBottleWindow": "entre {start} et {end}",
  "@nextBottleWindow": { "placeholders": { "start": { "type": "String" }, "end": { "type": "String" } } },
  "nextBottleNowUntil": "maintenant, jusqu'à {end}",
  "@nextBottleNowUntil": { "placeholders": { "end": { "type": "String" } } },
  "bottleScheduleTooltip": "Prochaines 24 h",
  "bottleScheduleTitle": "Prochaines 24 h",
  "bottleScheduleHint": "Prévisions indicatives : suivez aussi les signes de faim.",
  "bottleScheduleToday": "Aujourd'hui",
  "bottleScheduleTomorrow": "Demain",
  "bottleScheduleRange": "{start} – {end}",
  "@bottleScheduleRange": { "placeholders": { "start": { "type": "String" }, "end": { "type": "String" } } },
```

puis `flutter gen-l10n`.

- [x] **Step 2 : tests rouges.** Dans `dashboard_page_test.dart` : le premier test attend désormais `en retard de 35 min` (biberon 8h, fourchette 10h35–11h25, maintenant 12h). Ajouter :

```dart
  testWidgets('avant la fourchette, la carte affiche ses bornes', (
    tester,
  ) async {
    final recentBottle = makeEvent(
      id: 'r',
      startAt: DateTime(2026, 9, 10, 11),
      bottleMl: 60,
    );
    await pumpApp(
      tester,
      const DashboardPage(),
      overrides: [
        ...overridesFor(MockEventsRepository()),
        latestBottleProvider.overrideWith((ref) => Stream.value(recentBottle)),
      ],
    );
    expect(find.text('entre 13h35 et 14h25'), findsOneWidget);
  });

  testWidgets('dans la fourchette, la carte affiche sa fin', (tester) async {
    final recentBottle = makeEvent(
      id: 'r',
      startAt: DateTime(2026, 9, 10, 9, 10),
      bottleMl: 60,
    );
    await pumpApp(
      tester,
      const DashboardPage(),
      overrides: [
        ...overridesFor(MockEventsRepository()),
        latestBottleProvider.overrideWith((ref) => Stream.value(recentBottle)),
      ],
    );
    expect(find.text('maintenant, jusqu\'à 12h35'), findsOneWidget);
  });

  testWidgets('le bouton horloge ouvre la feuille des 24 prochaines heures', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const DashboardPage(),
      overrides: overridesFor(MockEventsRepository()),
    );
    await tester.tap(find.byTooltip('Prochaines 24 h'));
    await tester.pumpAndSettle();
    expect(find.text('Prochaines 24 h'), findsWidgets);
    expect(find.text('Demain'), findsOneWidget);
  });
```

(Si une surcharge en double de `latestBottleProvider` est refusée, ajouter un paramètre `CareEvent? latest` à `overridesFor`.)

`bottle_schedule_sheet_test.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/features/dashboard/domain/entities/projected_bottle.dart';
import 'package:colette/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:colette/features/dashboard/presentation/widgets/bottle_schedule_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  final now = DateTime(2026, 9, 10, 22);

  ProjectedBottle bottle(DateTime at, int ml) => ProjectedBottle(
    at: at,
    windowStart: at.subtract(const Duration(minutes: 25)),
    windowEnd: at.add(const Duration(minutes: 25)),
    suggestedMl: ml,
  );

  Future<void> pumpSheet(WidgetTester tester, List<ProjectedBottle> bottles) =>
      pumpApp(
        tester,
        const Scaffold(body: BottleScheduleSheet()),
        overrides: [
          clockProvider.overrideWithValue(FixedClock(now)),
          minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
          bottleScheduleProvider.overrideWithValue(bottles),
        ],
      );

  testWidgets('groupe par jour avec fourchette et quantité', (tester) async {
    await pumpSheet(tester, [
      bottle(DateTime(2026, 9, 10, 23), 70),
      bottle(DateTime(2026, 9, 11, 2), 80),
    ]);
    expect(find.text('Aujourd\'hui'), findsOneWidget);
    expect(find.text('Demain'), findsOneWidget);
    expect(find.text('22h35 – 23h25'), findsOneWidget);
    expect(find.text('70 ml'), findsOneWidget);
    expect(find.text('01h35 – 02h25'), findsOneWidget);
    expect(find.text('80 ml'), findsOneWidget);
  });

  testWidgets('le prochain biberon en retard porte la mention', (
    tester,
  ) async {
    await pumpSheet(tester, [
      bottle(DateTime(2026, 9, 10, 21), 70),
      bottle(DateTime(2026, 9, 11, 1), 80),
    ]);
    expect(find.text('en retard de 35 min'), findsOneWidget);
    expect(find.text('Aujourd\'hui'), findsOneWidget);
  });

  testWidgets('le prochain biberon en cours porte « maintenant »', (
    tester,
  ) async {
    await pumpSheet(tester, [bottle(DateTime(2026, 9, 10, 22, 10), 70)]);
    expect(find.text('maintenant'), findsOneWidget);
  });
}
```

- [x] **Step 3 :** tests → rouges.

- [x] **Step 4 : provider.** Dans `dashboard_providers.dart` :

```dart
/// Biberons prévus sur les 24 prochaines heures ; `null` sans plan.
@riverpod
List<ProjectedBottle>? bottleSchedule(Ref ref) {
  final plan = ref.watch(feedingPlanProvider);
  final profile = ref.watch(babyProfileProvider).value;
  if (plan == null || profile == null) return null;
  return const ProjectBottleSchedule()(
    plan: plan,
    birthDate: profile.birthDate,
    latestWeightGrams: ref.watch(latestWeightProvider)?.grams,
    now: ref.watch(currentMinuteProvider),
    dailyTargetMlOverride: profile.careSettings.dailyTargetMl,
  );
}
```

- [x] **Step 5 : carte.** Dans l'en-tête, avant le bouton ⓘ :

```dart
              IconButton(
                onPressed: () => showBottleScheduleSheet(context),
                icon: const Icon(Icons.schedule),
                color: context.appColor(AppColors.textSecondary),
                tooltip: s.bottleScheduleTooltip,
              ),
```

`_WhenText.build`, après le cas retard :

```dart
    final end = formatHourMinute(plan.windowEnd);
    final text = now.isBefore(plan.windowStart)
        ? s.nextBottleWindow(formatHourMinute(plan.windowStart), end)
        : plan.hasWindow
        ? s.nextBottleNowUntil(end)
        : s.nextBottleNow;
```

- [x] **Step 6 : feuille** `bottle_schedule_sheet.dart` :

```dart
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/dashboard/domain/entities/projected_bottle.dart';
import 'package:colette/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre la feuille « Prochaines 24 h ».
Future<void> showBottleScheduleSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const BottleScheduleSheet(),
    );

/// Timeline des biberons prévus sur les 24 prochaines heures.
class BottleScheduleSheet extends ConsumerWidget {
  const BottleScheduleSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottles = ref.watch(bottleScheduleProvider);
    if (bottles == null) return const SizedBox.shrink();
    final now = ref.watch(currentMinuteProvider);
    final entries = _entries(bottles, now);
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        Padding(
          padding: AppSpacing.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: .start,
            spacing: AppSpacing.xs.value,
            children: [
              Text(s.bottleScheduleTitle, style: styles.heading2),
              Text(
                s.bottleScheduleHint,
                style: styles.small.copyWith(
                  color: context.appColor(AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: AppSpacing.lg.all,
            itemCount: entries.length,
            itemBuilder: (context, index) => switch (entries[index]) {
              _DayEntry(:final tomorrow) => _DayHeader(tomorrow: tomorrow),
              _BottleEntry(:final bottle, :final isNext) => _BottleRow(
                bottle: bottle,
                now: now,
                isNext: isNext,
              ),
            },
          ),
        ),
      ],
    );
  }

  /// Aplatit les biberons en lignes, précédées d'un en-tête à chaque jour.
  static List<_Entry> _entries(List<ProjectedBottle> bottles, DateTime now) {
    final entries = <_Entry>[];
    DateTime? currentDay;
    for (final (index, bottle) in bottles.indexed) {
      final day = (bottle.at.isAfter(now) ? bottle.at : now).dateOnly;
      if (day != currentDay) {
        entries.add(_DayEntry(tomorrow: day != now.dateOnly));
        currentDay = day;
      }
      entries.add(_BottleEntry(bottle: bottle, isNext: index == 0));
    }
    return entries;
  }
}

sealed class _Entry {
  const _Entry();
}

final class _DayEntry extends _Entry {
  const _DayEntry({required this.tomorrow});

  final bool tomorrow;
}

final class _BottleEntry extends _Entry {
  const _BottleEntry({required this.bottle, required this.isNext});

  final ProjectedBottle bottle;
  final bool isNext;
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.tomorrow});

  final bool tomorrow;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: AppSpacing.symmetric(vertical: AppSpacing.sm),
      child: Text(
        tomorrow ? s.bottleScheduleTomorrow : s.bottleScheduleToday,
        style: Theme.of(context).coletteTextStyles.heading3.copyWith(
          color: context.appColor(AppColors.textSecondary),
        ),
      ),
    );
  }
}

/// Ligne « fourchette … quantité » ; le prochain biberon est surligné.
class _BottleRow extends StatelessWidget {
  const _BottleRow({
    required this.bottle,
    required this.now,
    required this.isNext,
  });

  final ProjectedBottle bottle;
  final DateTime now;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final status = isNext ? _status(s) : null;
    return Container(
      padding: AppSpacing.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isNext ? context.appColor(AppColors.primaryContainer) : null,
        borderRadius: AppRadius.sm.circular,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  s.bottleScheduleRange(
                    formatHourMinute(bottle.windowStart),
                    formatHourMinute(bottle.windowEnd),
                  ),
                  style: isNext ? styles.bodyMedium : styles.body,
                ),
                if (status case (final text, final color))
                  Text(
                    text,
                    style: styles.small.copyWith(
                      color: context.appColor(color),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            s.bottleMl(bottle.suggestedMl),
            style: styles.numberMedium.copyWith(
              color: context.appColor(
                isNext ? AppColors.primary : AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mention du prochain biberon : en retard, en cours, ou rien s'il est à venir.
  (String, AppColor)? _status(S s) {
    if (now.isAfter(bottle.windowEnd)) {
      return (
        s.nextBottleLate(now.difference(bottle.windowEnd).inMinutes),
        AppColors.warning,
      );
    }
    if (!now.isBefore(bottle.windowStart)) {
      return (s.nextBottleNow, AppColors.primary);
    }
    return null;
  }
}
```

(Vérifier le nom du type de couleur exposé par `app_colors.dart` et l'adapter.)

- [x] **Step 7 :** build_runner, `flutter test test/features/dashboard` → vert.
- [x] **Step 8 :** commit `feat: fourchette sur la carte biberon et feuille des 24 prochaines heures`.

## Task 6 : documentation et vérification finale

**Files :**
- Modify : `docs/superpowers/specs/2026-09-21-colette-v1-design.md` (lignes 173, 260, 300, 349), `README.md` si le prochain biberon y est décrit.

- [x] **Step 1 :** mettre à jour la spec v1 : schéma `feedingPlan` (`windowStartAt`, `windowEndAt`), carte (fourchette + bouton timeline), règle de retard (depuis `windowEnd`), `bottleReminder` (ouverture de la fourchette, repli).
- [x] **Step 2 :** `dart format lib test`, `dart analyze`, `flutter test`, `cd functions && npm test && npm run build`.
- [x] **Step 3 :** rendu PNG clair/sombre de la carte et de la feuille en test ponctuel (non commité) ou simulateur si un foyer est disponible.
- [x] **Step 4 :** commit `docs: fourchette du prochain biberon dans la spec v1`.
