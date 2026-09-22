# Colette v1 — Plan d'implémentation (Cloud Functions, règles et index Firestore)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Déployer les règles et index Firestore et trois Cloud Functions : push à l'autre iPhone quand un événement est créé, rappel 10 min avant le prochain biberon, digest des soins restants le matin.

**Architecture:** Dossier `functions/` TypeScript (CommonJS), Firebase Functions v2 en région `europe-west1`, fuseau `Europe/Paris`. La logique métier (résumé d'événement, soins en attente, échéance du rappel) vit dans `functions/src/lib/` en fonctions pures testées avec Vitest ; les handlers Firebase n'y ajoutent que la lecture Firestore et l'envoi FCM.

**Tech Stack:** Node 22, firebase-functions 7, firebase-admin 14, luxon 3, TypeScript 5.9, Vitest 5, Firebase CLI.

**Spec de référence :** `docs/superpowers/specs/2026-09-21-colette-v1-design.md` §5.1, §7. Dépend du plan app (`2026-09-21-colette-v1-app.md`) à partir de sa tâche 10 pour le champ `hasBottle` et la structure des documents.

---

## Carte des fichiers

| Fichier | Responsabilité |
| --- | --- |
| `firebase.json`, `.firebaserc` | Config CLI : rules, indexes, functions |
| `firestore.rules` | Lecture/écriture réservées aux sessions signées |
| `firestore.indexes.json` | Index composites `events` (bath, startAt) et (hasBottle, startAt) |
| `functions/package.json`, `tsconfig.json`, `.gitignore` | Projet Node |
| `functions/src/index.ts` | Options globales, init admin, exports |
| `functions/src/lib/types.ts` | Types des documents Firestore |
| `functions/src/lib/firestore.ts` | `db()`, `loadDevices()` |
| `functions/src/lib/paris-time.ts` | Heure, début de journée, format « 14h32 » en Europe/Paris |
| `functions/src/lib/summary.ts` | `summarizeEvent()` |
| `functions/src/lib/care-status.ts` | `pendingCares()`, `isBathExpected()` |
| `functions/src/lib/reminder.ts` | `isReminderDue()` |
| `functions/src/lib/push.ts` | `sendToDevices()` + nettoyage des tokens morts |
| `functions/src/on-event-created.ts` | Trigger Firestore |
| `functions/src/bottle-reminder.ts` | Cron 5 min |
| `functions/src/morning-digest.ts` | Cron horaire |
| `functions/src/lib/*.test.ts` | Tests Vitest |

---

### Task 1: Configuration Firebase, règles, index, projet Node

**Files:**
- Create: `firebase.json`, `.firebaserc`, `firestore.rules`, `firestore.indexes.json`
- Create: `functions/package.json`, `functions/tsconfig.json`, `functions/.gitignore`, `functions/src/index.ts`

- [ ] **Step 1: Créer `firebase.json`**

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "functions": [
    {
      "source": "functions",
      "codebase": "default",
      "runtime": "nodejs22",
      "predeploy": ["npm --prefix \"$RESOURCE_DIR\" run build"]
    }
  ]
}
```

- [ ] **Step 2: Créer `.firebaserc`**

```json
{
  "projects": {
    "default": "REPLACE_WITH_FIREBASE_PROJECT_ID"
  }
}
```

Maxence remplace la valeur par l'identifiant de son projet, ou lance `firebase use --add`.

- [ ] **Step 3: Créer `firestore.rules`**

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Le document foyer est atteignable par son code, jamais énumérable
    // (aucun `read`/`list` accordé ici), et créé seulement avec un code au
    // format généré par l'app (8 caractères, alphabet sans O/0 ni I/1).
    match /households/{code} {
      allow get: if request.auth != null;
      allow create: if request.auth != null && code.matches('^[A-HJ-NP-Z2-9]{8}$');
      allow update: if request.auth != null;
      allow delete: if false;
    }
    // Sous-collections : events, weights, devices.
    match /households/{code}/{collection}/{docId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

- [ ] **Step 4: Créer `firestore.indexes.json`**

```json
{
  "indexes": [
    {
      "collectionGroup": "events",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "bath", "order": "ASCENDING" },
        { "fieldPath": "startAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "events",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "hasBottle", "order": "ASCENDING" },
        { "fieldPath": "startAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

- [ ] **Step 5: Créer le projet Node**

`functions/package.json` :

```json
{
  "name": "colette-functions",
  "private": true,
  "main": "lib/index.js",
  "engines": { "node": "22" },
  "scripts": {
    "build": "tsc",
    "test": "vitest run",
    "serve": "npm run build && firebase emulators:start --only functions"
  },
  "dependencies": {
    "firebase-admin": "^14.4.0",
    "firebase-functions": "^7.4.0",
    "luxon": "^3.6.0"
  },
  "devDependencies": {
    "@types/luxon": "^3.6.0",
    "@types/node": "^22.0.0",
    "typescript": "^5.9.0",
    "vitest": "^5.0.0"
  }
}
```

`functions/tsconfig.json` :

```json
{
  "compilerOptions": {
    "target": "es2022",
    "module": "commonjs",
    "moduleResolution": "node",
    "outDir": "lib",
    "rootDir": "src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "sourceMap": true
  },
  "include": ["src"],
  "exclude": ["src/**/*.test.ts"]
}
```

`functions/.gitignore` :

```gitignore
/node_modules/
/lib/
```

(Motifs ancrés à la racine de `functions/` : un `lib/` non ancré ignorerait aussi `functions/src/lib/`.)

`functions/src/index.ts` (exports ajoutés dans les tâches suivantes) :

```ts
import { setGlobalOptions } from 'firebase-functions/v2';
import { initializeApp } from 'firebase-admin/app';

setGlobalOptions({ region: 'europe-west1', maxInstances: 5 });
initializeApp();
```

- [ ] **Step 6: Installer et compiler**

Run: `cd /Users/maxencemontet/Documents/colette/functions && npm install && npm run build`
Expected: `node_modules/` créé, `lib/index.js` produit sans erreur.

- [ ] **Step 7: Commit**

```bash
cd /Users/maxencemontet/Documents/colette
git add firebase.json .firebaserc firestore.rules firestore.indexes.json functions/package.json functions/package-lock.json functions/tsconfig.json functions/.gitignore functions/src/index.ts
git commit -m "chore: config Firebase (règles, index) et projet Cloud Functions"
```

---

### Task 2: Types, accès Firestore, heure de Paris

**Files:**
- Create: `functions/src/lib/types.ts`, `functions/src/lib/firestore.ts`, `functions/src/lib/paris-time.ts`
- Test: `functions/src/lib/paris-time.test.ts`, `functions/src/lib/types.test.ts`

- [ ] **Step 1: Écrire le test (rouge)**

`functions/src/lib/paris-time.test.ts` :

```ts
import { describe, expect, it } from 'vitest';
import {
  formatHourMinute,
  hourInParis,
  nearestHourInParis,
  startOfTodayInParis,
  startOfTomorrowInParis,
  todayKeyInParis,
} from './paris-time';

describe('paris-time', () => {
  it('formate en « 14h32 » heure de Paris', () => {
    expect(formatHourMinute(new Date('2026-09-21T12:32:00Z'))).toBe('14h32');
  });

  it('donne l\'heure de Paris (été : UTC+2)', () => {
    expect(hourInParis(new Date('2026-09-21T06:00:00Z'))).toBe(8);
  });

  it('donne minuit de Paris en UTC', () => {
    expect(startOfTodayInParis(new Date('2026-09-21T12:32:00Z')).toISOString()).toBe(
      '2026-09-20T22:00:00.000Z',
    );
  });

  it('donne minuit de Paris en UTC en heure d\'hiver', () => {
    expect(startOfTodayInParis(new Date('2026-01-15T12:00:00Z')).toISOString()).toBe(
      '2026-01-14T23:00:00.000Z',
    );
  });
});

describe('startOfTomorrowInParis', () => {
  it('donne minuit du lendemain (heure d\'été)', () => {
    expect(startOfTomorrowInParis(new Date('2026-09-21T12:32:00Z')).toISOString()).toBe(
      '2026-09-21T22:00:00.000Z',
    );
  });

  it('donne minuit du lendemain (heure d\'hiver)', () => {
    expect(startOfTomorrowInParis(new Date('2026-01-15T12:00:00Z')).toISOString()).toBe(
      '2026-01-15T23:00:00.000Z',
    );
  });
});

describe('nearestHourInParis', () => {
  it('arrondit à l\'heure la plus proche', () => {
    expect(nearestHourInParis(new Date('2026-09-21T05:59:00Z'))).toBe(8);
    expect(nearestHourInParis(new Date('2026-09-21T06:29:00Z'))).toBe(8);
    expect(nearestHourInParis(new Date('2026-09-21T06:31:00Z'))).toBe(9);
  });
});

describe('todayKeyInParis', () => {
  it('donne la date du jour à Paris au format yyyy-LL-dd', () => {
    expect(todayKeyInParis(new Date('2026-09-21T12:32:00Z'))).toBe('2026-09-21');
  });

  it('bascule au jour suivant dès minuit à Paris', () => {
    expect(todayKeyInParis(new Date('2026-09-21T22:30:00Z'))).toBe('2026-09-22');
  });
});
```

- [ ] **Step 2: Vérifier l'échec**

Run: `cd functions && npm test`
Expected: échec, module `./paris-time` introuvable.

- [ ] **Step 3: Créer `functions/src/lib/types.ts`**

```ts
import type { Timestamp } from 'firebase-admin/firestore';

export type CareSettings = {
  adrigylPerDay: number;
  eyeCarePerDay: number;
  noseCarePerDay: number;
  umbilicalCareEnabled: boolean;
  bathEveryDays: number;
  feedsPerDay: number;
};

export const DEFAULT_CARE_SETTINGS: CareSettings = {
  adrigylPerDay: 1,
  eyeCarePerDay: 1,
  noseCarePerDay: 1,
  umbilicalCareEnabled: true,
  bathEveryDays: 2,
  feedsPerDay: 8,
};

export type BabyDoc = {
  name: string;
  careSettings?: Partial<CareSettings>;
};

export type FeedingPlanDoc = {
  nextBottleAt: Timestamp;
  suggestedMl: number;
  computedAt?: Timestamp;
};

export type DeviceDoc = {
  label?: string;
  fcmToken?: string | null;
  notifyOnOthersEvents?: boolean;
  notifyBottleReminder?: boolean;
  notifyMorningDigest?: boolean;
  morningDigestHour?: number;
  lastDigestSentOn?: string;
};

export type Device = DeviceDoc & { id: string };

export type EventDoc = {
  startAt: Timestamp;
  pee?: boolean;
  poop?: boolean;
  diaperChange?: boolean;
  adrigyl?: boolean;
  bath?: boolean;
  eyeCare?: boolean;
  noseCare?: boolean;
  umbilicalCare?: boolean;
  bottleMl?: number | null;
  createdByDeviceId?: string;
};

/** Événement avec `startAt` converti en `Date`, pour la logique pure. */
export type CareEvent = Omit<EventDoc, 'startAt'> & { startAt: Date };

export function toCareEvent(doc: EventDoc): CareEvent {
  return { ...doc, startAt: doc.startAt.toDate() };
}

/** Borne une valeur comme le client : un document modifié à la main ne doit jamais casser les calculs. */
function clamped(value: unknown, min: number, max: number, fallback: number): number {
  if (typeof value !== 'number' || !Number.isFinite(value)) return fallback;
  return Math.min(max, Math.max(min, Math.trunc(value)));
}

/** Mêmes valeurs par défaut et mêmes bornes que `CareSettingsDto.fromMap` côté client. */
export function withDefaults(settings: Partial<CareSettings> | undefined): CareSettings {
  const raw = settings ?? {};
  return {
    adrigylPerDay: clamped(raw.adrigylPerDay, 0, 10, DEFAULT_CARE_SETTINGS.adrigylPerDay),
    eyeCarePerDay: clamped(raw.eyeCarePerDay, 0, 10, DEFAULT_CARE_SETTINGS.eyeCarePerDay),
    noseCarePerDay: clamped(raw.noseCarePerDay, 0, 10, DEFAULT_CARE_SETTINGS.noseCarePerDay),
    umbilicalCareEnabled: raw.umbilicalCareEnabled !== false,
    bathEveryDays: clamped(raw.bathEveryDays, 1, 30, DEFAULT_CARE_SETTINGS.bathEveryDays),
    feedsPerDay: clamped(raw.feedsPerDay, 1, 24, DEFAULT_CARE_SETTINGS.feedsPerDay),
  };
}
```

- [ ] **Step 4: Créer `functions/src/lib/firestore.ts`**

```ts
import { DocumentReference, getFirestore } from 'firebase-admin/firestore';
import type { Device, DeviceDoc } from './types';

export const db = () => getFirestore();

export async function loadDevices(household: DocumentReference): Promise<Device[]> {
  const snap = await household.collection('devices').get();
  return snap.docs.map((d) => ({ id: d.id, ...(d.data() as DeviceDoc) }));
}
```

- [ ] **Step 5: Créer `functions/src/lib/paris-time.ts`**

```ts
import { DateTime } from 'luxon';

export const ZONE = 'Europe/Paris';

const paris = (date: Date) => DateTime.fromJSDate(date, { zone: ZONE });

/** « 14h32 » */
export function formatHourMinute(date: Date): string {
  return paris(date).toFormat("HH'h'mm");
}

export function hourInParis(date: Date): number {
  return paris(date).hour;
}

export function startOfTodayInParis(date: Date): Date {
  return paris(date).startOf('day').toJSDate();
}

/** Minuit du lendemain à Paris : borne haute exclusive des événements du jour. */
export function startOfTomorrowInParis(date: Date): Date {
  return paris(date).startOf('day').plus({ days: 1 }).toJSDate();
}

/** Heure de Paris la plus proche : 7h59 et 8h29 donnent 8, 8h31 donne 9. */
export function nearestHourInParis(date: Date): number {
  return paris(date).plus({ minutes: 30 }).startOf('hour').hour;
}

/** « 2026-09-21 » : la journée civile parisienne, clé d'idempotence du digest. */
export function todayKeyInParis(date: Date): string {
  return paris(date).toFormat('yyyy-LL-dd');
}

/** Nombre de jours civils (Paris) entre deux instants. */
export function calendarDaysBetween(from: Date, to: Date): number {
  return Math.floor(paris(to).startOf('day').diff(paris(from).startOf('day'), 'days').days);
}
```

- [ ] **Step 6: Tester**

Run: `cd functions && npm test`
Expected: 3 tests passent.

- [ ] **Step 7: Tester `withDefaults` — `functions/src/lib/types.test.ts`**

Bornes identiques au client (`baby_profile_dto.dart`) : 0–10, 1–30, 1–24, troncature puis clamp, repli sur le défaut pour `null`/`NaN`.

```ts
import { describe, expect, it } from 'vitest';
import { DEFAULT_CARE_SETTINGS, withDefaults } from './types';

describe('withDefaults', () => {
  it('sans réglages : les valeurs par défaut du client', () => {
    expect(withDefaults(undefined)).toEqual(DEFAULT_CARE_SETTINGS);
    expect(withDefaults({})).toEqual(DEFAULT_CARE_SETTINGS);
  });

  it('valeurs nulles ou absentes : repli sur les valeurs par défaut', () => {
    const settings = withDefaults({
      adrigylPerDay: null,
      eyeCarePerDay: undefined,
      noseCarePerDay: null,
      bathEveryDays: null,
      feedsPerDay: undefined,
      umbilicalCareEnabled: null,
    } as never);

    expect(settings).toEqual(DEFAULT_CARE_SETTINGS);
  });

  it('valeurs hors bornes : ramenées dans les bornes du client', () => {
    expect(
      withDefaults({
        adrigylPerDay: 42,
        eyeCarePerDay: -3,
        noseCarePerDay: 10,
        bathEveryDays: 0,
        feedsPerDay: 99,
      }),
    ).toEqual({
      adrigylPerDay: 10,
      eyeCarePerDay: 0,
      noseCarePerDay: 10,
      bathEveryDays: 1,
      feedsPerDay: 24,
      umbilicalCareEnabled: true,
    });

    expect(withDefaults({ bathEveryDays: 60, feedsPerDay: 0 })).toMatchObject({
      bathEveryDays: 30,
      feedsPerDay: 1,
    });
  });

  it('valeurs normales : conservées telles quelles', () => {
    expect(
      withDefaults({
        adrigylPerDay: 2,
        eyeCarePerDay: 0,
        noseCarePerDay: 3,
        bathEveryDays: 7,
        feedsPerDay: 6,
        umbilicalCareEnabled: false,
      }),
    ).toEqual({
      adrigylPerDay: 2,
      eyeCarePerDay: 0,
      noseCarePerDay: 3,
      bathEveryDays: 7,
      feedsPerDay: 6,
      umbilicalCareEnabled: false,
    });
  });

  it('valeurs non numériques : repli sur les valeurs par défaut', () => {
    expect(withDefaults({ adrigylPerDay: 'deux', feedsPerDay: Number.NaN } as never)).toMatchObject({
      adrigylPerDay: 1,
      feedsPerDay: 8,
    });
  });

  it('nombril : activé sauf refus explicite', () => {
    expect(withDefaults({ umbilicalCareEnabled: false }).umbilicalCareEnabled).toBe(false);
    expect(withDefaults({ umbilicalCareEnabled: undefined }).umbilicalCareEnabled).toBe(true);
  });
});
```

- [ ] **Step 8: Commit**

```bash
cd /Users/maxencemontet/Documents/colette
git add functions/src/lib
git commit -m "feat(functions): types Firestore, accès db, helpers heure de Paris"
```

---

### Task 3: Résumé d'événement, soins en attente, échéance du rappel (logique pure)

**Files:**
- Create: `functions/src/lib/summary.ts`, `functions/src/lib/care-status.ts`, `functions/src/lib/reminder.ts`
- Test: `functions/src/lib/summary.test.ts`, `functions/src/lib/care-status.test.ts`, `functions/src/lib/reminder.test.ts`

- [ ] **Step 1: Écrire les tests (rouges)**

`functions/src/lib/summary.test.ts` :

```ts
import { describe, expect, it } from 'vitest';
import { summarizeEvent } from './summary';

describe('summarizeEvent', () => {
  const at = new Date('2026-09-21T12:32:00Z');

  it("liste biberon puis soins, avec l'heure de Paris", () => {
    expect(summarizeEvent({ startAt: at, bottleMl: 120, diaperChange: true, adrigyl: true })).toBe(
      'Biberon 120 ml · Couche · Adrigyl à 14h32',
    );
  });

  it('gère un événement à un seul soin', () => {
    expect(summarizeEvent({ startAt: at, bath: true })).toBe('Bain à 14h32');
  });

  it("sans biberon ni soin, décrit un événement simple", () => {
    expect(summarizeEvent({ startAt: at })).toBe('Événement à 14h32');
  });
});
```

`functions/src/lib/care-status.test.ts` :

```ts
import { describe, expect, it } from 'vitest';
import { isBathExpected, pendingCares } from './care-status';
import { DEFAULT_CARE_SETTINGS } from './types';

const now = new Date('2026-09-21T06:00:00Z');

describe('pendingCares', () => {
  it('sans événement : tous les soins par défaut sont en attente', () => {
    expect(pendingCares({ settings: DEFAULT_CARE_SETTINGS, todayEvents: [], lastBathAt: null, now })).toEqual([
      'Adrigyl',
      'Soin des yeux',
      'Soin du nez',
      'Soin du nombril',
      'Bain',
    ]);
  });

  it("un soin fait aujourd'hui disparaît de la liste", () => {
    const pending = pendingCares({
      settings: DEFAULT_CARE_SETTINGS,
      todayEvents: [{ startAt: new Date('2026-09-21T05:00:00Z'), adrigyl: true }],
      lastBathAt: null,
      now,
    });
    expect(pending).not.toContain('Adrigyl');
  });

  it('nombril désactivé et bain récent : ni nombril ni bain', () => {
    const pending = pendingCares({
      settings: { ...DEFAULT_CARE_SETTINGS, umbilicalCareEnabled: false },
      todayEvents: [],
      lastBathAt: new Date('2026-09-20T16:00:00Z'),
      now,
    });
    expect(pending).toEqual(['Adrigyl', 'Soin des yeux', 'Soin du nez']);
  });
  it('adrigylPerDay à 0 : Adrigyl jamais attendu', () => {
    const pending = pendingCares({
      settings: { ...DEFAULT_CARE_SETTINGS, adrigylPerDay: 0 },
      todayEvents: [],
      lastBathAt: null,
      now,
    });

    expect(pending).not.toContain('Adrigyl');
  });

  it('adrigylPerDay à 2 avec une prise faite : encore en attente', () => {
    const pending = pendingCares({
      settings: { ...DEFAULT_CARE_SETTINGS, adrigylPerDay: 2 },
      todayEvents: [{ startAt: new Date('2026-09-21T05:00:00Z'), adrigyl: true }],
      lastBathAt: null,
      now,
    });

    expect(pending).toContain('Adrigyl');
  });
});

describe('isBathExpected', () => {
  it('attendu sans bain, ou après bathEveryDays jours civils', () => {
    expect(isBathExpected(null, 2, now)).toBe(true);
    expect(isBathExpected(new Date('2026-09-20T16:00:00Z'), 2, now)).toBe(false);
    expect(isBathExpected(new Date('2026-09-19T16:00:00Z'), 2, now)).toBe(true);
  });
});
```

`functions/src/lib/reminder.test.ts` :

```ts
import { describe, expect, it } from 'vitest';
import { isReminderDue, REMINDER_LEAD_MS, REMINDER_TOLERANCE_MS } from './reminder';

describe('isReminderDue', () => {
  const next = new Date('2026-09-21T12:30:00Z');
  const computedAt = new Date('2026-09-21T09:30:00Z');

  it('pas encore dans la fenêtre de 10 min', () => {
    expect(
      isReminderDue({ nextBottleAt: next, computedAt, lastNotifiedFor: null, now: new Date('2026-09-21T12:15:00Z') }),
    ).toBe(false);
  });

  it('dû dès 10 min avant', () => {
    expect(
      isReminderDue({
        nextBottleAt: next,
        computedAt,
        lastNotifiedFor: null,
        now: new Date(next.getTime() - REMINDER_LEAD_MS),
      }),
    ).toBe(true);
  });

  it('jamais deux fois pour la même échéance', () => {
    expect(
      isReminderDue({ nextBottleAt: next, computedAt, lastNotifiedFor: next, now: new Date('2026-09-21T12:25:00Z') }),
    ).toBe(false);
  });

  it('plan calculé à son échéance (aucun biberon enregistré) : rien à rappeler', () => {
    expect(
      isReminderDue({ nextBottleAt: next, computedAt: next, lastNotifiedFor: null, now: new Date(next) }),
    ).toBe(false);
  });

  it('plan calculé après son échéance (dernier biberon trop ancien) : rien à rappeler', () => {
    expect(
      isReminderDue({
        nextBottleAt: next,
        computedAt: new Date(next.getTime() + 60 * 1000),
        lastNotifiedFor: null,
        now: new Date(next.getTime() + 60 * 1000),
      }),
    ).toBe(false);
  });

  it('plus rien au-delà de la tolérance de 15 min', () => {
    expect(
      isReminderDue({
        nextBottleAt: next,
        computedAt,
        lastNotifiedFor: null,
        now: new Date(next.getTime() + 20 * 60 * 1000),
      }),
    ).toBe(false);
    expect(REMINDER_TOLERANCE_MS).toBe(15 * 60 * 1000);
  });

  it('encore dû 14 min après l’échéance', () => {
    expect(
      isReminderDue({
        nextBottleAt: next,
        computedAt,
        lastNotifiedFor: null,
        now: new Date(next.getTime() + 14 * 60 * 1000),
      }),
    ).toBe(true);
  });

  it('sans computedAt, la fenêtre seule décide', () => {
    expect(
      isReminderDue({
        nextBottleAt: next,
        computedAt: null,
        lastNotifiedFor: null,
        now: new Date('2026-09-21T12:15:00Z'),
      }),
    ).toBe(false);
    expect(
      isReminderDue({ nextBottleAt: next, computedAt: null, lastNotifiedFor: null, now: new Date(next) }),
    ).toBe(true);
  });
});
```

- [ ] **Step 2: Vérifier l'échec**

Run: `cd functions && npm test`
Expected: échec, modules introuvables.

- [ ] **Step 3: Créer `functions/src/lib/summary.ts`**

```ts
import { formatHourMinute } from './paris-time';
import type { CareEvent } from './types';

export const CARE_LABELS = {
  diaperChange: 'Couche',
  pee: 'Pipi',
  poop: 'Caca',
  adrigyl: 'Adrigyl',
  bath: 'Bain',
  eyeCare: 'Soin des yeux',
  noseCare: 'Soin du nez',
  umbilicalCare: 'Soin du nombril',
} as const;

const ORDER = ['diaperChange', 'pee', 'poop', 'adrigyl', 'bath', 'eyeCare', 'noseCare', 'umbilicalCare'] as const;

/** « Biberon 120 ml · Couche · Adrigyl à 14h32 » */
export function summarizeEvent(event: CareEvent): string {
  const parts: string[] = [];
  if (event.bottleMl != null) parts.push(`Biberon ${event.bottleMl} ml`);
  for (const key of ORDER) {
    if (event[key]) parts.push(CARE_LABELS[key]);
  }
  const label = parts.length === 0 ? 'Événement' : parts.join(' · ');
  return `${label} à ${formatHourMinute(event.startAt)}`;
}
```

- [ ] **Step 4: Créer `functions/src/lib/care-status.ts`**

```ts
import { calendarDaysBetween } from './paris-time';
import { CARE_LABELS } from './summary';
import type { CareEvent, CareSettings } from './types';

type Input = {
  settings: CareSettings;
  todayEvents: CareEvent[];
  lastBathAt: Date | null;
  now: Date;
};

export function isBathExpected(lastBathAt: Date | null, bathEveryDays: number, now: Date): boolean {
  if (!lastBathAt) return true;
  return calendarDaysBetween(lastBathAt, now) >= bathEveryDays;
}

/** Libellés des soins attendus aujourd'hui et pas encore faits, dans l'ordre du dashboard. */
export function pendingCares({ settings, todayEvents, lastBathAt, now }: Input): string[] {
  const count = (key: keyof typeof CARE_LABELS) => todayEvents.filter((e) => e[key]).length;
  const pending: string[] = [];
  if (settings.adrigylPerDay > 0 && count('adrigyl') < settings.adrigylPerDay) pending.push(CARE_LABELS.adrigyl);
  if (settings.eyeCarePerDay > 0 && count('eyeCare') < settings.eyeCarePerDay) pending.push(CARE_LABELS.eyeCare);
  if (settings.noseCarePerDay > 0 && count('noseCare') < settings.noseCarePerDay) pending.push(CARE_LABELS.noseCare);
  if (settings.umbilicalCareEnabled && count('umbilicalCare') < 1) pending.push(CARE_LABELS.umbilicalCare);
  if (isBathExpected(lastBathAt, settings.bathEveryDays, now) && count('bath') < 1) pending.push(CARE_LABELS.bath);
  return pending;
}
```

- [ ] **Step 5: Créer `functions/src/lib/reminder.ts`**

```ts
export const REMINDER_LEAD_MS = 10 * 60 * 1000;
export const REMINDER_TOLERANCE_MS = 15 * 60 * 1000;

type Input = { nextBottleAt: Date; computedAt: Date | null; lastNotifiedFor: Date | null; now: Date };

/**
 * Dû entre 10 min avant l'échéance et 15 min après, une seule fois par échéance.
 * Un plan calculé à ou après son échéance (aucun biberon encore enregistré, ou
 * dernier biberon trop ancien) ne déclenche rien : le parent sait déjà.
 */
export function isReminderDue({ nextBottleAt, computedAt, lastNotifiedFor, now }: Input): boolean {
  if (lastNotifiedFor && lastNotifiedFor.getTime() === nextBottleAt.getTime()) return false;
  if (computedAt && computedAt.getTime() >= nextBottleAt.getTime()) return false;
  if (now.getTime() > nextBottleAt.getTime() + REMINDER_TOLERANCE_MS) return false;
  return nextBottleAt.getTime() - REMINDER_LEAD_MS <= now.getTime();
}
```

- [ ] **Step 6: Tester**

Run: `cd functions && npm test`
Expected: tous les tests passent.

- [ ] **Step 7: Commit**

```bash
cd /Users/maxencemontet/Documents/colette
git add functions/src/lib
git commit -m "feat(functions): résumé d'événement, soins en attente, échéance du rappel"
```

---

### Task 4: Envoi FCM et nettoyage des tokens

**Files:**
- Create: `functions/src/lib/push.ts`

- [ ] **Step 1: Créer `functions/src/lib/push.ts`**

```ts
import { FieldValue } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { logger } from 'firebase-functions';
import { db } from './firestore';
import type { Device } from './types';

export type PushPayload = { title: string; body: string; data?: Record<string, string> };

const STALE_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

/** Envoie la notification aux appareils munis d'un token ; efface les tokens morts. */
export async function sendToDevices(code: string, devices: Device[], payload: PushPayload): Promise<number> {
  const targets = devices.filter((d): d is Device & { fcmToken: string } => !!d.fcmToken);
  if (targets.length === 0) return 0;

  const response = await getMessaging().sendEachForMulticast({
    tokens: targets.map((d) => d.fcmToken),
    notification: { title: payload.title, body: payload.body },
    data: payload.data ?? {},
    apns: { payload: { aps: { sound: 'default' } } },
  });

  const stale = response.responses
    .map((r, i) => (!r.success && r.error && STALE_TOKEN_CODES.has(r.error.code) ? targets[i] : null))
    .filter((d): d is Device & { fcmToken: string } => d !== null);

  await Promise.all(
    stale.map((d) =>
      db()
        .collection('households')
        .doc(code)
        .collection('devices')
        .doc(d.id)
        .update({ fcmToken: FieldValue.delete() })
        .catch((err) => logger.warn('Token mort non effacé', { code, deviceId: d.id, err })),
    ),
  );

  logger.info('push sent', { code, success: response.successCount, failure: response.failureCount, stale: stale.length });
  return response.successCount;
}
```

- [ ] **Step 2: Compiler**

Run: `cd functions && npm run build`
Expected: aucune erreur TypeScript.

- [ ] **Step 3: Tester `sendToDevices` — `functions/src/lib/push.test.ts`**

`firebase-admin/messaging`, `firebase-functions` et `./firestore` sont mockés avec `vi.hoisted` + `vi.mock` : aucun appel sans token, multicast et nombre de succès, effacement des seuls tokens `registration-token-not-registered` / `invalid-registration-token`.

```ts
import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { Device } from './types';

const { sendEachForMulticast, updateCalls, failingDeviceIds, loggerInfo, loggerWarn } = vi.hoisted(() => ({
  sendEachForMulticast: vi.fn(),
  updateCalls: [] as Array<{ code: string; deviceId: string; data: unknown }>,
  failingDeviceIds: new Set<string>(),
  loggerInfo: vi.fn(),
  loggerWarn: vi.fn(),
}));

vi.mock('firebase-admin/messaging', () => ({
  getMessaging: () => ({ sendEachForMulticast }),
}));

vi.mock('firebase-functions', () => ({
  logger: { info: loggerInfo, warn: loggerWarn },
}));

vi.mock('./firestore', () => ({
  db: () => ({
    collection: (name: string) => {
      if (name !== 'households') throw new Error(`collection inattendue: ${name}`);
      return {
        doc: (code: string) => ({
          collection: (sub: string) => {
            if (sub !== 'devices') throw new Error(`sous-collection inattendue: ${sub}`);
            return {
              doc: (deviceId: string) => ({
                update: (data: unknown) => {
                  updateCalls.push({ code, deviceId, data });
                  return failingDeviceIds.has(deviceId)
                    ? Promise.reject(new Error('NOT_FOUND: document absent'))
                    : Promise.resolve();
                },
              }),
            };
          },
        }),
      };
    },
  }),
}));

const { sendToDevices } = await import('./push');

describe('sendToDevices', () => {
  beforeEach(() => {
    sendEachForMulticast.mockReset();
    loggerInfo.mockReset();
    loggerWarn.mockReset();
    updateCalls.length = 0;
    failingDeviceIds.clear();
  });

  it("ne fait aucun appel FCM si aucun appareil n'a de token", async () => {
    const devices: Device[] = [{ id: 'd1' }, { id: 'd2', fcmToken: null }];

    const count = await sendToDevices('ABC123', devices, { title: 'Titre', body: 'Corps' });

    expect(count).toBe(0);
    expect(sendEachForMulticast).not.toHaveBeenCalled();
  });

  it('envoie un multicast aux appareils munis d’un token et renvoie le nombre de succès', async () => {
    sendEachForMulticast.mockResolvedValue({
      responses: [{ success: true }, { success: true }],
      successCount: 2,
      failureCount: 0,
    });
    const devices: Device[] = [
      { id: 'd1', fcmToken: 'token-1' },
      { id: 'd2', fcmToken: 'token-2' },
    ];

    const count = await sendToDevices('ABC123', devices, {
      title: 'Titre',
      body: 'Corps',
      data: { type: 'reminder' },
    });

    expect(count).toBe(2);
    expect(sendEachForMulticast).toHaveBeenCalledWith({
      tokens: ['token-1', 'token-2'],
      notification: { title: 'Titre', body: 'Corps' },
      data: { type: 'reminder' },
      apns: { payload: { aps: { sound: 'default' } } },
    });
    expect(updateCalls).toEqual([]);
  });

  it('efface uniquement les tokens signalés comme non enregistrés ou invalides', async () => {
    sendEachForMulticast.mockResolvedValue({
      responses: [
        { success: true },
        { success: false, error: { code: 'messaging/registration-token-not-registered' } },
        { success: false, error: { code: 'messaging/invalid-registration-token' } },
        { success: false, error: { code: 'messaging/internal-error' } },
      ],
      successCount: 1,
      failureCount: 3,
    });
    const devices: Device[] = [
      { id: 'ok', fcmToken: 'token-ok' },
      { id: 'stale-1', fcmToken: 'token-stale-1' },
      { id: 'stale-2', fcmToken: 'token-stale-2' },
      { id: 'other-error', fcmToken: 'token-other' },
    ];

    const count = await sendToDevices('ABC123', devices, { title: 'Titre', body: 'Corps' });

    expect(count).toBe(1);
    expect(updateCalls).toHaveLength(2);
    expect(updateCalls.map((c) => c.deviceId).sort()).toEqual(['stale-1', 'stale-2']);
    for (const call of updateCalls) {
      expect(call.code).toBe('ABC123');
    }
  });

  it("n'échoue pas quand l'appareil a été supprimé entre-temps", async () => {
    sendEachForMulticast.mockResolvedValue({
      responses: [
        { success: true },
        { success: false, error: { code: 'messaging/registration-token-not-registered' } },
        { success: false, error: { code: 'messaging/invalid-registration-token' } },
      ],
      successCount: 1,
      failureCount: 2,
    });
    failingDeviceIds.add('parti');
    const devices: Device[] = [
      { id: 'ok', fcmToken: 'token-ok' },
      { id: 'parti', fcmToken: 'token-parti' },
      { id: 'stale', fcmToken: 'token-stale' },
    ];

    const count = await sendToDevices('ABC123', devices, { title: 'Titre', body: 'Corps' });

    expect(count).toBe(1);
    expect(updateCalls.map((c) => c.deviceId).sort()).toEqual(['parti', 'stale']);
    expect(loggerWarn).toHaveBeenCalledTimes(1);
  });
});
```

Run: `cd functions && npm test`
Expected: 15 tests verts.

- [ ] **Step 4: Commit**

```bash
cd /Users/maxencemontet/Documents/colette
git add functions/src/lib/push.ts functions/src/lib/push.test.ts
git commit -m "feat(functions): envoi FCM multicast et nettoyage des tokens morts"
```

---

### Task 5: Trigger « événement créé »

**Files:**
- Create: `functions/src/on-event-created.ts`
- Modify: `functions/src/index.ts`

- [ ] **Step 1: Créer `functions/src/on-event-created.ts`**

```ts
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { loadDevices } from './lib/firestore';
import { sendToDevices } from './lib/push';
import { summarizeEvent } from './lib/summary';
import { toCareEvent, type Device, type EventDoc } from './lib/types';

/**
 * Appareils à notifier : ni l'auteur, ni ceux ayant désactivé les notifications des autres événements.
 * Sans auteur identifié, impossible de savoir qui prévenir : personne n'est notifié.
 */
export function selectRecipients(devices: Device[], createdByDeviceId: string | undefined): Device[] {
  if (!createdByDeviceId) return [];
  return devices.filter((d) => d.id !== createdByDeviceId && d.notifyOnOthersEvents !== false);
}

export const onEventCreated = onDocumentCreated('households/{code}/events/{eventId}', async (event) => {
  const snap = event.data;
  if (!snap) return;
  const data = snap.data() as EventDoc;
  const code = event.params.code;

  const devices = await loadDevices(snap.ref.parent.parent!);
  const author = devices.find((d) => d.id === data.createdByDeviceId);
  const targets = selectRecipients(devices, data.createdByDeviceId);
  if (targets.length === 0) return;

  await sendToDevices(code, targets, {
    title: `${author?.label ?? 'L\'autre iPhone'} a ajouté un événement`,
    body: summarizeEvent(toCareEvent(data)),
    data: { route: '/journal' },
  });
});
```

- [ ] **Step 2: Exporter dans `functions/src/index.ts`**

Ajouter à la fin du fichier :

```ts
export { onEventCreated } from './on-event-created';
```

- [ ] **Step 2 bis: Tester — `functions/src/on-event-created.test.ts`**

Les helpers purs (`selectRecipients`) sont testés ; `firebase-functions/v2/firestore` est mocké, le câblage du trigger ne l'est pas.

```ts
import { Timestamp } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { Device, DeviceDoc, EventDoc } from './lib/types';

const { sendToDevices } = vi.hoisted(() => ({ sendToDevices: vi.fn() }));

vi.mock('firebase-functions/v2/firestore', () => ({
  onDocumentCreated: (_path: string, handler: unknown) => handler,
}));

vi.mock('./lib/push', () => ({ sendToDevices }));

const { selectRecipients, onEventCreated } = await import('./on-event-created');

/** Instantané Firestore minimal : données de l'événement et chemin vers le foyer. */
function fakeSnapshot(code: string, data: EventDoc, devices: Array<DeviceDoc & { id: string }>) {
  const householdRef = {
    collection: (name: string) => {
      if (name !== 'devices') throw new Error(`sous-collection inattendue: ${name}`);
      return { get: async () => ({ docs: devices.map(({ id, ...rest }) => ({ id, data: () => rest })) }) };
    },
  };
  return {
    params: { code },
    data: { data: () => data, ref: { parent: { parent: householdRef } } },
  };
}

const handler = onEventCreated as unknown as (event: unknown) => Promise<void>;

describe('selectRecipients', () => {
  it("exclut l'appareil auteur de l'événement", () => {
    const devices: Device[] = [
      { id: 'author', notifyOnOthersEvents: true },
      { id: 'other', notifyOnOthersEvents: true },
    ];

    const recipients = selectRecipients(devices, 'author');

    expect(recipients.map((d) => d.id)).toEqual(['other']);
  });

  it('exclut les appareils ayant désactivé les notifications des autres événements', () => {
    const devices: Device[] = [
      { id: 'other-1', notifyOnOthersEvents: false },
      { id: 'other-2', notifyOnOthersEvents: true },
      { id: 'other-3' },
    ];

    const recipients = selectRecipients(devices, 'author');

    expect(recipients.map((d) => d.id).sort()).toEqual(['other-2', 'other-3']);
  });

  it("renvoie un tableau vide s'il n'y a aucun destinataire", () => {
    const devices: Device[] = [{ id: 'author', notifyOnOthersEvents: true }];

    const recipients = selectRecipients(devices, 'author');

    expect(recipients).toEqual([]);
  });

  it('un événement sans auteur identifié ne notifie personne', () => {
    const devices: Device[] = [
      { id: 'd1', notifyOnOthersEvents: false },
      { id: 'd2', notifyOnOthersEvents: true },
    ];

    expect(selectRecipients(devices, undefined)).toEqual([]);
  });
});

describe('onEventCreated', () => {
  const startAt = Timestamp.fromDate(new Date('2026-09-21T12:32:00Z'));

  beforeEach(() => {
    sendToDevices.mockReset();
    sendToDevices.mockResolvedValue(1);
  });

  it("notifie les autres appareils, avec la route du journal", async () => {
    await handler(
      fakeSnapshot('ABC123', { startAt, bottleMl: 120, createdByDeviceId: 'author' }, [
        { id: 'author', label: 'iPhone de Maxence' },
        { id: 'other', label: 'iPhone de Julie' },
        { id: 'muet', notifyOnOthersEvents: false },
      ]),
    );

    expect(sendToDevices).toHaveBeenCalledTimes(1);
    const [code, devices, payload] = sendToDevices.mock.calls[0];
    expect(code).toBe('ABC123');
    expect(devices.map((d: Device) => d.id)).toEqual(['other']);
    expect(payload).toEqual({
      title: 'iPhone de Maxence a ajouté un événement',
      body: 'Biberon 120 ml à 14h32',
      data: { route: '/journal' },
    });
  });

  it("n'envoie rien quand l'événement n'a pas d'auteur identifié", async () => {
    await handler(
      fakeSnapshot('ABC123', { startAt, bath: true }, [{ id: 'd1' }, { id: 'd2' }]),
    );

    expect(sendToDevices).not.toHaveBeenCalled();
  });
});
```

- [ ] **Step 3: Compiler**

Run: `cd functions && npm run build`
Expected: aucune erreur.

- [ ] **Step 4: Commit**

```bash
cd /Users/maxencemontet/Documents/colette
git add functions/src
git commit -m "feat(functions): push à l'autre iPhone à la création d'un événement"
```

---

### Task 6: Rappel biberon (cron 5 min)

**Files:**
- Create: `functions/src/bottle-reminder.ts`
- Modify: `functions/src/index.ts`

- [ ] **Step 1: Créer `functions/src/bottle-reminder.ts`**

```ts
import type { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { db, loadDevices } from './lib/firestore';
import { formatHourMinute, ZONE } from './lib/paris-time';
import { sendToDevices } from './lib/push';
import { isReminderDue } from './lib/reminder';
import type { Device, FeedingPlanDoc } from './lib/types';

/** Appareils à notifier : ceux n'ayant pas désactivé le rappel biberon. */
export function selectBottleRecipients(devices: Device[]): Device[] {
  return devices.filter((d) => d.notifyBottleReminder !== false);
}

export const bottleReminder = onSchedule({ schedule: 'every 5 minutes', timeZone: ZONE, maxInstances: 1 }, async () => {
  const now = new Date();
  const households = await db().collection('households').get();

  for (const doc of households.docs) {
    try {
      const plan = doc.get('feedingPlan') as FeedingPlanDoc | undefined;
      if (!plan?.nextBottleAt) continue;
      const nextBottleAt = plan.nextBottleAt.toDate();
      const lastNotifiedFor = (doc.get('lastBottleNotifiedFor') as Timestamp | undefined)?.toDate() ?? null;
      const due = isReminderDue({
        nextBottleAt,
        computedAt: plan.computedAt?.toDate() ?? null,
        lastNotifiedFor,
        now,
      });
      if (!due) continue;

      const recipients = selectBottleRecipients(await loadDevices(doc.ref));
      const sent = await sendToDevices(doc.id, recipients, {
        title: 'Biberon dans 10 min',
        body: `Environ ${plan.suggestedMl} ml, prévu vers ${formatHourMinute(nextBottleAt)}`,
        data: { route: '/today?bottle=1' },
      });

      // L'échéance n'est consommée que si le rappel est parti, ou si personne ne l'attend :
      // sinon le tick suivant réessaie, dans la limite de la tolérance de 15 min.
      if (sent > 0 || recipients.length === 0) {
        await doc.ref.update({ lastBottleNotifiedFor: plan.nextBottleAt });
      }
    } catch (err) {
      logger.error('Rappel biberon en échec pour un foyer', { household: doc.id, err });
    }
  }
});
```

- [ ] **Step 2: Exporter dans `functions/src/index.ts`**

```ts
export { bottleReminder } from './bottle-reminder';
```

- [ ] **Step 2 bis: Tester — `functions/src/bottle-reminder.test.ts`**

Les helpers purs (`selectBottleRecipients`) sont testés ; `firebase-functions/v2/scheduler` est mocké.

```ts
import { Timestamp } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { Device, DeviceDoc, FeedingPlanDoc } from './lib/types';

const { sendToDevices, loggerError, households, updates } = vi.hoisted(() => ({
  sendToDevices: vi.fn(),
  loggerError: vi.fn(),
  households: [] as FakeHousehold[],
  updates: [] as Array<{ household: string; data: Record<string, unknown> }>,
}));

type FakeHousehold = {
  id: string;
  fields: Record<string, unknown>;
  devices?: Array<DeviceDoc & { id: string }>;
  fails?: boolean;
};

vi.mock('firebase-functions/v2/scheduler', () => ({
  onSchedule: (_options: unknown, handler: unknown) => handler,
}));

vi.mock('firebase-functions', () => ({
  logger: { info: vi.fn(), warn: vi.fn(), error: loggerError },
}));

vi.mock('./lib/push', () => ({ sendToDevices }));

vi.mock('./lib/firestore', async (importOriginal) => ({
  ...(await importOriginal<typeof import('./lib/firestore')>()),
  db: () => ({
    collection: (name: string) => {
      if (name !== 'households') throw new Error(`collection inattendue: ${name}`);
      return {
        get: async () => ({
          docs: households.map((h) => ({
            id: h.id,
            get: (field: string) => h.fields[field],
            ref: {
              update: async (data: Record<string, unknown>) => {
                updates.push({ household: h.id, data });
              },
              collection: (sub: string) => {
                if (sub !== 'devices') throw new Error(`sous-collection inattendue: ${sub}`);
                return {
                  get: async () => {
                    if (h.fails) throw new Error('Firestore indisponible');
                    return {
                      docs: (h.devices ?? []).map(({ id, ...rest }) => ({ id, data: () => rest })),
                    };
                  },
                };
              },
            },
          })),
        }),
      };
    },
  }),
}));

const { selectBottleRecipients, bottleReminder } = await import('./bottle-reminder');

const handler = bottleReminder as unknown as () => Promise<void>;

/** Plan dû : échéance dans 5 min, calculé bien avant (un biberon a donc été enregistré). */
function duePlan(): FeedingPlanDoc {
  const next = new Date(Date.now() + 5 * 60 * 1000);
  return {
    nextBottleAt: Timestamp.fromDate(next),
    suggestedMl: 120,
    computedAt: Timestamp.fromDate(new Date(next.getTime() - 3 * 60 * 60 * 1000)),
  };
}

describe('selectBottleRecipients', () => {
  it('inclut les appareils sans préférence définie', () => {
    const devices: Device[] = [{ id: 'd1' }];

    expect(selectBottleRecipients(devices).map((d) => d.id)).toEqual(['d1']);
  });

  it('inclut les appareils ayant explicitement activé le rappel', () => {
    const devices: Device[] = [{ id: 'd1', notifyBottleReminder: true }];

    expect(selectBottleRecipients(devices).map((d) => d.id)).toEqual(['d1']);
  });

  it('exclut les appareils ayant désactivé le rappel biberon', () => {
    const devices: Device[] = [
      { id: 'd1', notifyBottleReminder: false },
      { id: 'd2', notifyBottleReminder: true },
      { id: 'd3' },
    ];

    expect(selectBottleRecipients(devices).map((d) => d.id).sort()).toEqual(['d2', 'd3']);
  });

  it('renvoie un tableau vide si tous les appareils ont désactivé le rappel', () => {
    const devices: Device[] = [{ id: 'd1', notifyBottleReminder: false }];

    expect(selectBottleRecipients(devices)).toEqual([]);
  });
});

describe('bottleReminder', () => {
  beforeEach(() => {
    sendToDevices.mockReset();
    sendToDevices.mockResolvedValue(1);
    loggerError.mockReset();
    households.length = 0;
    updates.length = 0;
  });

  it("notifie une fois et consomme l'échéance", async () => {
    const plan = duePlan();
    households.push({ id: 'ABC123', fields: { feedingPlan: plan }, devices: [{ id: 'd1' }] });

    await handler();

    expect(sendToDevices).toHaveBeenCalledTimes(1);
    const [code, devices, payload] = sendToDevices.mock.calls[0];
    expect(code).toBe('ABC123');
    expect(devices.map((d: Device) => d.id)).toEqual(['d1']);
    expect(payload.data).toEqual({ route: '/today?bottle=1' });
    expect(payload.body).toContain('120 ml');
    expect(updates).toEqual([{ household: 'ABC123', data: { lastBottleNotifiedFor: plan.nextBottleAt } }]);
  });

  it("ne renotifie pas une échéance déjà notifiée", async () => {
    const plan = duePlan();
    households.push({
      id: 'ABC123',
      fields: { feedingPlan: plan, lastBottleNotifiedFor: plan.nextBottleAt },
      devices: [{ id: 'd1' }],
    });

    await handler();

    expect(sendToDevices).not.toHaveBeenCalled();
    expect(updates).toEqual([]);
  });

  it("ne consomme pas l'échéance quand rien n'a pu être envoyé", async () => {
    sendToDevices.mockResolvedValue(0);
    households.push({ id: 'ABC123', fields: { feedingPlan: duePlan() }, devices: [{ id: 'd1' }] });

    await handler();

    expect(sendToDevices).toHaveBeenCalledTimes(1);
    expect(updates).toEqual([]);
  });

  it("consomme l'échéance quand personne n'attend le rappel", async () => {
    sendToDevices.mockResolvedValue(0);
    const plan = duePlan();
    households.push({
      id: 'ABC123',
      fields: { feedingPlan: plan },
      devices: [{ id: 'd1', notifyBottleReminder: false }],
    });

    await handler();

    expect(updates).toEqual([{ household: 'ABC123', data: { lastBottleNotifiedFor: plan.nextBottleAt } }]);
  });

  it('ignore un plan incomplet sans bloquer les foyers suivants', async () => {
    households.push(
      { id: 'SANS', fields: { feedingPlan: { suggestedMl: 120 } }, devices: [{ id: 'd0' }] },
      { id: 'ABC123', fields: { feedingPlan: duePlan() }, devices: [{ id: 'd1' }] },
    );

    await handler();

    expect(sendToDevices).toHaveBeenCalledTimes(1);
    expect(sendToDevices.mock.calls[0][0]).toBe('ABC123');
  });

  it("journalise l'échec d'un foyer et poursuit la boucle", async () => {
    households.push(
      { id: 'KO', fields: { feedingPlan: duePlan() }, fails: true },
      { id: 'ABC123', fields: { feedingPlan: duePlan() }, devices: [{ id: 'd1' }] },
    );

    await handler();

    expect(loggerError).toHaveBeenCalledTimes(1);
    expect(loggerError.mock.calls[0][1]).toMatchObject({ household: 'KO' });
    expect(sendToDevices).toHaveBeenCalledTimes(1);
    expect(sendToDevices.mock.calls[0][0]).toBe('ABC123');
  });
});
```

- [ ] **Step 3: Compiler**

Run: `cd functions && npm run build`
Expected: aucune erreur.

- [ ] **Step 4: Commit**

```bash
cd /Users/maxencemontet/Documents/colette
git add functions/src
git commit -m "feat(functions): rappel biberon 10 min avant l'échéance"
```

---

### Task 7: Digest du matin (cron horaire)

**Files:**
- Create: `functions/src/morning-digest.ts`
- Modify: `functions/src/index.ts`

- [ ] **Step 1: Créer `functions/src/morning-digest.ts`**

```ts
import { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { pendingCares } from './lib/care-status';
import { db, loadDevices } from './lib/firestore';
import {
  nearestHourInParis,
  startOfTodayInParis,
  startOfTomorrowInParis,
  todayKeyInParis,
  ZONE,
} from './lib/paris-time';
import { sendToDevices } from './lib/push';
import { toCareEvent, withDefaults, type BabyDoc, type Device, type EventDoc } from './lib/types';

/**
 * Appareils à notifier : digest activé, heure choisie égale à l'heure courante (8h par défaut),
 * et digest pas déjà reçu aujourd'hui.
 */
export function selectMorningDigestRecipients(devices: Device[], hour: number, todayKey: string): Device[] {
  return devices.filter(
    (d) => d.notifyMorningDigest !== false && (d.morningDigestHour ?? 8) === hour && d.lastDigestSentOn !== todayKey,
  );
}

/** « Adrigyl, Soin des yeux, Bain » */
export function buildDigestBody(pending: string[]): string {
  return pending.join(', ');
}

export const morningDigest = onSchedule({ schedule: '0 * * * *', timeZone: ZONE, maxInstances: 1 }, async () => {
  const now = new Date();
  const hour = nearestHourInParis(now);
  const todayKey = todayKeyInParis(now);
  const households = await db().collection('households').get();

  for (const doc of households.docs) {
    try {
      const devices = selectMorningDigestRecipients(await loadDevices(doc.ref), hour, todayKey);
      if (devices.length === 0) continue;
      const baby = doc.get('baby') as BabyDoc | undefined;
      if (!baby) continue;

      const events = doc.ref.collection('events');
      const todaySnap = await events
        .where('startAt', '>=', Timestamp.fromDate(startOfTodayInParis(now)))
        .where('startAt', '<', Timestamp.fromDate(startOfTomorrowInParis(now)))
        .get();
      const lastBathSnap = await events.where('bath', '==', true).orderBy('startAt', 'desc').limit(1).get();

      const pending = pendingCares({
        settings: withDefaults(baby.careSettings),
        todayEvents: todaySnap.docs.map((d) => toCareEvent(d.data() as EventDoc)),
        lastBathAt: lastBathSnap.empty ? null : (lastBathSnap.docs[0].data() as EventDoc).startAt.toDate(),
        now,
      });
      if (pending.length === 0) continue;

      const sent = await sendToDevices(doc.id, devices, {
        title: baby.name ? `Aujourd'hui pour ${baby.name}` : "Aujourd'hui pour bébé",
        body: buildDigestBody(pending),
        data: { route: '/today' },
      });
      if (sent === 0) continue;

      // Marque la journée pour ne pas renvoyer le même digest au tick suivant.
      await Promise.all(
        devices.map((d) =>
          doc.ref
            .collection('devices')
            .doc(d.id)
            .update({ lastDigestSentOn: todayKey })
            .catch((err: unknown) =>
              logger.warn('Digest non marqué pour un appareil', { household: doc.id, deviceId: d.id, err }),
            ),
        ),
      );
    } catch (err) {
      logger.error('Digest matinal en échec pour un foyer', { household: doc.id, err });
    }
  }
});
```

- [ ] **Step 2: Exporter dans `functions/src/index.ts`**

```ts
export { morningDigest } from './morning-digest';
```

Le fichier complet vaut alors :

```ts
import { setGlobalOptions } from 'firebase-functions/v2';
import { initializeApp } from 'firebase-admin/app';

