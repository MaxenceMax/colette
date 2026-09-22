export const REMINDER_LEAD_MS = 10 * 60 * 1000;

type Input = { nextBottleAt: Date; lastNotifiedFor: Date | null; now: Date };

/** Dû à partir de 10 min avant l'échéance, une seule fois par échéance. */
export function isReminderDue({ nextBottleAt, lastNotifiedFor, now }: Input): boolean {
  if (lastNotifiedFor && lastNotifiedFor.getTime() === nextBottleAt.getTime()) return false;
  return nextBottleAt.getTime() - REMINDER_LEAD_MS <= now.getTime();
}
