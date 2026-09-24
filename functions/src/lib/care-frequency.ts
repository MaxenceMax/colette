import { calendarDaysBetween } from './paris-time';
import type { CareFrequency } from './types';

/** Espacement maximal réglable (jours) : fenêtre d'événements suffisante pour savoir si un soin est dû. */
export const CARE_WINDOW_DAYS = 7;

/**
 * Soin dû aujourd'hui : suivi actif, et quotidien, jamais fait, ou dernier fait il y a au moins
 * `everyDays` jours civils (Paris). Même règle que `CareFrequency.isExpected` côté app.
 */
export function isExpected(frequency: CareFrequency, lastDoneAt: Date | null, now: Date): boolean {
  if (!frequency.enabled) return false;
  if (frequency.everyDays === 1 || !lastDoneAt) return true;
  return calendarDaysBetween(lastDoneAt, now) >= frequency.everyDays;
}