setGlobalOptions({ region: 'europe-west1', maxInstances: 5 });
initializeApp();

export { onEventCreated } from './on-event-created';
export { bottleReminder } from './bottle-reminder';
export { morningDigest } from './morning-digest';
```

- [ ] **Step 2 bis: Tester — `functions/src/morning-digest.test.ts`**

Les helpers purs (`selectMorningDigestRecipients`, `buildDigestBody`) sont testés ; `firebase-functions/v2/scheduler` est mocké.

```ts
import { Timestamp } from 'firebase-admin/firestore';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type { BabyDoc, Device, DeviceDoc, EventDoc } from './lib/types';

const { sendToDevices, loggerError, loggerWarn, households, deviceUpdates } = vi.hoisted(() => ({
  sendToDevices: vi.fn(),
  loggerError: vi.fn(),
  loggerWarn: vi.fn(),
  households: [] as FakeHousehold[],
  deviceUpdates: [] as Array<{ household: string; deviceId: string; data: Record<string, unknown> }>,
}));

type FakeHousehold = {
  id: string;
  baby?: BabyDoc;
  devices?: Array<DeviceDoc & { id: string }>;
  events?: EventDoc[];
  fails?: boolean;
};

vi.mock('firebase-functions/v2/scheduler', () => ({
  onSchedule: (_options: unknown, handler: unknown) => handler,
}));

