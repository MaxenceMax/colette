import { isExpected } from './care-frequency';
import { calendarDaysBetween } from './paris-time';
import { CARE_LABELS } from './summary';
import type { CareEvent, CareSettings } from './types';

type Input = {
  settings: CareSettings;
  /** Les 7 derniers jours civils (Paris), aujourd'hui inclus. */
  events: CareEvent[];
  now: Date;
};

/** Soins programmés, dans l'ordre du dashboard et du digest. */
export const SCHEDULED_CARES = ['adrigyl', 'eyeCare', 'noseCare', 'umbilicalCare', 'bath'] as const;

/** Libellés des soins attendus aujourd'hui et pas encore faits, dans l'ordre du dashboard. */
export function pendingCares({ settings, events, now }: Input): string[] {
  const pending: string[] = [];
  for (const care of SCHEDULED_CARES) {
    const frequency = settings[care];
    if (!frequency.enabled) continue;
    const matching = events.filter((e) => e[care]).sort((a, b) => a.startAt.getTime() - b.startAt.getTime());
    const lastDoneAt = matching.length === 0 ? null : matching[matching.length - 1].startAt;
    if (!isExpected(frequency, lastDoneAt, now)) continue;
    const doneToday = matching.filter((e) => calendarDaysBetween(e.startAt, now) === 0).length;
    if (doneToday < frequency.timesPerDay) pending.push(CARE_LABELS[care]);
  }
  return pending;
}
