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