vi.mock('firebase-functions', () => ({
  logger: { info: vi.fn(), warn: loggerWarn, error: loggerError },
}));

vi.mock('./lib/push', () => ({ sendToDevices }));

type Filter = [field: string, op: string, value: unknown];

/** Requête Firestore en mémoire : filtres sur `startAt` et `bath`, tri et limite. */
function fakeQuery(events: EventDoc[], filters: Filter[] = [], desc = false, max?: number) {
  const matches = (event: EventDoc) =>
    filters.every(([field, op, value]) => {
      if (field === 'bath') return Boolean(event.bath) === value;
      if (field !== 'startAt') throw new Error(`filtre inattendu: ${field}`);
      const at = event.startAt.toMillis();
      const bound = (value as Timestamp).toMillis();
      if (op === '>=') return at >= bound;
      if (op === '<') return at < bound;
      throw new Error(`opérateur inattendu: ${op}`);
    });

  return {
    where: (field: string, op: string, value: unknown) => fakeQuery(events, [...filters, [field, op, value]], desc, max),
    orderBy: (_field: string, direction?: string) => fakeQuery(events, filters, direction === 'desc', max),
    limit: (n: number) => fakeQuery(events, filters, desc, n),
    get: async () => {
      const found = events
        .filter(matches)
        .sort((a, b) => (desc ? b.startAt.toMillis() - a.startAt.toMillis() : a.startAt.toMillis() - b.startAt.toMillis()))
        .slice(0, max ?? Number.MAX_SAFE_INTEGER);
      return { docs: found.map((e) => ({ data: () => e })), empty: found.length === 0 };
    },
  };
}

