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
