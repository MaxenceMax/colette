import type { Timestamp } from 'firebase-admin/firestore';

export type CareSettings = {
  adrigylPerDay: number;
  eyeCarePerDay: number;
  noseCarePerDay: number;
  umbilicalCarePerDay: number;
  bathEveryDays: number;
  feedsPerDay: number;
};

export const DEFAULT_CARE_SETTINGS: CareSettings = {
  adrigylPerDay: 1,
  eyeCarePerDay: 1,
  noseCarePerDay: 1,
  umbilicalCarePerDay: 3,
  bathEveryDays: 2,
  feedsPerDay: 8,
};

/** Réglages tels que stockés, y compris l'ancien booléen des documents antérieurs. */
export type StoredCareSettings = Partial<CareSettings> & { umbilicalCareEnabled?: boolean };

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

/** Documents antérieurs : seul le booléen `umbilicalCareEnabled` existe. */
function readUmbilicalCarePerDay(raw: StoredCareSettings): number {
  const fallback = DEFAULT_CARE_SETTINGS.umbilicalCarePerDay;
  if (typeof raw.umbilicalCarePerDay === 'number') return clamped(raw.umbilicalCarePerDay, 0, 10, fallback);
  return raw.umbilicalCareEnabled === false ? 0 : fallback;
}

/** Mêmes valeurs par défaut et mêmes bornes que `CareSettingsDto.fromMap` côté client. */
export function withDefaults(settings: StoredCareSettings | undefined): CareSettings {
  const raw = settings ?? {};
  return {
    adrigylPerDay: clamped(raw.adrigylPerDay, 0, 10, DEFAULT_CARE_SETTINGS.adrigylPerDay),
    eyeCarePerDay: clamped(raw.eyeCarePerDay, 0, 10, DEFAULT_CARE_SETTINGS.eyeCarePerDay),
    noseCarePerDay: clamped(raw.noseCarePerDay, 0, 10, DEFAULT_CARE_SETTINGS.noseCarePerDay),
    umbilicalCarePerDay: readUmbilicalCarePerDay(raw),
    bathEveryDays: clamped(raw.bathEveryDays, 1, 30, DEFAULT_CARE_SETTINGS.bathEveryDays),
    feedsPerDay: clamped(raw.feedsPerDay, 1, 24, DEFAULT_CARE_SETTINGS.feedsPerDay),
  };
}
