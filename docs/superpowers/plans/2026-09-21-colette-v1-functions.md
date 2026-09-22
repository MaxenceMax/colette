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
    match /households/{code}/{document=**} {
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
- Test: `functions/src/lib/paris-time.test.ts`

- [ ] **Step 1: Écrire le test (rouge)**

`functions/src/lib/paris-time.test.ts` :

```ts
import { describe, expect, it } from 'vitest';
import { formatHourMinute, hourInParis, startOfTodayInParis } from './paris-time';

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
};

export type DeviceDoc = {
  label?: string;
  fcmToken?: string | null;
  notifyOnOthersEvents?: boolean;
  notifyBottleReminder?: boolean;
  notifyMorningDigest?: boolean;
  morningDigestHour?: number;
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

export function withDefaults(settings: Partial<CareSettings> | undefined): CareSettings {
  return { ...DEFAULT_CARE_SETTINGS, ...(settings ?? {}) };
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

/** Nombre de jours civils (Paris) entre deux instants. */
export function calendarDaysBetween(from: Date, to: Date): number {
  return Math.floor(paris(to).startOf('day').diff(paris(from).startOf('day'), 'days').days);
}
```

- [ ] **Step 6: Tester**

Run: `cd functions && npm test`
Expected: 3 tests passent.

- [ ] **Step 7: Commit**

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

  it('liste biberon puis soins, avec l\'heure de Paris', () => {
    expect(summarizeEvent({ startAt: at, bottleMl: 120, diaperChange: true, adrigyl: true })).toBe(
      'Biberon 120 ml · Couche · Adrigyl à 14h32',
    );
  });

  it('gère un événement à un seul soin', () => {
    expect(summarizeEvent({ startAt: at, bath: true })).toBe('Bain à 14h32');
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

  it('un soin fait aujourd\'hui disparaît de la liste', () => {
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
import { isReminderDue, REMINDER_LEAD_MS } from './reminder';

describe('isReminderDue', () => {
  const next = new Date('2026-09-21T12:30:00Z');

  it('pas encore dans la fenêtre de 10 min', () => {
    expect(isReminderDue({ nextBottleAt: next, lastNotifiedFor: null, now: new Date('2026-09-21T12:15:00Z') })).toBe(false);
  });

  it('dû dès 10 min avant', () => {
    expect(isReminderDue({ nextBottleAt: next, lastNotifiedFor: null, now: new Date(next.getTime() - REMINDER_LEAD_MS) })).toBe(true);
  });

  it('jamais deux fois pour la même échéance', () => {
    expect(isReminderDue({ nextBottleAt: next, lastNotifiedFor: next, now: new Date('2026-09-21T12:25:00Z') })).toBe(false);
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
  return `${parts.join(' · ')} à ${formatHourMinute(event.startAt)}`;
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

type Input = { nextBottleAt: Date; lastNotifiedFor: Date | null; now: Date };

/** Dû à partir de 10 min avant l'échéance, une seule fois par échéance. */
export function isReminderDue({ nextBottleAt, lastNotifiedFor, now }: Input): boolean {
  if (lastNotifiedFor && lastNotifiedFor.getTime() === nextBottleAt.getTime()) return false;
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
      db().collection('households').doc(code).collection('devices').doc(d.id).update({
        fcmToken: FieldValue.delete(),
      }),
    ),
  );

  logger.info('push sent', { code, success: response.successCount, failure: response.failureCount, stale: stale.length });
  return response.successCount;
}
```

- [ ] **Step 2: Compiler**

Run: `cd functions && npm run build`
Expected: aucune erreur TypeScript.

- [ ] **Step 3: Commit**

```bash
cd /Users/maxencemontet/Documents/colette
git add functions/src/lib/push.ts
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
import { toCareEvent, type EventDoc } from './lib/types';

export const onEventCreated = onDocumentCreated('households/{code}/events/{eventId}', async (event) => {
  const snap = event.data;
  if (!snap) return;
  const data = snap.data() as EventDoc;
  const code = event.params.code;

  const devices = await loadDevices(snap.ref.parent.parent!);
  const author = devices.find((d) => d.id === data.createdByDeviceId);
  const targets = devices.filter(
    (d) => d.id !== data.createdByDeviceId && d.notifyOnOthersEvents !== false,
  );
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
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { db, loadDevices } from './lib/firestore';
import { formatHourMinute, ZONE } from './lib/paris-time';
import { sendToDevices } from './lib/push';
import { isReminderDue } from './lib/reminder';
import type { FeedingPlanDoc } from './lib/types';

export const bottleReminder = onSchedule({ schedule: 'every 5 minutes', timeZone: ZONE }, async () => {
  const now = new Date();
  const households = await db().collection('households').get();

  for (const doc of households.docs) {
    const plan = doc.get('feedingPlan') as FeedingPlanDoc | undefined;
    if (!plan) continue;
    const nextBottleAt = plan.nextBottleAt.toDate();
    const lastNotifiedFor = (doc.get('lastBottleNotifiedFor') as Timestamp | undefined)?.toDate() ?? null;
    if (!isReminderDue({ nextBottleAt, lastNotifiedFor, now })) continue;

    const devices = (await loadDevices(doc.ref)).filter((d) => d.notifyBottleReminder !== false);
    await sendToDevices(doc.id, devices, {
      title: 'Biberon dans 10 min',
      body: `Environ ${plan.suggestedMl} ml, prévu vers ${formatHourMinute(nextBottleAt)}`,
      data: { route: '/today?bottle=1' },
    });
    await doc.ref.update({ lastBottleNotifiedFor: plan.nextBottleAt });
  }
});
```

- [ ] **Step 2: Exporter dans `functions/src/index.ts`**

```ts
export { bottleReminder } from './bottle-reminder';
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
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { pendingCares } from './lib/care-status';
import { db, loadDevices } from './lib/firestore';
import { hourInParis, startOfTodayInParis, ZONE } from './lib/paris-time';
import { sendToDevices } from './lib/push';
import { toCareEvent, withDefaults, type BabyDoc, type EventDoc } from './lib/types';

export const morningDigest = onSchedule({ schedule: '0 * * * *', timeZone: ZONE }, async () => {
  const now = new Date();
  const hour = hourInParis(now);
  const households = await db().collection('households').get();

  for (const doc of households.docs) {
    const devices = (await loadDevices(doc.ref)).filter(
      (d) => d.notifyMorningDigest !== false && (d.morningDigestHour ?? 8) === hour,
    );
    if (devices.length === 0) continue;
    const baby = doc.get('baby') as BabyDoc | undefined;
    if (!baby) continue;

    const events = doc.ref.collection('events');
    const todaySnap = await events.where('startAt', '>=', Timestamp.fromDate(startOfTodayInParis(now))).get();
    const lastBathSnap = await events.where('bath', '==', true).orderBy('startAt', 'desc').limit(1).get();

    const pending = pendingCares({
      settings: withDefaults(baby.careSettings),
      todayEvents: todaySnap.docs.map((d) => toCareEvent(d.data() as EventDoc)),
      lastBathAt: lastBathSnap.empty ? null : (lastBathSnap.docs[0].data() as EventDoc).startAt.toDate(),
      now,
    });
    if (pending.length === 0) continue;

    await sendToDevices(doc.id, devices, {
      title: `Aujourd'hui pour ${baby.name}`,
      body: pending.join(', '),
      data: { route: '/today' },
    });
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
git add -A
git commit -m "chore: déploiement Firebase vérifié"
```

---

## Auto-revue du plan

**Couverture de la spec §5.1 et §7 :** règles → T1 ; index composites nécessaires aux requêtes `watchLatestBath` / `watchLatestBottle` de l'app et au digest → T1 ; `onEventCreated` → T5 ; `bottleReminder` avec `lastBottleNotifiedFor` → T6 ; `morningDigest` avec la même règle de soins que l'app, réimplémentée et testée → T3, T7 ; suppression des tokens invalides → T4 ; routes de tap `/journal`, `/today?bottle=1`, `/today` → gérées côté app par `NotificationsGate` (plan app T16) ; alerte budget → T8.

**Cohérence des noms :** `db()`, `loadDevices()` (T2) utilisés en T4–T7 ; `Device`, `EventDoc`, `FeedingPlanDoc`, `BabyDoc`, `toCareEvent`, `withDefaults` (T2) ; `summarizeEvent` (T3) en T5 ; `pendingCares` (T3) en T7 ; `isReminderDue` (T3) en T6 ; `sendToDevices(code, devices, payload)` (T4) en T5–T7 ; `formatHourMinute`, `hourInParis`, `startOfTodayInParis`, `ZONE` (T2).