vi.mock('./lib/firestore', async (importOriginal) => ({
  ...(await importOriginal<typeof import('./lib/firestore')>()),
  db: () => ({
    collection: (name: string) => {
      if (name !== 'households') throw new Error(`collection inattendue: ${name}`);
      return {
        get: async () => ({
          docs: households.map((h) => ({
            id: h.id,
            get: (field: string) => (field === 'baby' ? h.baby : undefined),
            ref: {
              collection: (sub: string) => {
                if (sub === 'events') return fakeQuery(h.events ?? []);
                if (sub !== 'devices') throw new Error(`sous-collection inattendue: ${sub}`);
                return {
                  get: async () => {
                    if (h.fails) throw new Error('Firestore indisponible');
                    return { docs: (h.devices ?? []).map(({ id, ...rest }) => ({ id, data: () => rest })) };
                  },
                  doc: (deviceId: string) => ({
                    update: async (data: Record<string, unknown>) => {
                      if (deviceId === 'disparu') throw new Error('NOT_FOUND: appareil supprimé');
                      deviceUpdates.push({ household: h.id, deviceId, data });
                    },
                  }),
                };
              },
            },
          })),
        }),
      };
    },
  }),
}));

const { buildDigestBody, selectMorningDigestRecipients, morningDigest } = await import('./morning-digest');

