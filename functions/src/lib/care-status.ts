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
