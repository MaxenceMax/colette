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