const handler = morningDigest as unknown as () => Promise<void>;

const NOW = new Date('2026-09-21T06:00:00Z'); // 8h, heure de Paris
const TODAY_KEY = '2026-09-21';
const at = (iso: string) => Timestamp.fromDate(new Date(iso));

describe('selectMorningDigestRecipients', () => {
  it("inclut un appareil sans préférence dont l'heure par défaut (8h) correspond", () => {
    const devices: Device[] = [{ id: 'd1' }];

    expect(selectMorningDigestRecipients(devices, 8, TODAY_KEY).map((d) => d.id)).toEqual(['d1']);
  });

  it("exclut un appareil sans préférence si l'heure courante n'est pas 8h", () => {
    const devices: Device[] = [{ id: 'd1' }];

    expect(selectMorningDigestRecipients(devices, 9, TODAY_KEY)).toEqual([]);
  });

  it('inclut un appareil ayant explicitement choisi cette heure', () => {
    const devices: Device[] = [{ id: 'd1', morningDigestHour: 9 }];

    expect(selectMorningDigestRecipients(devices, 9, TODAY_KEY).map((d) => d.id)).toEqual(['d1']);
  });

  it('exclut les appareils ayant désactivé le digest matinal, même à leur heure', () => {
    const devices: Device[] = [
      { id: 'd1', notifyMorningDigest: false, morningDigestHour: 8 },
      { id: 'd2', notifyMorningDigest: true, morningDigestHour: 8 },
      { id: 'd3', morningDigestHour: 8 },
    ];

    expect(
      selectMorningDigestRecipients(devices, 8, TODAY_KEY)
        .map((d) => d.id)
        .sort(),
    ).toEqual(['d2', 'd3']);
  });

  it("renvoie un tableau vide si aucun appareil n'est dû à cette heure", () => {
    const devices: Device[] = [{ id: 'd1', morningDigestHour: 20 }];

    expect(selectMorningDigestRecipients(devices, 8, TODAY_KEY)).toEqual([]);
  });

  it('exclut un appareil déjà servi aujourd’hui', () => {
    const devices: Device[] = [
      { id: 'servi', lastDigestSentOn: TODAY_KEY },
      { id: 'hier', lastDigestSentOn: '2026-09-20' },
    ];

    expect(selectMorningDigestRecipients(devices, 8, TODAY_KEY).map((d) => d.id)).toEqual(['hier']);
  });
});

