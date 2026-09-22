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
