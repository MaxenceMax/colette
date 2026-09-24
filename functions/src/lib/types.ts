import type { Timestamp } from 'firebase-admin/firestore';

/** Fréquence d'un soin : `timesPerDay` fois par jour, ou une fois tous les `everyDays` jours (l'un des deux vaut 1). */
export type CareFrequency = {
  timesPerDay: number;
  everyDays: number;
  enabled: boolean;
};

export type CareSettings = {
  adrigyl: CareFrequency;
  eyeCare: CareFrequency;
  noseCare: CareFrequency;
  umbilicalCare: CareFrequency;
  bath: CareFrequency;
  feedsPerDay: number;
};

const DAILY: CareFrequency = { timesPerDay: 1, everyDays: 1, enabled: true };

export const DEFAULT_CARE_SETTINGS: CareSettings = {
  adrigyl: DAILY,
  eyeCare: DAILY,
  noseCare: DAILY,
  umbilicalCare: { timesPerDay: 3, everyDays: 1, enabled: true },
  bath: { timesPerDay: 1, everyDays: 2, enabled: true },
  feedsPerDay: 8,
};

export type StoredCareFrequency = Partial<CareFrequency>;

/** Réglages tels que stockés : une map par soin, ou les anciens champs plats des documents antérieurs. */
export type StoredCareSettings = {
  adrigyl?: StoredCareFrequency;
  eyeCare?: StoredCareFrequency;
  noseCare?: StoredCareFrequency;
  umbilicalCare?: StoredCareFrequency;
  bath?: StoredCareFrequency;
  feedsPerDay?: number;
  adrigylPerDay?: number;
  eyeCarePerDay?: number;
  noseCarePerDay?: number;
  umbilicalCarePerDay?: number;
  umbilicalCareEnabled?: boolean;
  bathEveryDays?: number;
};

export type BabyDoc = {
  name: string;
  careSettings?: StoredCareSettings;
};

export type FeedingPlanDoc = {
  nextBottleAt: Timestamp;
  /** Absents dans les snapshots écrits par une version de l'app antérieure à la fourchette. */
  windowStartAt?: Timestamp;
  windowEndAt?: Timestamp;
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

export type MedicalReminderStageDoc = {
  stageId: string;
  dueFrom: Timestamp;
  dueUntil: Timestamp;
  hasAppointment: boolean;
};

/** Snapshot écrit par l'app : prochaines étapes non faites du suivi médical. */
export type MedicalReminderDoc = {
  stages?: MedicalReminderStageDoc[];
  computedAt?: Timestamp;
};

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

const MAX_TIMES_PER_DAY = 10;
const MAX_EVERY_DAYS = 30;

/** Borne une valeur comme le client : un document modifié à la main ne doit jamais casser les calculs. */
function clamped(value: unknown, min: number, max: number, fallback: number): number {
  if (typeof value !== 'number' || !Number.isFinite(value)) return fallback;
  return Math.min(max, Math.max(min, Math.trunc(value)));
}

function isFiniteNumber(value: unknown): value is number {
  return typeof value === 'number' && Number.isFinite(value);
}

function isMap(value: unknown): value is StoredCareFrequency {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

/** Map de soin : bornes 1..10 et 1..30, `enabled` vrai par défaut ; deux entiers > 1 → `timesPerDay` ramené à 1. */
function readFrequencyMap(raw: StoredCareFrequency): CareFrequency {
  const everyDays = clamped(raw.everyDays, 1, MAX_EVERY_DAYS, 1);
  const timesPerDay = everyDays > 1 ? 1 : clamped(raw.timesPerDay, 1, MAX_TIMES_PER_DAY, 1);
  return { timesPerDay, everyDays, enabled: typeof raw.enabled === 'boolean' ? raw.enabled : true };
}

/** Ancien entier « fois par jour » : `n > 0` → `n`/jour ; `0` → `fallback` désactivé. */
function readLegacyPerDay(value: unknown, fallback: CareFrequency): CareFrequency {
  if (!isFiniteNumber(value)) return fallback;
  const times = Math.trunc(value);
  if (times <= 0) return { ...fallback, enabled: false };
  return { timesPerDay: Math.min(MAX_TIMES_PER_DAY, times), everyDays: 1, enabled: true };
}

function readFrequency(nested: unknown, legacy: unknown, fallback: CareFrequency): CareFrequency {
  return isMap(nested) ? readFrequencyMap(nested) : readLegacyPerDay(legacy, fallback);
}

/** Documents antérieurs : entier `umbilicalCarePerDay`, ou booléen `umbilicalCareEnabled`. */
function readUmbilicalCare(raw: StoredCareSettings): CareFrequency {
  const fallback = DEFAULT_CARE_SETTINGS.umbilicalCare;
  if (isMap(raw.umbilicalCare)) return readFrequencyMap(raw.umbilicalCare);
  if (isFiniteNumber(raw.umbilicalCarePerDay)) return readLegacyPerDay(raw.umbilicalCarePerDay, fallback);
  return raw.umbilicalCareEnabled === false ? { ...fallback, enabled: false } : fallback;
}

/** Documents antérieurs : entier `bathEveryDays`. */
function readBath(raw: StoredCareSettings): CareFrequency {
  const fallback = DEFAULT_CARE_SETTINGS.bath;
  if (isMap(raw.bath)) return readFrequencyMap(raw.bath);
  if (!isFiniteNumber(raw.bathEveryDays)) return fallback;
  return { timesPerDay: 1, everyDays: clamped(raw.bathEveryDays, 1, MAX_EVERY_DAYS, fallback.everyDays), enabled: true };
}

/** Mêmes valeurs par défaut, mêmes bornes et même repli que `CareSettingsDto.fromMap` côté client. */
export function withDefaults(settings: StoredCareSettings | undefined): CareSettings {
  const raw = settings ?? {};
  const d = DEFAULT_CARE_SETTINGS;
  return {
    adrigyl: readFrequency(raw.adrigyl, raw.adrigylPerDay, d.adrigyl),
    eyeCare: readFrequency(raw.eyeCare, raw.eyeCarePerDay, d.eyeCare),
    noseCare: readFrequency(raw.noseCare, raw.noseCarePerDay, d.noseCare),
    umbilicalCare: readUmbilicalCare(raw),
    bath: readBath(raw),
    feedsPerDay: clamped(raw.feedsPerDay, 1, 24, d.feedsPerDay),
  };
}