describe('buildDigestBody', () => {
  it('joint les soins en attente avec une virgule', () => {
    expect(buildDigestBody(['Adrigyl', 'Soin des yeux', 'Bain'])).toBe('Adrigyl, Soin des yeux, Bain');
  });

  it('renvoie une chaîne vide sans soin en attente', () => {
    expect(buildDigestBody([])).toBe('');
  });

  it('renvoie le libellé seul pour un unique soin en attente', () => {
    expect(buildDigestBody(['Bain'])).toBe('Bain');
  });
});

describe('morningDigest', () => {
  beforeEach(() => {
    vi.useFakeTimers({ toFake: ['Date'] });
    vi.setSystemTime(NOW);
    sendToDevices.mockReset();
    sendToDevices.mockResolvedValue(1);
    loggerError.mockReset();
    loggerWarn.mockReset();
    households.length = 0;
    deviceUpdates.length = 0;
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('envoie les soins en attente et marque les appareils servis', async () => {
    households.push({
      id: 'ABC123',
      baby: { name: 'Colette' },
      devices: [{ id: 'd1' }, { id: 'd2', morningDigestHour: 8 }, { id: 'd3', morningDigestHour: 20 }],
      events: [{ startAt: at('2026-09-21T05:00:00Z'), adrigyl: true }],
    });

    await handler();

    expect(sendToDevices).toHaveBeenCalledTimes(1);
    const [code, devices, payload] = sendToDevices.mock.calls[0];
    expect(code).toBe('ABC123');
    expect(devices.map((d: Device) => d.id)).toEqual(['d1', 'd2']);
    expect(payload).toEqual({
      title: "Aujourd'hui pour Colette",
      body: buildDigestBody(['Soin des yeux', 'Soin du nez', 'Soin du nombril', 'Bain']),
      data: { route: '/today' },
    });
    expect(deviceUpdates).toEqual([
      { household: 'ABC123', deviceId: 'd1', data: { lastDigestSentOn: TODAY_KEY } },
      { household: 'ABC123', deviceId: 'd2', data: { lastDigestSentOn: TODAY_KEY } },
    ]);
  });

  it("n'envoie rien pour un foyer sans bébé", async () => {
    households.push({ id: 'ABC123', devices: [{ id: 'd1' }] });

    await handler();

    expect(sendToDevices).not.toHaveBeenCalled();
    expect(deviceUpdates).toEqual([]);
  });

  it("n'envoie rien quand tous les soins sont faits", async () => {
    households.push({
      id: 'ABC123',
      baby: { name: 'Colette' },
      devices: [{ id: 'd1' }],
      events: [
        { startAt: at('2026-09-21T05:00:00Z'), adrigyl: true, eyeCare: true, noseCare: true },
        { startAt: at('2026-09-21T05:30:00Z'), umbilicalCare: true, bath: true },
      ],
    });

    await handler();

    expect(sendToDevices).not.toHaveBeenCalled();
  });

  it('exclut un appareil déjà servi aujourd’hui', async () => {
    households.push({
      id: 'ABC123',
      baby: { name: 'Colette' },
      devices: [{ id: 'd1', lastDigestSentOn: TODAY_KEY }],
      events: [],
    });

    await handler();

    expect(sendToDevices).not.toHaveBeenCalled();
  });

  it("ne compte pas les événements datés de demain", async () => {
    households.push({
      id: 'ABC123',
      baby: { name: 'Colette' },
      devices: [{ id: 'd1' }],
      events: [{ startAt: at('2026-09-21T23:00:00Z'), adrigyl: true }],
    });

    await handler();

    expect(sendToDevices.mock.calls[0][2].body).toContain('Adrigyl');
  });

  it('se rabat sur « bébé » quand le prénom manque', async () => {
    households.push({ id: 'ABC123', baby: { name: '' }, devices: [{ id: 'd1' }], events: [] });

    await handler();

    expect(sendToDevices.mock.calls[0][2].title).toBe("Aujourd'hui pour bébé");
  });

  it("journalise l'échec d'un foyer et poursuit la boucle", async () => {
    households.push(
      { id: 'KO', baby: { name: 'Colette' }, fails: true },
      { id: 'ABC123', baby: { name: 'Colette' }, devices: [{ id: 'd1' }], events: [] },
    );

    await handler();

    expect(loggerError).toHaveBeenCalledTimes(1);
    expect(loggerError.mock.calls[0][1]).toMatchObject({ household: 'KO' });
    expect(sendToDevices).toHaveBeenCalledTimes(1);
    expect(sendToDevices.mock.calls[0][0]).toBe('ABC123');
  });

  it("n'échoue pas si un appareil a disparu avant le marquage", async () => {
    households.push({
      id: 'ABC123',
      baby: { name: 'Colette' },
      devices: [{ id: 'disparu' }, { id: 'd2' }],
      events: [],
    });

    await handler();

    expect(deviceUpdates.map((u) => u.deviceId)).toEqual(['d2']);
    expect(loggerWarn).toHaveBeenCalledTimes(1);
  });

  it('ne marque aucun appareil quand rien n’a pu être envoyé', async () => {
    sendToDevices.mockResolvedValue(0);
    households.push({ id: 'ABC123', baby: { name: 'Colette' }, devices: [{ id: 'd1' }], events: [] });

    await handler();

    expect(deviceUpdates).toEqual([]);
  });
});
```

- [ ] **Step 3: Compiler et tester**

Run: `cd functions && npm run build && npm test`
Expected: compilation sans erreur, tous les tests passent.

- [ ] **Step 4: Commit**

```bash
cd /Users/maxencemontet/Documents/colette
git add functions/src
git commit -m "feat(functions): digest matinal des soins restants"
```

---

### Task 8: Déploiement et vérification de bout en bout

Prérequis fournis par Maxence : projet Firebase en plan Blaze, Firebase CLI connectée (`firebase login`), clé APNs déposée dans Firebase → Cloud Messaging, app installée sur les deux iPhones avec les capacités push activées.

- [ ] **Step 1: Sélectionner le projet**

Run: `cd /Users/maxencemontet/Documents/colette && firebase use <project-id>`
Expected: `Now using project <project-id>`.

- [ ] **Step 2: Déployer règles et index**

Run: `firebase deploy --only firestore:rules,firestore:indexes`
Expected: `Deploy complete!`. Les index passent en construction quelques minutes.

- [ ] **Step 3: Déployer les fonctions**

Run: `firebase deploy --only functions`
Expected: `Deploy complete!` avec `onEventCreated`, `bottleReminder`, `morningDigest` en `europe-west1`. Le premier déploiement d'une fonction planifiée active Cloud Scheduler et Pub/Sub sur le projet.

- [ ] **Step 4: Vérification manuelle**

1. Sur l'iPhone A, ajouter un événement (par exemple une couche). L'iPhone B reçoit « {label A} a ajouté un événement » dans les secondes qui suivent ; le tap ouvre le Journal.
2. Sur l'iPhone A, enregistrer un biberon. Vérifier dans la console Firestore que `feedingPlan.nextBottleAt` est bien renseigné sur le foyer. Environ 3 h moins 10 min plus tard, les deux iPhones reçoivent « Biberon dans 10 min » ; le tap ouvre le formulaire biberon prérempli.
3. Régler l'heure du digest sur l'heure suivante dans Réglages ; à l'heure pile, recevoir « Aujourd'hui pour {prénom} » listant les soins non faits.
4. Dans la console Google Cloud → Facturation → Budgets, créer une alerte à 1 €.

- [ ] **Step 5: Commit final**

```bash
git add .firebaserc
git commit -m "chore: déploiement Firebase vérifié"
```

(Pas de `git add -A` : un `Makefile` non suivi et sans rapport traîne à la racine.)

---

## Auto-revue du plan

**Couverture de la spec §5.1 et §7 :** règles → T1 ; index composites nécessaires aux requêtes `watchLatestBath` / `watchLatestBottle` de l'app et au digest → T1 ; `onEventCreated` → T5 ; `bottleReminder` avec `lastBottleNotifiedFor` → T6 ; `morningDigest` avec la même règle de soins que l'app, réimplémentée et testée → T3, T7 ; suppression des tokens invalides → T4 ; routes de tap `/journal`, `/today?bottle=1`, `/today` → gérées côté app par `NotificationsGate` (plan app T16) ; alerte budget → T8.

**Cohérence des noms :** `db()`, `loadDevices()` (T2) utilisés en T4–T7 ; `Device`, `EventDoc`, `FeedingPlanDoc`, `BabyDoc`, `toCareEvent`, `withDefaults` (T2) ; `summarizeEvent` (T3) en T5 ; `pendingCares` (T3) en T7 ; `isReminderDue` (T3) en T6 ; `sendToDevices(code, devices, payload)` (T4) en T5–T7 ; `formatHourMinute`, `hourInParis`, `startOfTodayInParis`, `ZONE` (T2).
